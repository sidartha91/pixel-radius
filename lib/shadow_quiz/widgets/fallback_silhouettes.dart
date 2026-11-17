import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Fallback vectoriel : dessine une silhouette élégante par `CustomPainter`
/// lorsque le fichier SVG correspondant est absent des assets.
/// Toutes les formes sont dessinées en noir ; le `ColorFilter` global du
/// bandeau les recolore ensuite (ambre ou noir encre).
class FallbackSilhouette extends StatelessWidget {
  const FallbackSilhouette({super.key, required this.shape, this.seed = 0});

  final String shape;

  /// Graine permettant de petites variations (fenêtres, proportions).
  final int seed;

  /// Formes supportées (utile pour valider le catalogue).
  static const Set<String> supportedShapes = <String>{
    // Monuments
    'building', 'lattice_tower', 'tv_tower', 'skyscraper', 'skyscraper_spire', 'dome',
    'mosque', 'minaret', 'stupa', 'pagoda', 'torii', 'temple', 'arch', 'gate',
    'clock_tower', 'cathedral', 'pyramid', 'statue', 'bridge', 'ferris_wheel',
    'opera_sails', 'colonial', 'mountain', 'obelisk', 'castle', 'windmill',
    'onion_domes', 'lighthouse',
    // Culture & vie quotidienne
    'person', 'person_hat', 'robed_person', 'dancer', 'musician', 'food_stall',
    'umbrella_stall', 'boat', 'canoe', 'car', 'bus', 'tram', 'cyclist', 'tuk_tuk',
    'train', 'palm', 'tree', 'animal_cart', 'camel', 'elephant', 'cafe_table',
    // Ciel
    'cloud', 'birds', 'moon', 'sun',
  };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SilhouettePainter(shape, seed),
      child: const SizedBox.expand(),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter(this.shape, this.seed);

  final String shape;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pen = _Pen(canvas, size, seed);
    canvas.saveLayer(Offset.zero & size, Paint());
    switch (shape) {
      case 'lattice_tower':
        pen.latticeTower();
      case 'tv_tower':
        pen.tvTower();
      case 'skyscraper':
        pen.skyscraper();
      case 'skyscraper_spire':
        pen.skyscraperSpire();
      case 'dome':
        pen.dome();
      case 'mosque':
        pen.mosque();
      case 'minaret':
        pen.minaret(0.35, 0.65, 0.12);
      case 'stupa':
        pen.stupa();
      case 'pagoda':
        pen.pagoda();
      case 'torii':
        pen.torii();
      case 'temple':
        pen.temple();
      case 'arch':
        pen.arch();
      case 'gate':
        pen.gate();
      case 'clock_tower':
        pen.clockTower();
      case 'cathedral':
        pen.cathedral();
      case 'pyramid':
        pen.pyramid();
      case 'statue':
        pen.statue();
      case 'bridge':
        pen.bridge();
      case 'ferris_wheel':
        pen.ferrisWheel();
      case 'opera_sails':
        pen.operaSails();
      case 'colonial':
        pen.colonial();
      case 'mountain':
        pen.mountain();
      case 'obelisk':
        pen.obelisk();
      case 'castle':
        pen.castle();
      case 'windmill':
        pen.windmill();
      case 'onion_domes':
        pen.onionDomes();
      case 'lighthouse':
        pen.lighthouse();
      case 'person':
        pen.person(0.5, hat: false);
      case 'person_hat':
        pen.person(0.5, hat: true);
      case 'robed_person':
        pen.robedPerson();
      case 'dancer':
        pen.dancer();
      case 'musician':
        pen.musician();
      case 'food_stall':
        pen.foodStall();
      case 'umbrella_stall':
        pen.umbrellaStall();
      case 'boat':
        pen.boat();
      case 'canoe':
        pen.canoe();
      case 'car':
        pen.car();
      case 'bus':
        pen.bus();
      case 'tram':
        pen.tram();
      case 'cyclist':
        pen.cyclist();
      case 'tuk_tuk':
        pen.tukTuk();
      case 'train':
        pen.train();
      case 'palm':
        pen.palm();
      case 'tree':
        pen.tree();
      case 'animal_cart':
        pen.animalCart();
      case 'camel':
        pen.camel(0.5);
      case 'elephant':
        pen.elephant();
      case 'cafe_table':
        pen.cafeTable();
      case 'cloud':
        pen.cloud();
      case 'birds':
        pen.birds();
      case 'moon':
        pen.moon();
      case 'sun':
        pen.sun();
      default:
        pen.building();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.shape != shape || old.seed != seed;
}

/// Outil de dessin en coordonnées relatives (0..1), y=1 = sol.
class _Pen {
  _Pen(this.c, this.s, this.seed)
      : fill = Paint()
          ..color = const Color(0xFF000000)
          ..isAntiAlias = true,
        clear = Paint()
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;

  final Canvas c;
  final Size s;
  final int seed;
  final Paint fill;
  final Paint clear;

  double x(double f) => f * s.width;
  double y(double f) => f * s.height;
  Offset o(double fx, double fy) => Offset(x(fx), y(fy));

  void rect(double l, double t, double r, double b, {bool hole = false}) =>
      c.drawRect(Rect.fromLTRB(x(l), y(t), x(r), y(b)), hole ? clear : fill);

  void rrect(double l, double t, double r, double b, double radius, {bool hole = false}) => c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(x(l), y(t), x(r), y(b)), Radius.circular(radius * s.width)),
      hole ? clear : fill);

  void oval(double cx, double cy, double rx, double ry, {bool hole = false}) =>
      c.drawOval(Rect.fromCenter(center: o(cx, cy), width: x(rx) * 2, height: y(ry) * 2), hole ? clear : fill);

  void circle(double cx, double cy, double r, {bool hole = false}) =>
      c.drawCircle(o(cx, cy), r * math.min(s.width, s.height), hole ? clear : fill);

  void poly(List<double> pts, {bool hole = false}) {
    final path = Path()..moveTo(x(pts[0]), y(pts[1]));
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(x(pts[i]), y(pts[i + 1]));
    }
    path.close();
    c.drawPath(path, hole ? clear : fill);
  }

  /// Demi-ellipse supérieure (dôme) posée sur la ligne cy.
  void halfDome(double cx, double cy, double rx, double ry, {bool hole = false}) {
    final path = Path()
      ..moveTo(x(cx - rx), y(cy))
      ..arcTo(Rect.fromCenter(center: o(cx, cy), width: x(rx) * 2, height: y(ry) * 2), math.pi, math.pi, false)
      ..close();
    c.drawPath(path, hole ? clear : fill);
  }

  /// Arche (rectangle surmonté d'un demi-cercle) — utilisé pour les trous.
  void archShape(double l, double r, double springY, double bottom, {bool hole = true}) {
    final rx = (r - l) / 2;
    final path = Path()
      ..moveTo(x(l), y(bottom))
      ..lineTo(x(l), y(springY))
      ..arcTo(Rect.fromLTRB(x(l), y(springY) - x(rx), x(r), y(springY) + x(rx)), math.pi, math.pi, false)
      ..lineTo(x(r), y(bottom))
      ..close();
    c.drawPath(path, hole ? clear : fill);
  }

  void line(double x1, double y1, double x2, double y2, double width, {bool hole = false}) {
    final p = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = width * s.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (hole) p.blendMode = BlendMode.clear;
    c.drawLine(o(x1, y1), o(x2, y2), p);
  }

  void ring(double cx, double cy, double r, double width) {
    final p = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = width * s.width
      ..style = PaintingStyle.stroke;
    c.drawCircle(o(cx, cy), r * s.width, p);
  }

  void quadStroke(double x1, double y1, double qx, double qy, double x2, double y2, double width) {
    final p = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = width * s.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(Path()
      ..moveTo(x(x1), y(y1))
      ..quadraticBezierTo(x(qx), y(qy), x(x2), y(y2)), p);
  }

  void windows(double l, double t, double r, double b, int cols, int rows) {
    final cw = (r - l) / (cols * 2 + 1);
    final rh = (b - t) / (rows * 2 + 1);
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        if ((i * 7 + j * 3 + seed) % 5 == 0) continue; // quelques fenêtres « éteintes »
        rect(l + cw * (i * 2 + 1), t + rh * (j * 2 + 1), l + cw * (i * 2 + 2), t + rh * (j * 2 + 2), hole: true);
      }
    }
  }

  // ───────────────────────── Monuments ─────────────────────────

  void building() {
    rect(0.15, 0.4, 0.85, 1);
    poly([0.1, 0.42, 0.5, 0.18, 0.9, 0.42]);
    windows(0.2, 0.48, 0.8, 0.95, 3, 3);
  }

  void latticeTower() {
    poly([0.12, 1, 0.3, 1, 0.5, 0.62, 0.7, 1, 0.88, 1, 0.56, 0.1, 0.44, 0.1]);
    archShape(0.32, 0.68, 0.9, 1);
    rect(0.27, 0.66, 0.73, 0.7);
    rect(0.37, 0.42, 0.63, 0.45);
    rect(0.47, 0.0, 0.53, 0.12);
    // treillis
    for (var i = 0; i < 6; i++) {
      final t = 0.18 + i * 0.07;
      line(0.5 - 0.02 - i * 0.012, t, 0.5 + 0.02 + i * 0.012, t + 0.05, 0.008, hole: true);
    }
  }

  void tvTower() {
    rect(0.47, 0.0, 0.53, 1);
    poly([0.36, 1, 0.47, 0.6, 0.53, 0.6, 0.64, 1]);
    oval(0.5, 0.3, 0.17, 0.05);
    oval(0.5, 0.34, 0.12, 0.03);
    oval(0.5, 0.14, 0.06, 0.02);
    rect(0.4, 0.29, 0.6, 0.31, hole: true);
  }

  void skyscraper() {
    rect(0.3, 0.2, 0.7, 1);
    rect(0.35, 0.12, 0.65, 0.2);
    rect(0.42, 0.06, 0.58, 0.12);
    rect(0.49, 0.0, 0.51, 0.06);
    windows(0.32, 0.24, 0.68, 0.98, 4, 9);
  }

  void skyscraperSpire() {
    poly([0.32, 1, 0.32, 0.3, 0.4, 0.22, 0.6, 0.22, 0.68, 0.3, 0.68, 1]);
    poly([0.4, 0.22, 0.5, 0.0, 0.6, 0.22]);
    for (var i = 0; i < 3; i++) {
      halfDome(0.5, 0.22 - i * 0.05, 0.08 - i * 0.02, 0.04, hole: true);
    }
    windows(0.34, 0.33, 0.66, 0.98, 3, 8);
  }

  void dome() {
    rect(0.1, 0.62, 0.9, 1);
    rect(0.28, 0.45, 0.72, 0.62);
    halfDome(0.5, 0.46, 0.24, 0.22);
    rect(0.46, 0.17, 0.54, 0.26);
    poly([0.47, 0.17, 0.5, 0.08, 0.53, 0.17]);
    for (var i = 0; i < 6; i++) {
      rect(0.15 + i * 0.125, 0.7, 0.19 + i * 0.125, 0.96, hole: true);
    }
  }

  void minaret(double l, double r, double top) {
    final w = r - l;
    rect(l, top + 0.18, r, 1);
    rect(l - w * 0.15, top + 0.14, r + w * 0.15, top + 0.18);
    rect(l + w * 0.18, top + 0.04, r - w * 0.18, top + 0.14);
    halfDome((l + r) / 2, top + 0.04, w * 0.32, 0.04);
    rect((l + r) / 2 - 0.006, top - 0.04, (l + r) / 2 + 0.006, top);
  }

  void mosque() {
    rect(0.15, 0.62, 0.85, 1);
    halfDome(0.5, 0.62, 0.26, 0.28);
    rect(0.49, 0.26, 0.51, 0.34);
    circle(0.5, 0.25, 0.015);
    minaret(0.04, 0.12, 0.1);
    minaret(0.88, 0.96, 0.1);
    for (var i = 0; i < 4; i++) {
      archShape(0.22 + i * 0.15, 0.3 + i * 0.15, 0.8, 1);
    }
  }

  void stupa() {
    rect(0.05, 0.92, 0.95, 1);
    rect(0.14, 0.85, 0.86, 0.92);
    halfDome(0.5, 0.86, 0.32, 0.38);
    rect(0.42, 0.42, 0.58, 0.5);
    poly([0.44, 0.42, 0.5, 0.04, 0.56, 0.42]);
    for (var i = 0; i < 4; i++) {
      rect(0.42, 0.34 - i * 0.07, 0.58, 0.345 - i * 0.07, hole: true);
    }
  }

  void pagoda() {
    const tiers = 5;
    for (var i = 0; i < tiers; i++) {
      final b = 1 - i * 0.17;
      final half = 0.42 - i * 0.06;
      rect(0.5 - half * 0.6, b - 0.12, 0.5 + half * 0.6, b);
      poly([
        0.5 - half - 0.04, b - 0.13,
        0.5 - half, b - 0.11,
        0.5 + half, b - 0.11,
        0.5 + half + 0.04, b - 0.13,
        0.5 + half * 0.5, b - 0.17,
        0.5 - half * 0.5, b - 0.17,
      ]);
    }
    rect(0.49, 0.0, 0.51, 0.16);
    for (var i = 0; i < 4; i++) {
      oval(0.5, 0.04 + i * 0.03, 0.025, 0.008);
    }
  }

  void torii() {
    rect(0.2, 0.22, 0.27, 1);
    rect(0.73, 0.22, 0.8, 1);
    poly([0.02, 0.1, 0.15, 0.16, 0.85, 0.16, 0.98, 0.1, 0.96, 0.18, 0.04, 0.18]);
    rect(0.1, 0.24, 0.9, 0.29);
    rect(0.47, 0.18, 0.53, 0.24);
  }

  void temple() {
    rect(0.05, 0.92, 0.95, 1);
    rect(0.08, 0.88, 0.92, 0.92);
    for (var i = 0; i < 6; i++) {
      rect(0.12 + i * 0.13, 0.48, 0.18 + i * 0.13, 0.88);
    }
    rect(0.08, 0.42, 0.92, 0.48);
    poly([0.06, 0.42, 0.5, 0.22, 0.94, 0.42]);
  }

  void arch() {
    rect(0.08, 0.12, 0.92, 1);
    rect(0.04, 0.12, 0.96, 0.2);
    archShape(0.36, 0.64, 0.52, 1);
    rect(0.18, 0.62, 0.28, 0.8, hole: true);
    rect(0.72, 0.62, 0.82, 0.8, hole: true);
  }

  void gate() {
    rect(0.0, 0.28, 1, 1);
    for (var i = 0; i < 6; i++) {
      rect(0.02 + i * 0.17, 0.2, 0.12 + i * 0.17, 0.28);
    }
    archShape(0.3, 0.7, 0.55, 1);
    oval(0.5, 0.55, 0.2, 0.06, hole: false);
    archShape(0.33, 0.67, 0.6, 1);
    rect(0.08, 0.4, 0.2, 0.44, hole: true);
    rect(0.8, 0.4, 0.92, 0.44, hole: true);
  }

  void clockTower() {
    rect(0.33, 0.3, 0.67, 1);
    rect(0.3, 0.26, 0.7, 0.3);
    circle(0.5, 0.4, 0.07);
    circle(0.5, 0.4, 0.05, hole: true);
    line(0.5, 0.4, 0.5, 0.36, 0.015);
    line(0.5, 0.4, 0.53, 0.41, 0.015);
    rect(0.36, 0.16, 0.64, 0.26);
    archShape(0.4, 0.48, 0.2, 0.25);
    archShape(0.52, 0.6, 0.2, 0.25);
    poly([0.34, 0.16, 0.5, 0.0, 0.66, 0.16]);
    windows(0.36, 0.55, 0.64, 0.95, 2, 4);
  }

  void cathedral() {
    rect(0.05, 0.25, 0.32, 1);
    rect(0.68, 0.25, 0.95, 1);
    rect(0.3, 0.38, 0.7, 1);
    poly([0.3, 0.4, 0.5, 0.3, 0.7, 0.4]);
    rect(0.48, 0.08, 0.52, 0.32);
    poly([0.47, 0.12, 0.5, 0.02, 0.53, 0.12]);
    circle(0.5, 0.56, 0.1, hole: true);
    circle(0.5, 0.56, 0.04);
    archShape(0.4, 0.6, 0.8, 1);
    archShape(0.12, 0.25, 0.4, 0.62);
    archShape(0.75, 0.88, 0.4, 0.62);
    for (var i = 0; i < 4; i++) {
      rect(0.06 + i * 0.07, 0.21, 0.1 + i * 0.07, 0.25);
      rect(0.69 + i * 0.07, 0.21, 0.73 + i * 0.07, 0.25);
    }
  }

  void pyramid() {
    poly([0.0, 1, 0.42, 0.25, 0.84, 1]);
    poly([0.55, 1, 0.8, 0.55, 1.0, 1]);
  }

  void statue() {
    rect(0.3, 0.68, 0.7, 1);
    rect(0.26, 0.64, 0.74, 0.68);
    poly([0.38, 0.64, 0.42, 0.3, 0.58, 0.3, 0.62, 0.64]);
    circle(0.5, 0.25, 0.06);
    line(0.56, 0.33, 0.68, 0.08, 0.05);
    poly([0.64, 0.08, 0.72, 0.08, 0.68, 0.0]);
    line(0.43, 0.36, 0.36, 0.5, 0.05);
  }

  void bridge() {
    rect(0.0, 0.68, 1, 0.74);
    rect(0.2, 0.15, 0.28, 1);
    rect(0.72, 0.15, 0.8, 1);
    poly([0.19, 0.15, 0.24, 0.06, 0.29, 0.15]);
    poly([0.71, 0.15, 0.76, 0.06, 0.81, 0.15]);
    quadStroke(0.0, 0.5, 0.12, 0.62, 0.24, 0.2, 0.012);
    quadStroke(0.24, 0.2, 0.5, 0.65, 0.76, 0.2, 0.012);
    quadStroke(0.76, 0.2, 0.88, 0.62, 1.0, 0.5, 0.012);
    for (var i = 1; i < 10; i++) {
      final fx = 0.24 + i * 0.052;
      final t = (fx - 0.24) / 0.52;
      final cy = (1 - t) * (1 - t) * 0.2 + 2 * (1 - t) * t * 0.65 + t * t * 0.2;
      line(fx, cy, fx, 0.68, 0.005);
    }
    rect(0.2, 0.32, 0.28, 0.36, hole: true);
    rect(0.72, 0.32, 0.8, 0.36, hole: true);
  }

  void ferrisWheel() {
    ring(0.5, 0.42, 0.38, 0.03);
    ring(0.5, 0.42, 0.06, 0.03);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final ex = 0.5 + math.cos(a) * 0.38;
      final ey = 0.42 + math.sin(a) * 0.38 * s.width / s.height;
      line(0.5, 0.42, ex, ey, 0.008);
      oval(ex, ey + 0.03, 0.035, 0.025);
    }
    poly([0.3, 1, 0.48, 0.42, 0.52, 0.42, 0.7, 1, 0.64, 1, 0.5, 0.5, 0.36, 1]);
  }

  void operaSails() {
    rect(0.0, 0.85, 1, 1);
    for (var i = 0; i < 4; i++) {
      final l = 0.05 + i * 0.2;
      final top = 0.3 + (i % 2) * 0.15;
      final p = Path()
        ..moveTo(x(l), y(0.86))
        ..quadraticBezierTo(x(l + 0.02), y(top), x(l + 0.3), y(top - 0.05))
        ..quadraticBezierTo(x(l + 0.18), y(0.55), x(l + 0.24), y(0.86))
        ..close();
      c.drawPath(p, fill);
    }
  }

  void colonial() {
    rect(0.05, 0.4, 0.95, 1);
    rect(0.02, 0.36, 0.98, 0.4);
    poly([0.3, 0.36, 0.5, 0.2, 0.7, 0.36]);
    halfDome(0.5, 0.2, 0.08, 0.1);
    rect(0.495, 0.04, 0.505, 0.11);
    for (var i = 0; i < 8; i++) {
      archShape(0.09 + i * 0.11, 0.15 + i * 0.11, 0.55, 0.72);
      archShape(0.09 + i * 0.11, 0.15 + i * 0.11, 0.82, 1.0);
    }
  }

  void mountain() {
    poly([0.0, 1, 0.38, 0.12, 0.52, 0.3, 0.62, 0.22, 1.0, 1]);
    poly([0.3, 0.3, 0.38, 0.12, 0.46, 0.26, 0.41, 0.24, 0.37, 0.3, 0.34, 0.26], hole: true);
  }

  void obelisk() {
    rect(0.3, 0.9, 0.7, 1);
    poly([0.4, 0.9, 0.44, 0.1, 0.56, 0.1, 0.6, 0.9]);
    poly([0.44, 0.1, 0.5, 0.0, 0.56, 0.1]);
  }

  void castle() {
    rect(0.15, 0.45, 0.85, 1);
    rect(0.02, 0.25, 0.22, 1);
    rect(0.78, 0.25, 0.98, 1);
    rect(0.4, 0.15, 0.6, 0.45);
    for (var i = 0; i < 3; i++) {
      rect(0.02 + i * 0.075, 0.19, 0.06 + i * 0.075, 0.25);
      rect(0.78 + i * 0.075, 0.19, 0.82 + i * 0.075, 0.25);
      rect(0.4 + i * 0.075, 0.09, 0.44 + i * 0.075, 0.15);
    }
    archShape(0.42, 0.58, 0.8, 1);
    rect(0.48, 0.0, 0.5, 0.09);
    poly([0.5, 0.0, 0.6, 0.025, 0.5, 0.05]);
  }

  void windmill() {
    poly([0.32, 1, 0.4, 0.35, 0.6, 0.35, 0.68, 1]);
    poly([0.36, 0.36, 0.5, 0.24, 0.64, 0.36]);
    final cx = 0.5, cy = 0.3;
    for (var i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      line(cx, cy, cx + math.cos(a) * 0.42, cy + math.sin(a) * 0.3, 0.05);
    }
    archShape(0.45, 0.55, 0.85, 1);
  }

  void onionDomes() {
    void onion(double cx, double base, double r) {
      rect(cx - r * 0.75, base, cx + r * 0.75, 1);
      final p = Path()
        ..moveTo(x(cx - r * 0.75), y(base))
        ..cubicTo(x(cx - r * 1.4), y(base - 0.08), x(cx - 0.01), y(base - 0.14), x(cx), y(base - 0.2))
        ..cubicTo(x(cx + 0.01), y(base - 0.14), x(cx + r * 1.4), y(base - 0.08), x(cx + r * 0.75), y(base))
        ..close();
      c.drawPath(p, fill);
      line(cx, base - 0.2, cx, base - 0.26, 0.01);
    }

    onion(0.5, 0.32, 0.12);
    onion(0.22, 0.5, 0.09);
    onion(0.78, 0.5, 0.09);
    rect(0.08, 0.7, 0.92, 1);
    for (var i = 0; i < 5; i++) {
      archShape(0.14 + i * 0.16, 0.22 + i * 0.16, 0.82, 1);
    }
  }

  void lighthouse() {
    poly([0.36, 1, 0.42, 0.28, 0.58, 0.28, 0.64, 1]);
    rect(0.38, 0.24, 0.62, 0.28);
    rect(0.42, 0.14, 0.58, 0.24);
    rect(0.44, 0.16, 0.56, 0.22, hole: true);
    halfDome(0.5, 0.14, 0.09, 0.06);
    for (var i = 0; i < 3; i++) {
      final t = 0.42 + i * 0.18;
      rect(0.3, t, 0.7, t + 0.05, hole: true);
    }
  }

  // ───────────────────── Culture & vie quotidienne ─────────────────────

  void person(double cx, {required bool hat}) {
    circle(cx, 0.14, 0.09);
    poly([cx - 0.14, 0.62, cx - 0.1, 0.26, cx + 0.1, 0.26, cx + 0.14, 0.62]);
    rect(cx - 0.1, 0.6, cx - 0.03, 1);
    rect(cx + 0.03, 0.6, cx + 0.1, 1);
    line(cx - 0.11, 0.3, cx - 0.2, 0.58, 0.06);
    line(cx + 0.11, 0.3, cx + 0.2, 0.58, 0.06);
    if (hat) {
      oval(cx, 0.08, 0.22, 0.03);
      halfDome(cx, 0.08, 0.1, 0.07);
    }
  }

  void robedPerson() {
    circle(0.5, 0.12, 0.09);
    poly([0.38, 0.14, 0.5, 0.0, 0.62, 0.14, 0.6, 0.24, 0.4, 0.24]);
    poly([0.24, 1, 0.38, 0.24, 0.62, 0.24, 0.76, 1]);
    line(0.4, 0.3, 0.22, 0.55, 0.06);
  }

  void dancer() {
    circle(0.5, 0.12, 0.08);
    poly([0.42, 0.5, 0.45, 0.22, 0.55, 0.22, 0.58, 0.5]);
    quadStroke(0.45, 0.25, 0.25, 0.25, 0.15, 0.05, 0.05);
    quadStroke(0.55, 0.25, 0.75, 0.3, 0.88, 0.18, 0.05);
    poly([0.2, 0.78, 0.42, 0.48, 0.58, 0.48, 0.82, 0.74, 0.5, 0.8]);
    line(0.45, 0.78, 0.4, 1, 0.05);
    line(0.55, 0.78, 0.66, 0.98, 0.05);
  }

  void musician() {
    person(0.4, hat: true);
    oval(0.58, 0.56, 0.13, 0.12);
    circle(0.58, 0.54, 0.03, hole: true);
    line(0.6, 0.48, 0.9, 0.18, 0.04);
  }

  void foodStall() {
    rect(0.1, 0.45, 0.9, 0.82);
    poly([0.04, 0.32, 0.96, 0.32, 0.9, 0.42, 0.1, 0.42]);
    for (var i = 0; i < 6; i++) {
      halfDome(0.1 + i * 0.16 + 0.08, 0.42, 0.08, 0.04);
    }
    rect(0.12, 0.32, 0.15, 0.45);
    rect(0.85, 0.32, 0.88, 0.45);
    circle(0.25, 0.9, 0.09);
    circle(0.75, 0.9, 0.09);
    circle(0.25, 0.9, 0.04, hole: true);
    circle(0.75, 0.9, 0.04, hole: true);
    quadStroke(0.35, 0.28, 0.3, 0.2, 0.36, 0.1, 0.02);
    quadStroke(0.5, 0.28, 0.45, 0.18, 0.51, 0.06, 0.02);
    quadStroke(0.65, 0.28, 0.6, 0.2, 0.66, 0.1, 0.02);
    rect(0.2, 0.55, 0.8, 0.6, hole: true);
  }

  void umbrellaStall() {
    halfDome(0.5, 0.3, 0.46, 0.24);
    for (var i = 0; i < 4; i++) {
      halfDome(0.15 + i * 0.233, 0.3, 0.11, 0.04, hole: true);
    }
    rect(0.49, 0.3, 0.51, 1);
    rect(0.18, 0.62, 0.82, 0.68);
    rect(0.22, 0.68, 0.26, 1);
    rect(0.74, 0.68, 0.78, 1);
    oval(0.38, 0.58, 0.08, 0.04);
    oval(0.62, 0.58, 0.08, 0.04);
  }

  void boat() {
    poly([0.0, 0.7, 1.0, 0.7, 0.86, 0.95, 0.12, 0.95]);
    rect(0.48, 0.05, 0.51, 0.7);
    poly([0.52, 0.08, 0.92, 0.62, 0.52, 0.62]);
    poly([0.47, 0.15, 0.47, 0.62, 0.15, 0.62]);
  }

  void canoe() {
    final p = Path()
      ..moveTo(x(0.0), y(0.72))
      ..quadraticBezierTo(x(0.5), y(1.02), x(1.0), y(0.72))
      ..lineTo(x(0.9), y(0.8))
      ..quadraticBezierTo(x(0.5), y(0.88), x(0.1), y(0.8))
      ..close();
    c.drawPath(p, fill);
    rect(0.05, 0.78, 0.95, 0.86);
    person(0.5, hat: true);
    line(0.25, 0.25, 0.8, 0.95, 0.03);
  }

  void car() {
    rrect(0.02, 0.5, 0.98, 0.82, 0.06);
    poly([0.2, 0.52, 0.3, 0.25, 0.7, 0.25, 0.82, 0.52]);
    poly([0.34, 0.3, 0.49, 0.3, 0.49, 0.5, 0.27, 0.5], hole: true);
    poly([0.53, 0.3, 0.67, 0.3, 0.76, 0.5, 0.53, 0.5], hole: true);
    circle(0.24, 0.84, 0.12);
    circle(0.76, 0.84, 0.12);
    circle(0.24, 0.84, 0.05, hole: true);
    circle(0.76, 0.84, 0.05, hole: true);
  }

  void bus() {
    rrect(0.02, 0.06, 0.98, 0.86, 0.05);
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 5; i++) {
        rect(0.06 + i * 0.18, 0.14 + row * 0.34, 0.2 + i * 0.18, 0.34 + row * 0.34, hole: true);
      }
    }
    circle(0.22, 0.88, 0.11);
    circle(0.78, 0.88, 0.11);
    circle(0.22, 0.88, 0.045, hole: true);
    circle(0.78, 0.88, 0.045, hole: true);
  }

  void tram() {
    rrect(0.04, 0.25, 0.96, 0.88, 0.04);
    line(0.5, 0.25, 0.35, 0.05, 0.02);
    line(0.35, 0.05, 0.65, 0.05, 0.02);
    for (var i = 0; i < 5; i++) {
      rect(0.08 + i * 0.175, 0.32, 0.2 + i * 0.175, 0.55, hole: true);
    }
    circle(0.25, 0.9, 0.07);
    circle(0.75, 0.9, 0.07);
  }

  void cyclist() {
    ring(0.22, 0.8, 0.17, 0.035);
    ring(0.78, 0.8, 0.17, 0.035);
    line(0.22, 0.8, 0.45, 0.8, 0.03);
    line(0.45, 0.8, 0.68, 0.5, 0.03);
    line(0.38, 0.52, 0.68, 0.52, 0.03);
    line(0.38, 0.52, 0.22, 0.8, 0.03);
    line(0.68, 0.5, 0.78, 0.8, 0.03);
    circle(0.52, 0.1, 0.07);
    poly([0.4, 0.5, 0.46, 0.18, 0.58, 0.18, 0.52, 0.5]);
    line(0.55, 0.25, 0.7, 0.46, 0.04);
    line(0.45, 0.5, 0.5, 0.78, 0.045);
    // baguette / panier
    line(0.6, 0.2, 0.88, 0.05, 0.035);
  }

  void tukTuk() {
    poly([0.08, 0.2, 0.92, 0.2, 0.96, 0.3, 0.04, 0.3]);
    rect(0.1, 0.3, 0.13, 0.55);
    rect(0.82, 0.3, 0.85, 0.55);
    final p = Path()
      ..moveTo(x(0.04), y(0.82))
      ..lineTo(x(0.04), y(0.55))
      ..quadraticBezierTo(x(0.04), y(0.48), x(0.14), y(0.48))
      ..lineTo(x(0.7), y(0.48))
      ..quadraticBezierTo(x(0.96), y(0.5), x(0.98), y(0.82))
      ..close();
    c.drawPath(p, fill);
    circle(0.2, 0.86, 0.1);
    circle(0.8, 0.86, 0.1);
    circle(0.2, 0.86, 0.04, hole: true);
    circle(0.8, 0.86, 0.04, hole: true);
    rect(0.48, 0.55, 0.62, 0.7, hole: true);
  }

  void train() {
    final p = Path()
      ..moveTo(x(0.0), y(0.3))
      ..lineTo(x(0.7), y(0.3))
      ..quadraticBezierTo(x(1.0), y(0.35), x(1.0), y(0.85))
      ..lineTo(x(0.0), y(0.85))
      ..close();
    c.drawPath(p, fill);
    for (var i = 0; i < 5; i++) {
      rect(0.04 + i * 0.13, 0.4, 0.13 + i * 0.13, 0.55, hole: true);
    }
    poly([0.72, 0.38, 0.84, 0.42, 0.9, 0.56, 0.72, 0.56], hole: true);
    rect(0.0, 0.66, 1.0, 0.69, hole: true);
    rect(0.0, 0.88, 1.0, 0.92);
  }

  void palm() {
    quadStroke(0.5, 1.0, 0.42, 0.55, 0.56, 0.18, 0.07);
    void frond(double ex, double ey, double qx, double qy) {
      final p = Path()
        ..moveTo(x(0.56), y(0.18))
        ..quadraticBezierTo(x(qx), y(qy - 0.06), x(ex), y(ey))
        ..quadraticBezierTo(x(qx), y(qy + 0.02), x(0.56), y(0.2))
        ..close();
      c.drawPath(p, fill);
    }

    frond(0.0, 0.35, 0.28, 0.08);
    frond(0.12, 0.5, 0.3, 0.2);
    frond(1.0, 0.35, 0.8, 0.06);
    frond(0.92, 0.52, 0.8, 0.22);
    frond(0.4, 0.0, 0.42, 0.06);
    frond(0.78, 0.0, 0.7, 0.04);
    circle(0.54, 0.24, 0.04);
  }

  void tree() {
    rect(0.45, 0.55, 0.55, 1);
    circle(0.5, 0.35, 0.3);
    circle(0.3, 0.48, 0.2);
    circle(0.7, 0.48, 0.2);
  }

  void camel(double cx) {
    oval(cx, 0.5, 0.26, 0.14);
    halfDome(cx, 0.42, 0.12, 0.14);
    line(cx + 0.22, 0.45, cx + 0.32, 0.2, 0.06);
    oval(cx + 0.36, 0.2, 0.07, 0.04);
    for (final dx in <double>[-0.18, -0.1, 0.1, 0.18]) {
      line(cx + dx, 0.55, cx + dx, 1.0, 0.04);
    }
  }

  void animalCart() {
    // âne + charrette
    oval(0.25, 0.52, 0.16, 0.1);
    line(0.38, 0.48, 0.44, 0.3, 0.06);
    oval(0.45, 0.28, 0.06, 0.04);
    line(0.42, 0.24, 0.4, 0.14, 0.02);
    line(0.45, 0.24, 0.46, 0.14, 0.02);
    for (final dx in <double>[0.14, 0.2, 0.3, 0.36]) {
      line(dx, 0.58, dx, 1.0, 0.03);
    }
    line(0.4, 0.52, 0.6, 0.6, 0.02);
    rect(0.58, 0.45, 0.98, 0.7);
    oval(0.78, 0.42, 0.18, 0.06);
    ring(0.78, 0.82, 0.12, 0.03);
  }

  void elephant() {
    oval(0.5, 0.5, 0.32, 0.24);
    circle(0.84, 0.36, 0.13);
    quadStroke(0.92, 0.42, 1.0, 0.7, 0.9, 0.9, 0.06);
    for (final dx in <double>[0.28, 0.4, 0.6, 0.72]) {
      rect(dx - 0.05, 0.6, dx + 0.05, 1.0);
    }
    poly([0.4, 0.28, 0.66, 0.28, 0.62, 0.12, 0.44, 0.12]);
  }

  void cafeTable() {
    halfDome(0.5, 0.25, 0.42, 0.2);
    rect(0.49, 0.25, 0.51, 0.62);
    oval(0.5, 0.62, 0.2, 0.03);
    rect(0.49, 0.62, 0.51, 1);
    rect(0.4, 0.97, 0.6, 1);
    // chaises bistrot
    for (final cx in <double>[0.15, 0.85]) {
      rect(cx - 0.07, 0.7, cx + 0.07, 0.74);
      line(cx - 0.06, 0.74, cx - 0.08, 1.0, 0.02);
      line(cx + 0.06, 0.74, cx + 0.08, 1.0, 0.02);
      final back = cx < 0.5 ? cx - 0.07 : cx + 0.07;
      line(back, 0.72, back, 0.5, 0.02);
    }
    rect(0.44, 0.56, 0.48, 0.61);
  }

  // ───────────────────────────── Ciel ─────────────────────────────

  void cloud() {
    oval(0.3, 0.65, 0.2, 0.2);
    oval(0.5, 0.5, 0.22, 0.3);
    oval(0.72, 0.62, 0.2, 0.22);
    rrect(0.1, 0.62, 0.92, 0.85, 0.1);
  }

  void birds() {
    void bird(double cx, double cy, double sz) {
      quadStroke(cx - sz, cy - sz * 0.3, cx - sz * 0.5, cy - sz * 0.8, cx, cy, 0.03);
      quadStroke(cx, cy, cx + sz * 0.5, cy - sz * 0.8, cx + sz, cy - sz * 0.3, 0.03);
    }

    bird(0.25, 0.45, 0.14);
    bird(0.55, 0.3, 0.1);
    bird(0.75, 0.6, 0.12);
  }

  void moon() {
    circle(0.5, 0.5, 0.42);
    circle(0.66, 0.4, 0.36, hole: true);
  }

  void sun() {
    circle(0.5, 0.5, 0.26);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      line(0.5 + math.cos(a) * 0.32, 0.5 + math.sin(a) * 0.32, 0.5 + math.cos(a) * 0.45,
          0.5 + math.sin(a) * 0.45, 0.04);
    }
  }
}
