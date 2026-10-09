import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/rock_engine.dart';
import '../render/ship_art.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rock_themes.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.rockblaster';

/// Active gameplay: HUD + canvas + touch controls. The engine owns all
/// state; this screen renders it and forwards input. A 1-second watchdog
/// timer calls engine.watchdog() so no phase can ever get stuck.
class GameScreen extends StatefulWidget {
  final BlastSettings settings;
  final SpaceAudio audio;
  const GameScreen({super.key, required this.settings, required this.audio});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final RockEngine _engine;
  late final Ticker _ticker;
  Timer? _watchdog;
  Duration _last = Duration.zero;
  bool _sized = false;
  bool _firing = false;
  bool _recorded = false;
  bool _newBest = false;

  RockThemeDef get _theme => RockThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = RockEngine();
    _engine.onEvent = _onEngineEvent;
    _engine.onPhase = _onEnginePhase;
    _ticker = createTicker(_onTick)..start();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      _engine.watchdog();
      if (mounted) setState(() {});
    });
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _watchdog?.cancel();
    widget.audio.stopThrust();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine.setPaused(true);
      widget.audio.onAppPaused();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _onEngineEvent(BlastEvent e) {
    final a = widget.audio;
    switch (e) {
      case BlastEvent.shoot:
        a.shoot();
      case BlastEvent.boom:
        a.boom();
      case BlastEvent.bigBoom:
        a.bigBoom();
      case BlastEvent.ufoWarn:
        a.ufoWarn();
      case BlastEvent.playerHit:
        a.bigBoom();
      case BlastEvent.waveStart:
        a.gameStart();
      case BlastEvent.waveClear:
        a.waveClear();
      case BlastEvent.hyperspace:
        a.hyperspace();
      case BlastEvent.invalid:
        a.invalid();
    }
  }

  void _onEnginePhase(BlastPhase p) {
    if (p == BlastPhase.gameOver) {
      widget.audio.stopThrust();
      widget.audio.gameOver();
      _recordRun();
    }
    if (mounted) setState(() {});
  }

  Future<void> _recordRun() async {
    if (_recorded) return;
    _recorded = true;
    _newBest = await widget.settings.recordGame(
      score: _engine.score,
      mode: _engine.mode,
      rocks: _engine.rocksSmashed,
      waves: _engine.wave,
    );
    if (_newBest) widget.audio.newBest();
    if (mounted) setState(() {});
    // Sensible review moment: new best, or every 4th finished run.
    try {
      if (_newBest || widget.settings.gamesPlayed % 4 == 0) {
        if (await InAppReview.instance.isAvailable()) {
          await InAppReview.instance.requestReview();
        }
      }
    } catch (_) {}
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_sized) {
      _last = elapsed;
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      _last = elapsed;
      return; // covered by a dialog — freeze the world
    }
    final dt = min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    if (_firing) _engine.fire();
    _engine.advance(dt);
    if (_engine.thrusting) {
      widget.audio.startThrust();
    } else {
      widget.audio.stopThrust();
    }
    setState(() {});
  }

  /// Kicks off the run AFTER the first frame — engine.start() fires
  /// onPhase → setState, which is illegal during the build pass itself.
  void _startRun() {
    _engine.rockStyle = widget.settings.rockStyle;
    _engine.start(
      mode: widget.settings.mode,
      difficulty: widget.settings.difficulty,
    );
  }

  void _shareScore() {
    widget.audio.click();
    SharePlus.instance.share(
      ShareParams(
        text:
            'I scored ${_engine.score} in Rock Blaster! 🚀 Can you beat me?\n$_storeUrl',
        subject: 'Rock Blaster',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            _hud(t),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LayoutBuilder(builder: (ctx, c) {
                  final ns = Size(c.maxWidth, c.maxHeight);
                  if (!_sized && ns.width > 0 && ns.height > 0) {
                    _sized = true;
                    _engine.setSize(ns);
                    // Start after this frame — never inside the build pass.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _startRun();
                    });
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: _SpacePainter(
                            engine: _engine,
                            theme: t,
                            shipStyle: widget.settings.shipStyle,
                          ),
                          child: const SizedBox.expand(),
                        ),
                        if (_engine.phase == BlastPhase.paused)
                          _pauseOverlay(t),
                        if (_engine.phase == BlastPhase.gameOver)
                          _gameOverOverlay(t),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            _controls(t),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _hud(RockThemeDef t) {
    final e = _engine;
    final best =
        e.mode == 1 ? widget.settings.bestAttack : widget.settings.bestScore;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCORE ${e.score}',
                    style: TextStyle(
                        color: t.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 17)),
                Text(
                    e.mode == 1
                        ? '⏱ ${_engine.timeLeft.ceil()}s   •   BEST $best'
                        : 'BEST $best   •   WAVE ${e.wave}',
                    style: TextStyle(
                        color: t.text.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
          if (e.mode == 0)
            Text('🚀' * e.lives.clamp(0, 5),
                style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          _iconBtn('🌀', () {
            if (e.phase == BlastPhase.playing) {
              e.hyperspace();
            } else {
              widget.audio.invalid();
            }
          }, t),
          const SizedBox(width: 8),
          _iconBtn('⏸', () {
            widget.audio.click();
            e.setPaused(true);
            widget.audio.stopThrust();
            setState(() {});
          }, t),
        ],
      ),
    );
  }

  Widget _iconBtn(String label, VoidCallback onTap, RockThemeDef t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.accent.withValues(alpha: 0.45)),
        ),
        child: Center(
            child:
                Text(label, style: TextStyle(fontSize: 20, color: t.text))),
      ),
    );
  }

  Widget _holdBtn(
      String label, void Function(bool) onHold, RockThemeDef t) {
    return GestureDetector(
      onTapDown: (_) => onHold(true),
      onTapUp: (_) => onHold(false),
      onTapCancel: () => onHold(false),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.accent.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(fontSize: 26, color: t.text))),
      ),
    );
  }

  Widget _fireBtn(RockThemeDef t) {
    return GestureDetector(
      onTapDown: (_) {
        _firing = true;
        _engine.fire();
      },
      onTapUp: (_) => _firing = false,
      onTapCancel: () => _firing = false,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: t.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: t.accent.withValues(alpha: 0.45),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Center(
            child: Text('🔥', style: TextStyle(fontSize: 34))),
      ),
    );
  }

  Widget _controls(RockThemeDef t) {
    final e = _engine;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _holdBtn('◀',
                (h) => e.rotDir = h ? -1 : (e.rotDir == -1 ? 0 : e.rotDir), t),
            const SizedBox(width: 12),
            _holdBtn('▶',
                (h) => e.rotDir = h ? 1 : (e.rotDir == 1 ? 0 : e.rotDir), t),
          ]),
          _fireBtn(t),
          Row(children: [
            _holdBtn('▲', (h) => e.thrust = h, t),
          ]),
        ],
      ),
    );
  }

  Widget _pauseOverlay(RockThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Score ${_engine.score}  •  Wave ${_engine.wave}',
                  style: TextStyle(
                      color: t.text.withValues(alpha: 0.7), fontSize: 14)),
              const SizedBox(height: 18),
              _menuBtn('▶  Resume', () {
                widget.audio.click();
                _engine.setPaused(false);
              }, t, primary: true),
              const SizedBox(height: 10),
              _menuBtn('↻  Restart', () {
                widget.audio.click();
                _recorded = false;
                _newBest = false;
                _startRun();
              }, t),
              const SizedBox(height: 10),
              _menuBtn('🏠  Menu', () {
                widget.audio.click();
                Navigator.of(context).pop();
              }, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay(RockThemeDef t) {
    final e = _engine;
    final best =
        e.mode == 1 ? widget.settings.bestAttack : widget.settings.bestScore;
    return Container(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_newBest ? '🏆 NEW BEST!' : 'GAME OVER',
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${e.score}',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 46,
                      fontWeight: FontWeight.w900)),
              Text(
                  '${widget.settings.playerName}  •  Wave ${e.wave}  •  ${e.rocksSmashed} rocks smashed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.text.withValues(alpha: 0.7), fontSize: 13)),
              const SizedBox(height: 4),
              Text('Best: $best',
                  style: TextStyle(
                      color: t.text.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              _menuBtn('↻  Play Again', () {
                widget.audio.click();
                _recorded = false;
                _newBest = false;
                _startRun();
                widget.audio.startGameMusic();
              }, t, primary: true),
              const SizedBox(height: 10),
              _menuBtn('📤  Share Score', _shareScore, t),
              const SizedBox(height: 10),
              _menuBtn('🏠  Menu', () {
                widget.audio.click();
                Navigator.of(context).pop();
              }, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuBtn(String label, VoidCallback onTap, RockThemeDef t,
      {bool primary = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? t.accent : t.button,
          foregroundColor: primary ? const Color(0xFF1A1008) : t.text,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  final RockEngine engine;
  final RockThemeDef theme;
  final int shipStyle;

  _SpacePainter(
      {required this.engine, required this.theme, required this.shipStyle});

  static const _enemyRed = Color(0xFFB6452F);

  @override
  void paint(Canvas canvas, Size size) {
    final e = engine;
    canvas.save();
    // Screen shake.
    if (e.shake > 0.01) {
      canvas.translate(
        e.shake * 10 * sin(e.tGlobal * 97),
        e.shake * 10 * cos(e.tGlobal * 113),
      );
    }

    // Starfield.
    for (var i = 0; i < e.stars.length; i++) {
      final s = e.stars[i];
      final tw = 0.5 + 0.5 * sin(e.tGlobal * 2 + e.starSeed[i]);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        0.8 + tw * 1.3,
        Paint()..color = theme.star.withValues(alpha: 0.22 + 0.3 * tw),
      );
    }

    // Rocks: filled stone + darker crater detail + carved outline.
    for (final r in e.rocks) {
      final path = ShipArt.rockPath(r);
      canvas.drawPath(path, Paint()..color = theme.rockDark);
      ShipArt.paintCraters(canvas, r, _shade(theme.rockDark, 0.7));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = theme.rock);
    }

    // UFO saucer.
    final u = e.ufo;
    if (u != null) {
      canvas.drawOval(
          Rect.fromCenter(center: u.p + const Offset(0, 3), width: 46, height: 14),
          Paint()..color = _shade(_enemyRed, 0.55));
      canvas.drawOval(
          Rect.fromCenter(center: u.p, width: 46, height: 14),
          Paint()..color = _enemyRed);
      canvas.drawArc(
          Rect.fromCenter(center: u.p + const Offset(0, -4), width: 26, height: 20),
          pi,
          pi,
          false,
          Paint()..color = theme.accent.withValues(alpha: 0.85));
    }

    // Bullets.
    for (final b in e.bullets) {
      canvas.drawCircle(
          b.p, 3.6, Paint()..color = b.enemy ? _enemyRed : theme.accent);
      if (!b.enemy) {
        canvas.drawCircle(
            b.p,
            6.5,
            Paint()
              ..color = theme.accent.withValues(alpha: 0.3));
      }
    }

    // Sparks.
    for (final p in e.particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
          p.p, p.size * a, Paint()..color = theme.accent.withValues(alpha: a));
    }

    // Ship (blink while invulnerable).
    final showShip = e.phase == BlastPhase.playing ||
        e.phase == BlastPhase.waveBreak ||
        e.phase == BlastPhase.ready;
    if (showShip && (e.invuln <= 0 || (e.tGlobal * 8).floor() % 2 == 0)) {
      canvas.save();
      canvas.translate(e.ship.dx, e.ship.dy);
      canvas.rotate(e.angle + pi / 2);
      ShipArt.paintShip(canvas, shipStyle,
          hull: theme.ship,
          accent: theme.accent,
          thrust: e.thrusting,
          tick: e.tGlobal);
      canvas.restore();
      // Muzzle flash.
      if (e.muzzleT > 0) {
        final nose =
            e.ship + Offset(cos(e.angle), sin(e.angle)) * 18;
        canvas.drawCircle(
            nose, 7, Paint()..color = theme.accent.withValues(alpha: 0.9));
        canvas.drawCircle(
            nose, 3.4, Paint()..color = const Color(0xFFFFF3D6));
      }
    }

    // Score popups.
    for (final p in e.popups) {
      final a = (p.life).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
            text: p.text,
            style: TextStyle(
                color: theme.accent.withValues(alpha: a),
                fontSize: 17,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p.p + Offset(-tp.width / 2, -tp.height / 2));
    }

    // Banner.
    if (e.bannerT > 0 && e.banner.isNotEmpty) {
      final a = (e.bannerT / 1.6).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
            text: e.banner,
            style: TextStyle(
                color: theme.text.withValues(alpha: a),
                fontSize: 34,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 3),
                      blurRadius: 6)
                ])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset((size.width - tp.width) / 2,
              size.height * 0.34 - tp.height / 2));
    }

    // Score-attack low-time warning.
    if (e.mode == 1 &&
        e.phase == BlastPhase.playing &&
        e.timeLeft < 10 &&
        e.timeLeft > 0) {
      final tp = TextPainter(
        text: TextSpan(
            text: '${e.timeLeft.ceil()}',
            style: TextStyle(
                color: _enemyRed,
                fontSize: 30,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, 14));
    }

    canvas.restore();
  }

  Color _shade(Color c, double f) {
    return Color.from(
        alpha: c.a,
        red: (c.r * f).clamp(0.0, 1.0),
        green: (c.g * f).clamp(0.0, 1.0),
        blue: (c.b * f).clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(covariant _SpacePainter old) => true;
}
