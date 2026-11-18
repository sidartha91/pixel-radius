import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Carte du monde vectorielle intégrée (Natural Earth 1:50m, domaine public).
///
/// Aucun nom de ville ni de pays, aucune clé d'API, fonctionne hors ligne et
/// prend les couleurs du thème (Cyber-Soul / Vinyle Vintage).
class WorldMapLayer extends StatefulWidget {
  const WorldMapLayer({
    super.key,
    required this.landColor,
    required this.borderColor,
  });

  static const String assetPath = 'assets/data/world_countries.json';

  final Color landColor;
  final Color borderColor;

  static Future<List<List<LatLng>>>? _cache;

  static Future<List<List<LatLng>>> load() {
    return _cache ??= () async {
      final raw = await rootBundle.loadString(assetPath);
      return compute(_parse, raw);
    }();
  }

  static List<List<LatLng>> _parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final polygons = <List<LatLng>>[];
    for (final ring in data['polygons'] as List) {
      final flat = (ring as List).cast<num>();
      final points = <LatLng>[];
      for (var i = 0; i + 1 < flat.length; i += 2) {
        points.add(LatLng(flat[i + 1].toDouble(), flat[i].toDouble()));
      }
      polygons.add(points);
    }
    return polygons;
  }

  /// Méridiens et parallèles discrets (style « radar » Cyber-Soul).
  static List<Polyline> graticule(Color color) {
    final lines = <Polyline>[];
    for (var lat = -60; lat <= 60; lat += 30) {
      lines.add(Polyline(
        points: <LatLng>[for (var lng = -180; lng <= 180; lng += 10) LatLng(lat.toDouble(), lng.toDouble())],
        color: color,
        strokeWidth: lat == 0 ? 1.2 : 0.6,
      ));
    }
    for (var lng = -180; lng <= 180; lng += 30) {
      lines.add(Polyline(
        points: <LatLng>[for (var lat = -80; lat <= 80; lat += 10) LatLng(lat.toDouble(), lng.toDouble())],
        color: color,
        strokeWidth: 0.6,
      ));
    }
    return lines;
  }

  @override
  State<WorldMapLayer> createState() => _WorldMapLayerState();
}

class _WorldMapLayerState extends State<WorldMapLayer> {
  List<List<LatLng>>? _shapes;

  @override
  void initState() {
    super.initState();
    WorldMapLayer.load().then((shapes) {
      if (mounted) setState(() => _shapes = shapes);
    }).catchError((Object e) {
      debugPrint('[WorldMapLayer] $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final shapes = _shapes;
    if (shapes == null) return const SizedBox.shrink();
    return PolygonLayer(
      polygons: <Polygon>[
        for (final points in shapes)
          Polygon(
            points: points,
            color: widget.landColor,
            borderColor: widget.borderColor,
            borderStrokeWidth: 0.7,
          ),
      ],
    );
  }
}
