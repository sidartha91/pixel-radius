import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Données « lumières de la Terre la nuit » : 7 300 villes réelles (Natural
/// Earth, domaine public) + semis procédural, et étoiles sur l'océan.
class NightLightsData {
  NightLightsData._(this.lights, this.levels, this.stars);

  static const String assetPath = 'assets/data/night_lights.json';
  static Future<NightLightsData>? _cache;

  final List<LatLng> lights;

  /// -1 = texture diffuse, 0..3 = ville petite → mégapole.
  final Int8List levels;
  final List<LatLng> stars;

  static Future<NightLightsData> load() {
    return _cache ??= () async {
      final raw = await rootBundle.loadString(assetPath);
      final parsed = await compute(_parse, raw);
      return NightLightsData._(
        <LatLng>[for (var i = 0; i < parsed.$1.length; i += 2) LatLng(parsed.$1[i + 1], parsed.$1[i])],
        parsed.$2,
        <LatLng>[for (var i = 0; i < parsed.$3.length; i += 2) LatLng(parsed.$3[i + 1], parsed.$3[i])],
      );
    }();
  }

  static (Float64List, Int8List, Float64List) _parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final lights = data['lights'] as List;
    final coords = Float64List(lights.length * 2);
    final levels = Int8List(lights.length);
    for (var i = 0; i < lights.length; i++) {
      final l = lights[i] as List;
      coords[i * 2] = (l[0] as num).toDouble();
      coords[i * 2 + 1] = (l[1] as num).toDouble();
      levels[i] = (l[2] as num).toInt();
    }
    final stars = data['stars'] as List;
    final starCoords = Float64List(stars.length * 2);
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i] as List;
      starCoords[i * 2] = (s[0] as num).toDouble();
      starCoords[i * 2 + 1] = (s[1] as num).toDouble();
    }
    return (coords, levels, starCoords);
  }
}

enum NightLayerKind { stars, lights }

/// Calque flutter_map dessinant les étoiles (sous les terres) ou les
/// lumières des villes (au-dessus), avec halo ambré et scintillements.
class NightLightsLayer extends StatefulWidget {
  const NightLightsLayer({super.key, required this.kind});

  final NightLayerKind kind;

  @override
  State<NightLightsLayer> createState() => _NightLightsLayerState();
}

class _NightLightsLayerState extends State<NightLightsLayer> {
  NightLightsData? _data;

  @override
  void initState() {
    super.initState();
    NightLightsData.load().then((d) {
      if (mounted) setState(() => _data = d);
    }).catchError((Object e) {
      debugPrint('[NightLightsLayer] $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final camera = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _NightPainter(data: data, camera: camera, kind: widget.kind),
      ),
    );
  }
}

class _NightPainter extends CustomPainter {
  _NightPainter({required this.data, required this.camera, required this.kind});

  final NightLightsData data;
  final MapCamera camera;
  final NightLayerKind kind;

  static const Color _amber = Color(0xFFE5A93C);
  static const Color _ember = Color(0xFFC8782A);
  static const Color _hot = Color(0xFFFFD9A0);

  @override
  void paint(Canvas canvas, Size size) {
    final zoomScale = (camera.zoom / 2.2).clamp(0.75, 3.0);
    final bounds = Offset.zero & size;
    final inflated = bounds.inflate(12);

    if (kind == NightLayerKind.stars) {
      final pts = <double>[];
      for (final p in data.stars) {
        final o = camera.getOffsetFromOrigin(p);
        if (inflated.contains(o)) pts..add(o.dx)..add(o.dy);
      }
      final paint = Paint()
        ..color = _amber.withValues(alpha: 0.45)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6;
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(pts), paint);
      return;
    }

    // Regroupe les points visibles par intensité.
    final buckets = List<List<double>>.generate(5, (_) => <double>[]);
    final megacities = <Offset>[];
    for (var i = 0; i < data.lights.length; i++) {
      final o = camera.getOffsetFromOrigin(data.lights[i]);
      if (!inflated.contains(o)) continue;
      final level = data.levels[i];
      buckets[level + 1]..add(o.dx)..add(o.dy);
      if (level == 3) megacities.add(o);
    }

    // 1) Halo diffus (glow ambré)
    final halo = Paint()
      ..color = _ember.withValues(alpha: 0.32)
      ..strokeCap = StrokeCap.round
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3.5 * zoomScale);
    for (var b = 0; b < buckets.length; b++) {
      if (buckets[b].isEmpty) continue;
      halo.strokeWidth = (3.0 + b * 1.6) * zoomScale;
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(buckets[b]), halo);
    }

    // 2) Cœurs lumineux
    final core = Paint()..strokeCap = StrokeCap.round;
    for (var b = 0; b < buckets.length; b++) {
      if (buckets[b].isEmpty) continue;
      core
        ..color = b == 0 ? _amber.withValues(alpha: 0.75) : (b >= 3 ? _hot : _amber)
        ..strokeWidth = (0.9 + b * 0.45) * zoomScale;
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(buckets[b]), core);
    }

    // 3) Scintillements en étoile sur les mégapoles
    final sparkle = Paint()
      ..color = _hot.withValues(alpha: 0.9)
      ..strokeWidth = 0.9 * zoomScale
      ..strokeCap = StrokeCap.round;
    final arm = 6.0 * zoomScale;
    for (final o in megacities) {
      canvas.drawLine(o - Offset(arm, 0), o + Offset(arm, 0), sparkle);
      canvas.drawLine(o - Offset(0, arm), o + Offset(0, arm), sparkle);
    }
  }

  @override
  bool shouldRepaint(_NightPainter old) =>
      old.camera != camera || old.kind != kind || old.data != data;
}
