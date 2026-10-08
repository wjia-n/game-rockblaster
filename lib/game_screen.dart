import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class _Rock {
  Offset p;
  Offset v;
  double r;
  List<double> verts;
  double rot, rotV;
  _Rock(this.p, this.v, this.r, this.verts, this.rot, this.rotV);
}

class _Bullet {
  Offset p;
  Offset v;
  double life;
  bool enemy;
  _Bullet(this.p, this.v, this.life, this.enemy);
}

class _Bit {
  Offset p;
  Offset v;
  double life;
  _Bit(this.p, this.v, this.life);
}

class _Ufo {
  Offset p;
  double dir;
  double fireT;
  _Ufo(this.p, this.dir, this.fireT);
}

class RockBlasterScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const RockBlasterScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<RockBlasterScreen> createState() => _RockBlasterScreenState();
}

class _RockBlasterScreenState extends State<RockBlasterScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;

  Offset _ship = Offset.zero;
  Offset _vel = Offset.zero;
  double _angle = -pi / 2;
  int _rotDir = 0;
  bool _thrust = false;
  double _fireCd = 0;
  double _invuln = 0;

  final List<_Rock> _rocks = [];
  final List<_Bullet> _bullets = [];
  final List<_Bit> _bits = [];
  _Ufo? _ufo;
  double _ufoT = 18;
  List<Offset> _stars = [];

  int _lives = 3, _score = 0, _best = 0, _wave = 0;
  bool _over = false;
  String _banner = '';
  double _bannerT = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = p.getInt('rockblaster_best') ?? 0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startWave() {
    _wave++;
    final n = min(3 + _wave, 9);
    for (var i = 0; i < n; i++) {
      _spawnRock(46, _edgePos());
    }
    _banner = 'WAVE $_wave';
    _bannerT = 1.6;
    _score += _wave * 100;
    Sfx.win();
  }

  Offset _edgePos() {
    final w = _size.width, h = _size.height;
    final side = _rng.nextInt(4);
    final m = 60.0;
    switch (side) {
      case 0:
        return Offset(_rng.nextDouble() * w, -m);
      case 1:
        return Offset(w + m, _rng.nextDouble() * h);
      case 2:
        return Offset(_rng.nextDouble() * w, h + m);
      default:
        return Offset(-m, _rng.nextDouble() * h);
    }
  }

  void _spawnRock(double r, Offset p) {
    final a = _rng.nextDouble() * 2 * pi;
    final sp = 30 + _rng.nextDouble() * (30 + _wave * 8);
    final verts =
        List.generate(9, (_) => 0.75 + _rng.nextDouble() * 0.45);
    _rocks.add(_Rock(
        p,
        Offset(cos(a), sin(a)) * sp,
        r,
        verts,
        _rng.nextDouble() * 2 * pi,
        (_rng.nextDouble() - 0.5) * 2));
  }

  double _wx(double x, double m) {
    final w = _size.width + m * 2;
    return (((x + m) % w) + w) % w - m;
  }

  double _wy(double y, double m) {
    final h = _size.height + m * 2;
    return (((y + m) % h) + h) % h - m;
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _over || _size == Size.zero) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      _last = elapsed;
      return; // paused — freeze the world
    }
    final dt = min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    _update(dt);
    setState(() {});
  }

  void _update(double dt) {
    // ship
    _angle += _rotDir * 3.6 * dt;
    if (_thrust) {
      _vel += Offset(cos(_angle), sin(_angle)) * 320 * dt;
      if (_rng.nextDouble() < 0.5) {
        _bits.add(_Bit(
            _ship - Offset(cos(_angle), sin(_angle)) * 12,
            -Offset(cos(_angle), sin(_angle)) * 120 +
                Offset((_rng.nextDouble() - 0.5) * 60,
                    (_rng.nextDouble() - 0.5) * 60),
            0.35));
      }
    }
    _vel *= (1 - 0.5 * dt);
    if (_vel.distance > 430) _vel = _vel / _vel.distance * 430;
    _ship = Offset(_wx(_ship.dx + _vel.dx * dt, 12),
        _wy(_ship.dy + _vel.dy * dt, 12));
    _fireCd -= dt;
    _tGlobal += dt;
    _invuln = max(0, _invuln - dt);
    _bannerT = max(0, _bannerT - dt);

    // bullets
    for (final b in _bullets) {
      b.p += b.v * dt;
      b.life -= dt;
    }
    _bullets.removeWhere(
        (b) => b.life <= 0 || b.p.dx < -20 || b.p.dx > _size.width + 20 || b.p.dy < -20 || b.p.dy > _size.height + 20);

    // rocks
    for (final r in _rocks) {
      r.p = Offset(_wx(r.p.dx + r.v.dx * dt, r.r),
          _wy(r.p.dy + r.v.dy * dt, r.r));
      r.rot += r.rotV * dt;
    }

    // ufo
    _ufoT -= dt;
    if (_ufoT <= 0 && _ufo == null) {
      final y = _size.height * (0.2 + _rng.nextDouble() * 0.6);
      final dir = _rng.nextBool() ? 1.0 : -1.0;
      _ufo = _Ufo(
          Offset(dir > 0 ? -40 : _size.width + 40, y), dir, 1.0);
      _ufoT = 20 + _rng.nextDouble() * 12;
    }
    final ufo = _ufo;
    if (ufo != null) {
      ufo.p += Offset(ufo.dir * 110 * dt, sin(_tGlobal * 3) * 30 * dt);
      ufo.fireT -= dt;
      if (ufo.fireT <= 0) {
        ufo.fireT = 1.4;
        final aim = (_ship - ufo.p);
        final d = aim.distance;
        if (d > 1) {
          _bullets.add(_Bullet(
              ufo.p, aim / d * 300, 2.0, true));
          Sfx.tap();
        }
      }
      if (ufo.p.dx < -60 || ufo.p.dx > _size.width + 60) _ufo = null;
    }

    // bits
    for (final b in _bits) {
      b.p += b.v * dt;
      b.life -= dt;
    }
    _bits.removeWhere((b) => b.life <= 0);

    _collisions();

    if (_rocks.isEmpty && !_over) _startWave();
  }

  double _tGlobal = 0;

  void _collisions() {
    // bullets vs rocks / ufo
    final deadBullets = <_Bullet>[];
    final deadRocks = <_Rock>[];
    for (final b in _bullets) {
      if (b.enemy) continue;
      for (final r in _rocks) {
        if ((b.p - r.p).distance < r.r + 4) {
          deadBullets.add(b);
          deadRocks.add(r);
          _smashRock(r);
          break;
        }
      }
      final ufo = _ufo;
      if (ufo != null && (b.p - ufo.p).distance < 26) {
        deadBullets.add(b);
        _ufo = null;
        _score += 200;
        _burst(ufo.p, 16);
        Sfx.win();
      }
    }
    _bullets.removeWhere(deadBullets.contains);
    _rocks.removeWhere(deadRocks.contains);

    // enemy bullets vs ship
    for (final b in _bullets.where((b) => b.enemy)) {
      if ((b.p - _ship).distance < 12) {
        _bullets.remove(b);
        _die();
        break;
      }
    }
    if (_over) return;

    // rocks vs ship
    for (final r in List<_Rock>.from(_rocks)) {
      if ((r.p - _ship).distance < r.r + 9) {
        _rocks.remove(r);
        _burst(r.p, 8);
        _die();
        break;
      }
    }
    if (_over) return;
    final ufo = _ufo;
    if (ufo != null && (ufo.p - _ship).distance < 30) {
      _ufo = null;
      _burst(ufo.p, 16);
      _die();
    }
  }

  void _smashRock(_Rock r) {
    _score += r.r > 40 ? 20 : (r.r > 20 ? 50 : 100);
    _burst(r.p, 10);
    Sfx.move();
    if (r.r > 20) {
      for (var i = 0; i < 2; i++) {
        final a = _rng.nextDouble() * 2 * pi;
        final nr = _Rock(
            r.p,
            Offset(cos(a), sin(a)) * (60 + _rng.nextDouble() * 60),
            r.r * 0.55,
            List.generate(9, (_) => 0.75 + _rng.nextDouble() * 0.45),
            _rng.nextDouble() * 2 * pi,
            (_rng.nextDouble() - 0.5) * 3);
        _rocks.add(nr);
      }
    }
  }

  void _burst(Offset p, int n) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final sp = 60 + _rng.nextDouble() * 180;
      _bits.add(_Bit(p, Offset(cos(a), sin(a)) * sp, 0.5 + _rng.nextDouble() * 0.4));
    }
  }

  void _fire() {
    if (_over || _fireCd > 0) return;
    _fireCd = 0.18;
    final nose = _ship + Offset(cos(_angle), sin(_angle)) * 14;
    _bullets.add(_Bullet(
        nose, Offset(cos(_angle), sin(_angle)) * 560 + _vel * 0.4, 0.9, false));
    Sfx.tap();
  }

  void _hyperspace() {
    if (_over) return;
    Sfx.click();
    _ship = Offset(_rng.nextDouble() * _size.width,
        _rng.nextDouble() * _size.height);
    _vel = Offset.zero;
    _invuln = 1.0;
    _burst(_ship, 12);
    if (_rng.nextDouble() < 0.15) {
      _invuln = 0;
      _die();
    }
  }

  void _die() {
    if (_invuln > 0 || _over) return;
    _burst(_ship, 22);
    Sfx.lose();
    _lives--;
    if (_lives <= 0) {
      _gameOver();
    } else {
      _ship = Offset(_size.width / 2, _size.height / 2);
      _vel = Offset.zero;
      _invuln = 2.5;
    }
  }

  Future<void> _gameOver() async {
    _over = true;
    _ticker.stop();
    final isBest = _score > _best;
    if (isBest) {
      _best = _score;
      final p = await SharedPreferences.getInstance();
      await p.setInt('rockblaster_best', _best);
    }
    widget.players.first.score = _score;
    widget.callbacks.refreshHud();
    widget.callbacks.finish(
      headline: 'You scored $_score!',
      subline: isBest ? '☄️ New best!' : 'Best: $_best',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Column(
      children: [
        _hud(t),
        Expanded(
          child: LayoutBuilder(builder: (ctx, c) {
            final ns = Size(c.maxWidth, c.maxHeight);
            if (_size == Size.zero && ns.width > 0) {
              _size = ns;
              _ship = Offset(ns.width / 2, ns.height / 2);
              _stars = List.generate(
                  70,
                  (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
              _startWave();
            }
            return Container(
              decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(16)),
              child: CustomPaint(
                painter: _SpacePainter(
                  ship: _ship,
                  angle: _angle,
                  thrust: _thrust,
                  invuln: _invuln,
                  rocks: _rocks,
                  bullets: _bullets,
                  bits: _bits,
                  ufo: _ufo,
                  stars: _stars,
                  banner: _bannerT > 0 ? _banner : '',
                  shipColor: t.primary,
                  rockColor: t.text,
                  accent: t.accent,
                  tick: _tGlobal,
                ),
                child: const SizedBox.expand(),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        _controls(t),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _hud(GameTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text('SCORE $_score  •  BEST $_best',
                  style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15))),
          Text('🚀' * _lives,
              style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _hyperspace,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('🌀', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _holdBtn(String label, void Function(bool) onHold, GameTheme t,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTapDown: (_) => onHold(true),
      onTapUp: (_) => onHold(false),
      onTapCancel: () => onHold(false),
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.primary.withValues(alpha: 0.4)),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(fontSize: 24, color: t.text))),
      ),
    );
  }

  Widget _controls(GameTheme t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          _holdBtn('◀', (h) => _rotDir = h ? -1 : (_rotDir == -1 ? 0 : _rotDir), t),
          const SizedBox(width: 10),
          _holdBtn('▶', (h) => _rotDir = h ? 1 : (_rotDir == 1 ? 0 : _rotDir), t),
        ]),
        Row(children: [
          _holdBtn('▲', (h) => _thrust = h, t),
          const SizedBox(width: 10),
          _holdBtn('🔥', (_) {}, t, onTap: _fire),
        ]),
      ],
    );
  }
}

class _SpacePainter extends CustomPainter {
  final Offset ship;
  final double angle;
  final bool thrust;
  final double invuln;
  final List<_Rock> rocks;
  final List<_Bullet> bullets;
  final List<_Bit> bits;
  final _Ufo? ufo;
  final List<Offset> stars;
  final String banner;
  final Color shipColor, rockColor, accent;
  final double tick;

  _SpacePainter({
    required this.ship,
    required this.angle,
    required this.thrust,
    required this.invuln,
    required this.rocks,
    required this.bullets,
    required this.bits,
    required this.ufo,
    required this.stars,
    required this.banner,
    required this.shipColor,
    required this.rockColor,
    required this.accent,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // stars
    final sp = Paint()..color = rockColor.withValues(alpha: 0.35);
    for (final s in stars) {
      final tw = 0.5 + 0.5 * sin(tick * 2 + s.dx * 40);
      canvas.drawCircle(
          Offset(s.dx * size.width, s.dy * size.height),
          1 + tw,
          sp..color = rockColor.withValues(alpha: 0.2 + 0.25 * tw));
    }
    // rocks
    for (final r in rocks) {
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
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = rockColor.withValues(alpha: 0.85));
    }
    // ufo
    final u = ufo;
    if (u != null) {
      canvas.drawOval(
          Rect.fromCenter(center: u.p, width: 44, height: 14),
          Paint()..color = accent);
      canvas.drawArc(
          Rect.fromCenter(center: u.p + const Offset(0, -4), width: 24, height: 18),
          pi,
          pi,
          false,
          Paint()..color = accent.withValues(alpha: 0.7));
    }
    // bullets
    for (final b in bullets) {
      canvas.drawCircle(
          b.p, 3.5, Paint()..color = b.enemy ? Colors.redAccent : accent);
    }
    // bits
    for (final b in bits) {
      canvas.drawCircle(
          b.p,
          3 * (b.life.clamp(0, 1)),
          Paint()..color = accent.withValues(alpha: b.life.clamp(0, 1)));
    }
    // ship (blink while invulnerable)
    if (invuln <= 0 || (tick * 8).floor() % 2 == 0) {
      canvas.save();
      canvas.translate(ship.dx, ship.dy);
      canvas.rotate(angle + pi / 2);
      final path = Path()
        ..moveTo(0, -14)
        ..lineTo(10, 12)
        ..lineTo(0, 6)
        ..lineTo(-10, 12)
        ..close();
      canvas.drawPath(
          path, Paint()..color = shipColor);
      if (thrust) {
        final flame = Path()
          ..moveTo(-5, 10)
          ..lineTo(0, 20 + 6 * sin(tick * 40))
          ..lineTo(5, 10)
          ..close();
        canvas.drawPath(flame, Paint()..color = accent);
      }
      canvas.restore();
    }
    // banner
    if (banner.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
            text: banner,
            style: TextStyle(
                color: rockColor,
                fontSize: 34,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset((size.width - tp.width) / 2,
              size.height * 0.35));
    }
  }

  @override
  bool shouldRepaint(covariant _SpacePainter old) => true;
}
