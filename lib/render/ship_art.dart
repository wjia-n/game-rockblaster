import 'dart:math';
import 'dart:ui';
import '../engine/rock_engine.dart';

/// Vector art for ships and rocks. Toy-like, physical, chunky — drawn with
/// filled hulls, darker undersides and warm highlights so everything reads
/// as a tangible object, never a hologram.
class ShipArt {
  /// Draws the ship centered at the origin, pointing UP. [tick] drives the
  /// thrust flame flicker.
  static void paintShip(Canvas canvas, int style,
      {required Color hull,
      required Color accent,
      required bool thrust,
      required double tick}) {
    final hullPaint = Paint()..color = hull;
    final darkPaint = Paint()..color = _shade(hull, 0.62);
    final accentPaint = Paint()..color = accent;

    void flame(double y) {
      if (!thrust) return;
      final f = Path()
        ..moveTo(-5, y)
        ..lineTo(0, y + 12 + 7 * sin(tick * 42))
        ..lineTo(5, y)
        ..close();
      canvas.drawPath(f, accentPaint);
      final core = Path()
        ..moveTo(-2.5, y)
        ..lineTo(0, y + 7 + 4 * sin(tick * 55))
        ..lineTo(2.5, y)
        ..close();
      canvas.drawPath(core, Paint()..color = const Color(0xFFFFF3D6));
    }

    void porthole(double y, double r) {
      canvas.drawCircle(
          Offset(0, y), r + 1.5, Paint()..color = _shade(hull, 0.5));
      canvas.drawCircle(Offset(0, y), r, Paint()..color = accent);
      canvas.drawCircle(
          Offset(-r * 0.3, y - r * 0.3),
          r * 0.35,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85));
    }

    switch (style) {
      case 1: // Toy Rocket
        flame(13);
        final body = Path()
          ..moveTo(0, -16)
          ..quadraticBezierTo(8, -8, 7, 4)
          ..lineTo(7, 12)
          ..lineTo(-7, 12)
          ..lineTo(-7, 4)
          ..quadraticBezierTo(-8, -8, 0, -16)
          ..close();
        canvas.drawPath(body, hullPaint);
        final belly = Path()
          ..moveTo(0, -16)
          ..quadraticBezierTo(8, -8, 7, 4)
          ..lineTo(7, 12)
          ..lineTo(0, 12)
          ..close();
        canvas.drawPath(belly, Paint()..color = _shade(hull, 0.85));
        final finL = Path()
          ..moveTo(-7, 2)
          ..lineTo(-13, 13)
          ..lineTo(-7, 13)
          ..close();
        final finR = Path()
          ..moveTo(7, 2)
          ..lineTo(13, 13)
          ..lineTo(7, 13)
          ..close();
        canvas.drawPath(finL, darkPaint);
        canvas.drawPath(finR, darkPaint);
        porthole(-3, 4);
      case 2: // Saucer
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(0, 4), width: 30, height: 10),
            darkPaint);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(0, 2), width: 30, height: 10),
            hullPaint);
        canvas.drawArc(
            Rect.fromCenter(center: const Offset(0, -1), width: 16, height: 14),
            pi,
            pi,
            false,
            Paint()..color = accent);
        canvas.drawArc(
            Rect.fromCenter(center: const Offset(0, -1), width: 16, height: 14),
            pi,
            pi,
            true,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = _shade(hull, 0.6));
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(
              Offset(i * 9.0, 6), 1.8, Paint()..color = accent);
        }
        flame(9);
      case 3: // Dart
        flame(12);
        canvas.drawPath(
            Path()
              ..moveTo(0, -17)
              ..lineTo(5, 10)
              ..lineTo(0, 13)
              ..lineTo(-5, 10)
              ..close(),
            hullPaint);
        canvas.drawPath(
            Path()
              ..moveTo(0, -17)
              ..lineTo(5, 10)
              ..lineTo(0, 6)
              ..close(),
            Paint()..color = _shade(hull, 0.85));
        canvas.drawPath(
            Path()
              ..moveTo(-5, 4)
              ..lineTo(-11, 12)
              ..lineTo(-5, 11)
              ..close(),
            darkPaint);
        canvas.drawPath(
            Path()
              ..moveTo(5, 4)
              ..lineTo(11, 12)
              ..lineTo(5, 11)
              ..close(),
            darkPaint);
        canvas.drawCircle(Offset(0, -6), 2.2, accentPaint);
      case 4: // Shuttle
        flame(12);
        final hullP = Path()
          ..moveTo(0, -15)
          ..lineTo(6, -4)
          ..lineTo(6, 10)
          ..lineTo(-6, 10)
          ..lineTo(-6, -4)
          ..close();
        canvas.drawPath(hullP, hullPaint);
        canvas.drawPath(
            Path()
              ..moveTo(-6, 0)
              ..lineTo(-14, 11)
              ..lineTo(-6, 11)
              ..close(),
            darkPaint);
        canvas.drawPath(
            Path()
              ..moveTo(6, 0)
              ..lineTo(14, 11)
              ..lineTo(6, 11)
              ..close(),
            darkPaint);
        canvas.drawRect(
            const Rect.fromLTWH(-3.5, -12, 7, 8),
            Paint()..color = _shade(hull, 0.55));
        canvas.drawRect(
            const Rect.fromLTWH(-2.5, -11, 5, 6), accentPaint);
      case 5: // Cruiser
        flame(12);
        canvas.drawPath(
            Path()
              ..moveTo(0, -16)
              ..lineTo(12, 2)
              ..lineTo(8, 12)
              ..lineTo(3, 8)
              ..lineTo(-3, 8)
              ..lineTo(-8, 12)
              ..lineTo(-12, 2)
              ..close(),
            hullPaint);
        canvas.drawPath(
            Path()
              ..moveTo(0, -16)
              ..lineTo(12, 2)
              ..lineTo(4, 2)
              ..close(),
            Paint()..color = _shade(hull, 0.85));
        porthole(-4, 3.4);
      case 6: // Wedge
        flame(11);
        canvas.drawPath(
            Path()
              ..moveTo(0, -14)
              ..lineTo(13, 10)
              ..lineTo(-13, 10)
              ..close(),
            hullPaint);
        canvas.drawPath(
            Path()
              ..moveTo(0, -14)
              ..lineTo(13, 10)
              ..lineTo(0, 10)
              ..close(),
            Paint()..color = _shade(hull, 0.85));
        canvas.drawCircle(Offset(0, 2), 2.6, accentPaint);
      case 7: // Blade
        flame(12);
        canvas.drawPath(
            Path()
              ..moveTo(0, -18)
              ..quadraticBezierTo(4, -4, 3, 12)
              ..lineTo(-3, 12)
              ..quadraticBezierTo(-4, -4, 0, -18)
              ..close(),
            hullPaint);
        canvas.drawPath(
            Path()
              ..moveTo(0, -18)
              ..quadraticBezierTo(4, -4, 3, 12)
              ..lineTo(0, 12)
              ..close(),
            Paint()..color = _shade(hull, 0.85));
        canvas.drawCircle(Offset(0, -8), 2, accentPaint);
      case 8: // Ring Runner
        canvas.drawCircle(
            const Offset(0, 0),
            13,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = hullPaint.color);
        canvas.drawCircle(
            const Offset(0, 0),
            13,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = _shade(hull, 0.6));
        canvas.drawPath(
            Path()
              ..moveTo(0, -11)
              ..lineTo(7, 8)
              ..lineTo(0, 4)
              ..lineTo(-7, 8)
              ..close(),
            accentPaint);
        flame(11);
      default: // 0 Classic Arrow
        flame(11);
        canvas.drawPath(
            Path()
              ..moveTo(0, -15)
              ..lineTo(10, 12)
              ..lineTo(0, 6)
              ..lineTo(-10, 12)
              ..close(),
            hullPaint);
        canvas.drawPath(
            Path()
              ..moveTo(0, -15)
              ..lineTo(10, 12)
              ..lineTo(0, 12)
              ..close(),
            Paint()..color = _shade(hull, 0.85));
        canvas.drawCircle(Offset(0, -2), 2.4, accentPaint);
    }
  }

  /// Rock polygon path from the engine's vertex profile.
  static Path rockPath(RockBody r) {
    final path = Path();
    for (var i = 0; i < r.verts.length; i++) {
      final a = r.rot + i / r.verts.length * 2 * pi;
      final rr = r.r * r.verts[i];
      final pt = r.p + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  /// Chunky crater detail so rocks feel like carved stone.
  static void paintCraters(Canvas canvas, RockBody r, Color dark) {
    final n = (r.r / 14).clamp(1, 4).round();
    for (var i = 0; i < n; i++) {
      final a = r.rot * 1.7 + i * 2.4;
      final d = r.r * 0.38;
      final c = r.p + Offset(cos(a), sin(a)) * d;
      final cr = r.r * (0.10 + 0.05 * ((i * 37) % 10) / 10);
      canvas.drawCircle(c, cr, Paint()..color = dark);
      canvas.drawCircle(
          c + Offset(-cr * 0.25, -cr * 0.25),
          cr * 0.55,
          Paint()..color = dark.withValues(alpha: 0.55));
    }
  }

  static Color _shade(Color c, double f) {
    final r = (c.r * f).clamp(0.0, 1.0);
    final g = (c.g * f).clamp(0.0, 1.0);
    final b = (c.b * f).clamp(0.0, 1.0);
    return Color.from(alpha: c.a, red: r, green: g, blue: b);
  }
}
