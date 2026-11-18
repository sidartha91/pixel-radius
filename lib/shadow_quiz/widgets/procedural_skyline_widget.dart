import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../logic/quiz_models.dart';
import 'fallback_silhouettes.dart';

/// Registre des SVG réellement présents dans le bundle (via AssetManifest).
/// Permet de basculer proprement sur le fallback vectoriel si un fichier manque.
class SilhouetteAssetRegistry {
  SilhouetteAssetRegistry._(this._assets);

  static const String commonDir = 'assets/silhouettes/common/';
  static const String uniqueDir = 'assets/silhouettes/unique/';

  static Future<SilhouetteAssetRegistry>? _instance;

  final Set<String> _assets;

  static Future<SilhouetteAssetRegistry> load() {
    return _instance ??= () async {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        return SilhouetteAssetRegistry._(manifest.listAssets().where((a) => a.endsWith('.svg')).toSet());
      } catch (e) {
        debugPrint('[Skyline] AssetManifest indisponible, fallback vectoriel intégral : $e');
        return SilhouetteAssetRegistry._(<String>{});
      }
    }();
  }

  bool has(String path) => _assets.contains(path);

  List<String> commonSky() => _assets
      .where((a) => a.startsWith(commonDir) && _skyPrefixes.any((p) => a.startsWith('$commonDir$p')))
      .toList()
    ..sort();

  static const List<String> _skyPrefixes = <String>['cloud', 'birds', 'moon', 'sun'];

  /// Résout le SVG d'un élément : `asset` explicite → convention `unique/{city}_{id}.svg`.
  String? resolve(String cityId, QuizSilhouette item) {
    if (item.asset != null) {
      final explicit = 'assets/silhouettes/${item.asset}.svg';
      if (has(explicit)) return explicit;
    }
    final conventional = '$uniqueDir${cityId}_${item.id}.svg';
    if (has(conventional)) return conventional;
    return null;
  }
}

/// Un élément positionné dans la fresque.
class SkylinePlacement {
  const SkylinePlacement({
    required this.id,
    required this.shape,
    required this.assetPath,
    required this.x,
    required this.y,
    required this.scale,
    required this.flipped,
    required this.aspect,
  });

  final String id;

  /// Forme de fallback (si `assetPath` est null).
  final String shape;
  final String? assetPath;

  /// Centre horizontal (0..1).
  final double x;

  /// Ciel : haut de l'élément (0..1 de la hauteur). Plans au sol : ignoré.
  final double y;
  final double scale;
  final bool flipped;

  /// Largeur / hauteur de la boîte d'affichage.
  final double aspect;
}

enum GroundStyle { river, street, dunes }

class SkylineComposition {
  const SkylineComposition({
    required this.sky,
    required this.monuments,
    required this.foreground,
    required this.groundStyle,
    required this.groundSeed,
    required this.signature,
  });

  final List<SkylinePlacement> sky;
  final List<SkylinePlacement> monuments;
  final List<SkylinePlacement> foreground;
  final GroundStyle groundStyle;
  final int groundSeed;
  final String signature;

  /// Nombre d'éléments dévoilables (Rapid Fire).
  int get elementCount => sky.length + foreground.length + monuments.length;

  /// Ordre de dévoilement en Rapid Fire : du moins au plus révélateur
  /// (ciel → scènes culturelles → monuments).
  int revealIndex(SkylineLayer layer, int i) => switch (layer) {
        SkylineLayer.sky => i,
        SkylineLayer.foreground => sky.length + i,
        SkylineLayer.monuments => sky.length + foreground.length + i,
      };
}

enum SkylineLayer { sky, foreground, monuments }

/// Assemble une fresque procédurale unique pour une ville cible.
class SkylineComposer {
  SkylineComposer(this.registry);

  final SilhouetteAssetRegistry registry;

  /// Signatures déjà produites (aucune fresque ne se répète dans la session).
  static final Set<String> _history = <String>{};

  SkylineComposition compose(QuizCity city, math.Random random) {
    SkylineComposition? result;
    for (var attempt = 0; attempt < 30; attempt++) {
      result = _composeOnce(city, random);
      if (_history.add(result.signature)) return result;
    }
    return result!;
  }

  double _jitter(math.Random r, double amplitude) => (r.nextDouble() * 2 - 1) * amplitude;

  SkylineComposition _composeOnce(QuizCity city, math.Random r) {
    // ── Calque 1 : Ciel (4 à 6 éléments) ──
    final skyCount = 4 + r.nextInt(3);
    final skyAssets = registry.commonSky();
    final skyPool = <({String id, String shape, String? asset})>[
      for (final a in skyAssets)
        (id: a.split('/').last.replaceAll('.svg', ''), shape: _skyShapeOf(a), asset: a),
    ];
    if (skyPool.isEmpty) {
      skyPool.addAll(const <({String id, String shape, String? asset})>[
        (id: 'cloud', shape: 'cloud', asset: null),
        (id: 'birds', shape: 'birds', asset: null),
        (id: 'moon', shape: 'moon', asset: null),
        (id: 'sun', shape: 'sun', asset: null),
      ]);
    }
    final sky = <SkylinePlacement>[];
    var hasCelestial = false;
    final skySlots = List<int>.generate(skyCount, (i) => i)..shuffle(r);
    for (var i = 0; i < skyCount; i++) {
      var pick = skyPool[r.nextInt(skyPool.length)];
      final celestial = pick.shape == 'moon' || pick.shape == 'sun';
      if (celestial && hasCelestial) {
        final nonCelestial = skyPool.where((e) => e.shape != 'moon' && e.shape != 'sun').toList();
        if (nonCelestial.isEmpty) continue;
        pick = nonCelestial[r.nextInt(nonCelestial.length)];
      }
      if (pick.shape == 'moon' || pick.shape == 'sun') hasCelestial = true;
      final slot = skySlots[i];
      sky.add(SkylinePlacement(
        id: pick.id,
        shape: pick.shape,
        assetPath: pick.asset,
        x: ((slot + 0.5) / skyCount + _jitter(r, 0.06)).clamp(0.04, 0.96),
        y: 0.04 + r.nextDouble() * 0.28,
        scale: 0.6 + r.nextDouble() * 0.5, // 0.6x → 1.1x
        flipped: r.nextBool(),
        aspect: pick.shape == 'cloud' ? 1.8 : (pick.shape == 'birds' ? 1.4 : 1.0),
      ));
    }

    // ── Calque 2 : Monuments (2 ou 3) ──
    final monumentPool = List<QuizSilhouette>.of(city.monuments)..shuffle(r);
    final monumentCount = math.min(monumentPool.length, 2 + r.nextInt(2));
    final slots = monumentCount == 3 ? <double>[0.2, 0.5, 0.8] : <double>[0.3, 0.7];
    final monuments = <SkylinePlacement>[];
    for (var i = 0; i < monumentCount; i++) {
      final m = monumentPool[i];
      monuments.add(SkylinePlacement(
        id: m.id,
        shape: m.shape,
        assetPath: registry.resolve(city.id, m),
        x: (slots[i] + _jitter(r, 0.045)).clamp(0.1, 0.9),
        y: 0,
        scale: 1 + _jitter(r, 0.15), // ±15 %
        flipped: r.nextDouble() < 0.25, // miroir occasionnel
        aspect: _aspectFor(m.shape, monument: true),
      ));
    }

    // ── Calque 3 : Premier plan (3 ou 4 scènes culturelles) ──
    final culturePool = List<QuizSilhouette>.of(city.cultureLife)..shuffle(r);
    final cultureCount = math.min(culturePool.length, 3 + r.nextInt(2));
    final foreground = <SkylinePlacement>[];
    for (var i = 0; i < cultureCount; i++) {
      final item = culturePool[i];
      final base = (i + 0.5) / cultureCount;
      foreground.add(SkylinePlacement(
        id: item.id,
        shape: item.shape,
        assetPath: registry.resolve(city.id, item),
        x: (base + _jitter(r, 0.5 / cultureCount * 0.5)).clamp(0.07, 0.93),
        y: 0,
        scale: 0.85 + r.nextDouble() * 0.25,
        flipped: r.nextBool(),
        aspect: _aspectFor(item.shape, monument: false),
      ));
    }

    final groundStyle = GroundStyle.values[r.nextInt(GroundStyle.values.length)];
    final groundSeed = r.nextInt(1 << 30);

    final signature = <String>[
      city.id,
      for (final p in <SkylinePlacement>[...sky, ...monuments, ...foreground])
        '${p.id}@${(p.x * 20).round()}:${(p.y * 10).round()}:${(p.scale * 10).round()}${p.flipped ? 'f' : ''}',
      groundStyle.name,
    ].join('|');

    return SkylineComposition(
      sky: sky,
      monuments: monuments,
      foreground: foreground,
      groundStyle: groundStyle,
      groundSeed: groundSeed,
      signature: signature,
    );
  }

  static String _skyShapeOf(String path) {
    final name = path.split('/').last;
    if (name.startsWith('cloud')) return 'cloud';
    if (name.startsWith('birds')) return 'birds';
    if (name.startsWith('moon')) return 'moon';
    if (name.startsWith('sun')) return 'sun';
    return 'cloud';
  }

  static double _aspectFor(String shape, {required bool monument}) {
    const wide = <String>{
      'bridge', 'gate', 'temple', 'colonial', 'pyramid', 'castle', 'mosque', 'cathedral',
      'opera_sails', 'mountain', 'onion_domes', 'stupa', 'dome', 'arch', 'ferris_wheel',
      'bus', 'tram', 'train', 'car', 'tuk_tuk', 'food_stall', 'umbrella_stall', 'boat',
      'canoe', 'animal_cart', 'elephant', 'camel', 'cafe_table', 'cyclist',
    };
    const slim = <String>{
      'tv_tower', 'minaret', 'obelisk', 'lattice_tower', 'skyscraper', 'skyscraper_spire',
      'lighthouse', 'clock_tower', 'person', 'person_hat', 'robed_person', 'statue',
    };
    if (wide.contains(shape)) return monument ? 1.25 : 1.5;
    if (slim.contains(shape)) return monument ? 0.55 : 0.55;
    return monument ? 0.85 : 0.9;
  }
}

/// Bandeau panoramique : 3 calques superposés + ColorFilter global srcIn.
class ProceduralSkylineWidget extends StatelessWidget {
  const ProceduralSkylineWidget({
    super.key,
    required this.composition,
    required this.silhouetteColor,
    required this.backgroundColor,
    this.glowColor,
    this.visibleCount,
  });

  final SkylineComposition composition;

  /// #E5A93C en mode sombre, #000000 en mode clair.
  final Color silhouetteColor;
  final Color backgroundColor;
  final Color? glowColor;

  /// Rapid Fire : nombre d'éléments visibles (null = tout est visible).
  final int? visibleCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final groundTop = h * 0.84;

      Widget silhouette(SkylinePlacement p, double boxH) {
        final boxW = boxH * p.aspect;
        final Widget art = p.assetPath != null
            ? SvgPicture.asset(
                p.assetPath!,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                placeholderBuilder: (_) => FallbackSilhouette(shape: p.shape, seed: p.id.hashCode),
              )
            : FallbackSilhouette(shape: p.shape, seed: p.id.hashCode);
        return SizedBox(
          width: boxW,
          height: boxH,
          child: Transform.flip(flipX: p.flipped, child: art),
        );
      }

      final children = <Widget>[];

      // Apparition en fondu + léger grossissement (Rapid Fire).
      Widget reveal(SkylineLayer layer, int i, double opacity, Widget child) {
        final visible = visibleCount == null || composition.revealIndex(layer, i) < visibleCount!;
        return AnimatedOpacity(
          opacity: visible ? opacity : 0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: visible ? 1 : 0.82,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            child: child,
          ),
        );
      }

      // Calque 1 — Ciel
      for (var i = 0; i < composition.sky.length; i++) {
        final p = composition.sky[i];
        final boxH = h * 0.13 * p.scale;
        final boxW = boxH * p.aspect;
        children.add(Positioned(
          left: p.x * w - boxW / 2,
          top: p.y * h,
          child: reveal(SkylineLayer.sky, i, 0.7, silhouette(p, boxH)),
        ));
      }

      // Calque 2 — Monuments (plan moyen, légèrement translucide pour la profondeur)
      for (var i = 0; i < composition.monuments.length; i++) {
        final p = composition.monuments[i];
        final boxH = h * 0.66 * p.scale;
        final boxW = boxH * p.aspect;
        children.add(Positioned(
          left: p.x * w - boxW / 2,
          bottom: h - groundTop - 1,
          child: reveal(SkylineLayer.monuments, i, 0.85, silhouette(p, boxH)),
        ));
      }

      // Ligne de sol / fleuve
      children.add(Positioned(
        left: 0,
        right: 0,
        top: groundTop - h * 0.02,
        bottom: 0,
        child: CustomPaint(
          painter: _GroundPainter(style: composition.groundStyle, seed: composition.groundSeed),
        ),
      ));

      // Calque 3 — Premier plan
      for (var i = 0; i < composition.foreground.length; i++) {
        final p = composition.foreground[i];
        final boxH = h * 0.27 * p.scale;
        final boxW = boxH * p.aspect;
        children.add(Positioned(
          left: p.x * w - boxW / 2,
          bottom: h - groundTop - h * 0.02,
          child: reveal(SkylineLayer.foreground, i, 1, silhouette(p, boxH)),
        ));
      }

      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              backgroundColor,
              Color.lerp(backgroundColor, glowColor ?? silhouetteColor, 0.12)!,
            ],
          ),
        ),
        child: ClipRect(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(silhouetteColor, BlendMode.srcIn),
            child: Stack(clipBehavior: Clip.hardEdge, children: children),
          ),
        ),
      );
    });
  }
}

class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.style, required this.seed});

  final GroundStyle style;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final fill = Paint()..color = const Color(0xFF000000);
    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = size.height * 0.12;

    canvas.saveLayer(Offset.zero & size, Paint());
    final path = Path()..moveTo(0, size.height);
    switch (style) {
      case GroundStyle.river:
        path.lineTo(0, top);
        for (double x = 0; x <= size.width; x += 8) {
          path.lineTo(x, top + math.sin(x / 22 + seed) * 1.6);
        }
      case GroundStyle.street:
        path.lineTo(0, top);
        path.lineTo(size.width, top);
      case GroundStyle.dunes:
        path.lineTo(0, top + 4);
        for (double x = 0; x <= size.width; x += 6) {
          path.lineTo(x, top + math.sin(x / 70 + seed * 0.1) * 4);
        }
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, fill);

    // Reflets / pavés évidés pour donner de la matière.
    final rows = 3;
    for (var row = 0; row < rows; row++) {
      final yy = top + (size.height - top) * (row + 1) / (rows + 1);
      var x = r.nextDouble() * 30;
      while (x < size.width) {
        final len = style == GroundStyle.street ? 14.0 : 8 + r.nextDouble() * 26;
        canvas.drawLine(Offset(x, yy), Offset(x + len, yy), clear);
        x += len + 10 + r.nextDouble() * (style == GroundStyle.street ? 10 : 40);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.style != style || old.seed != seed;
}
