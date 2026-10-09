import 'dart:math';
import 'dart:ui';

/// Rock Blaster engine: owns ALL game state and phase transitions.
///
/// Phases: ready -> playing <-> waveBreak -> playing ... -> gameOver,
/// with respawning as a timed sub-phase and paused as a freeze frame.
/// Every timed phase carries its own deadline; [watchdog] re-verifies all
/// invariants once a second so a stuck state is impossible by construction:
/// any phase found without a live deadline, or a playing phase with no
/// rocks and no pending transition, is forced forward.
enum BlastPhase { ready, playing, waveBreak, respawning, paused, gameOver }

/// One-shot events the UI turns into sound/juice. The engine never plays
/// audio itself — it just reports what happened.
enum BlastEvent {
  shoot,
  boom,
  bigBoom,
  ufoWarn,
  playerHit,
  waveStart,
  waveClear,
  hyperspace,
  invalid,
}

class RockBody {
  Offset p;
  Offset v;
  double r;
  List<double> verts;
  double rot, rotV;
  RockBody(this.p, this.v, this.r, this.verts, this.rot, this.rotV);
}

class BulletShot {
  Offset p;
  Offset v;
  double life;
  bool enemy;
  BulletShot(this.p, this.v, this.life, this.enemy);
}

class Spark {
  Offset p;
  Offset v;
  double life;
  double maxLife;
  double size;
  Spark(this.p, this.v, this.life, this.maxLife, this.size);
}

class ScorePopup {
  Offset p;
  String text;
  double life;
  ScorePopup(this.p, this.text, this.life);
}

class UfoShip {
  Offset p;
  double dir;
  double fireT;
  UfoShip(this.p, this.dir, this.fireT);
}

class RockEngine {
  final Random rng;
  void Function(BlastEvent e)? onEvent;
  void Function(BlastPhase p)? onPhase;

  BlastPhase phase = BlastPhase.ready;
  BlastPhase _pausedFrom = BlastPhase.playing;

  int mode = 0; // 0 endless, 1 score attack
  int difficulty = 0; // 0 cadet, 1 pilot, 2 ace

  // Ship state
  Offset ship = Offset.zero;
  Offset vel = Offset.zero;
  double angle = -pi / 2;
  double invuln = 0;
  int rotDir = 0;
  bool thrust = false;
  bool get thrusting => thrust && phase == BlastPhase.playing;

  // World state
  Size size = Size.zero;
  final List<RockBody> rocks = [];
  final List<BulletShot> bullets = [];
  final List<Spark> particles = [];
  final List<ScorePopup> popups = [];
  final List<Offset> stars = [];
  final List<double> starSeed = [];
  UfoShip? ufo;

  int score = 0;
  int wave = 0;
  int lives = 3;
  int rocksSmashed = 0;
  double timeLeft = 120;
  double tGlobal = 0;
  double shake = 0;
  double muzzleT = 0;
  double bannerT = 0;
  String banner = '';

  double _deadline = 0; // seconds left in the current timed phase
  double _fireCd = 0;
  double _ufoT = 20;

  RockEngine({Random? rng}) : rng = rng ?? Random();

  // ------------------------------------------------------------ lifecycle
  void start({required int mode, required int difficulty}) {
    this.mode = mode;
    this.difficulty = difficulty;
    score = 0;
    wave = 0;
    lives = 3;
    rocksSmashed = 0;
    timeLeft = 120;
    shake = 0;
    muzzleT = 0;
    rocks.clear();
    bullets.clear();
    particles.clear();
    popups.clear();
    ufo = null;
    ship = Offset(size.width / 2, size.height / 2);
    vel = Offset.zero;
    angle = -pi / 2;
    invuln = 1.0;
    rotDir = 0;
    thrust = false;
    _ufoT = 16 + rng.nextDouble() * 10;
    _setPhase(BlastPhase.ready, deadline: 1.4);
    banner = 'GET READY';
    bannerT = 1.4;
  }

  void setSize(Size s) {
    if (s == size) return;
    size = s;
    stars.clear();
    starSeed.clear();
    for (var i = 0; i < 90; i++) {
      stars.add(Offset(rng.nextDouble(), rng.nextDouble()));
      starSeed.add(rng.nextDouble() * 40);
    }
    if (ship == Offset.zero && s.width > 0) {
      ship = Offset(s.width / 2, s.height / 2);
    }
  }

  void setPaused(bool p) {
    if (p && phase != BlastPhase.paused && phase != BlastPhase.gameOver) {
      _pausedFrom = phase;
      _setPhase(BlastPhase.paused);
    } else if (!p && phase == BlastPhase.paused) {
      _setPhase(_pausedFrom);
    }
  }

  void _setPhase(BlastPhase p, {double deadline = 0}) {
    phase = p;
    _deadline = deadline;
    onPhase?.call(p);
  }

  /// Watchdog: re-verify engine invariants. Runs on a wall-clock timer so
  /// even a stalled UI ticker cannot leave the game stuck.
  void watchdog() {
    if (phase == BlastPhase.paused || phase == BlastPhase.gameOver) return;
    switch (phase) {
      case BlastPhase.ready:
        if (_deadline <= 0) {
          _beginWave();
          _setPhase(BlastPhase.playing);
        }
      case BlastPhase.waveBreak:
        if (_deadline <= 0) {
          _beginWave();
          _setPhase(BlastPhase.playing);
        }
      case BlastPhase.respawning:
        if (_deadline <= 0) _respawnShip();
      case BlastPhase.playing:
        // Rocks gone but no transition pending — force the wave break.
        if (rocks.isEmpty) _enterWaveBreak();
        if (mode == 1 && timeLeft <= 0) _gameOver();
      case BlastPhase.paused:
      case BlastPhase.gameOver:
        break;
    }
  }

  // ---------------------------------------------------------------- update
  void advance(double dt) {
    if (phase == BlastPhase.paused || phase == BlastPhase.gameOver) return;
    if (size == Size.zero) return;
    dt = dt.clamp(0.0, 0.05);
    tGlobal += dt;
    shake = max(0.0, shake - dt * 2.2);
    muzzleT = max(0.0, muzzleT - dt);
    bannerT = max(0.0, bannerT - dt);
    invuln = max(0.0, invuln - dt);
    _updateParticles(dt);
    _updatePopups(dt);

    switch (phase) {
      case BlastPhase.ready:
        _deadline -= dt;
        if (_deadline <= 0) {
          _beginWave();
          _setPhase(BlastPhase.playing);
        }
      case BlastPhase.waveBreak:
        _deadline -= dt;
        _driftRocks(dt);
        if (_deadline <= 0) {
          _beginWave();
          _setPhase(BlastPhase.playing);
        }
      case BlastPhase.respawning:
        _deadline -= dt;
        _driftRocks(dt);
        _updateUfo(dt, canFire: false);
        if (_deadline <= 0) _respawnShip();
      case BlastPhase.playing:
        _updatePlaying(dt);
      case BlastPhase.paused:
      case BlastPhase.gameOver:
        break;
    }
  }

  void _updatePlaying(double dt) {
    // Score-attack clock.
    if (mode == 1) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        _gameOver();
        return;
      }
    }

    // --- ship ---
    angle += rotDir * 3.6 * dt;
    if (thrust) {
      vel = vel + Offset(cos(angle), sin(angle)) * 340 * dt;
      if (rng.nextDouble() < 0.6) {
        final back = Offset(cos(angle), sin(angle)) * -14;
        particles.add(Spark(
          ship + back,
          Offset(cos(angle), sin(angle)) * -140 +
              Offset((rng.nextDouble() - 0.5) * 70,
                  (rng.nextDouble() - 0.5) * 70),
          0.35,
          0.35,
          3.5,
        ));
      }
    }
    vel = vel * (1 - 0.55 * dt);
    if (vel.distance > 440) vel = vel / vel.distance * 440;
    ship = Offset(_wx(ship.dx + vel.dx * dt, 12), _wy(ship.dy + vel.dy * dt, 12));
    _fireCd -= dt;

    // --- rocks drift ---
    _driftRocks(dt);

    // --- bullets ---
    for (final b in bullets) {
      b.p = b.p + b.v * dt;
      b.life -= dt;
    }
    bullets.removeWhere((b) =>
        b.life <= 0 ||
        b.p.dx < -24 ||
        b.p.dx > size.width + 24 ||
        b.p.dy < -24 ||
        b.p.dy > size.height + 24);

    // --- ufo ---
    _updateUfo(dt, canFire: true);

    _collisions();

    // Wave cleared? (collisions may have emptied the field)
    if (phase == BlastPhase.playing && rocks.isEmpty) _enterWaveBreak();
  }

  void _driftRocks(double dt) {
    for (final r in rocks) {
      r.p = Offset(_wx(r.p.dx + r.v.dx * dt, r.r), _wy(r.p.dy + r.v.dy * dt, r.r));
      r.rot += r.rotV * dt;
    }
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.p = p.p + p.v * dt;
      p.v = p.v * (1 - 2.2 * dt);
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  void _updatePopups(double dt) {
    for (final p in popups) {
      p.p = p.p + const Offset(0, -34) * dt;
      p.life -= dt;
    }
    popups.removeWhere((p) => p.life <= 0);
  }

  void _updateUfo(double dt, {required bool canFire}) {
    _ufoT -= dt;
    if (_ufoT <= 0 && ufo == null) {
      final y = size.height * (0.2 + rng.nextDouble() * 0.6);
      final dir = rng.nextBool() ? 1.0 : -1.0;
      ufo = UfoShip(Offset(dir > 0 ? -40 : size.width + 40, y), dir, 1.2);
      _ufoT = _ufoInterval() + rng.nextDouble() * 8;
      onEvent?.call(BlastEvent.ufoWarn);
    }
    final u = ufo;
    if (u != null) {
      u.p = u.p + Offset(u.dir * 115 * dt, sin(tGlobal * 3) * 34 * dt);
      if (canFire) {
        u.fireT -= dt;
        if (u.fireT <= 0) {
          u.fireT = 1.5;
          final aim = ship - u.p;
          final d = aim.distance;
          if (d > 1) {
            final err = (rng.nextDouble() - 0.5) * 2 * _ufoError();
            final a = atan2(aim.dy, aim.dx) + err;
            bullets.add(BulletShot(u.p, Offset(cos(a), sin(a)) * _ufoBulletSpeed(), 2.2, true));
          }
        }
      }
      if (u.p.dx < -70 || u.p.dx > size.width + 70) ufo = null;
    }
  }

  // -------------------------------------------------------------- actions
  void fire() {
    if (phase != BlastPhase.playing || _fireCd > 0) return;
    _fireCd = 0.17;
    muzzleT = 0.07;
    final nose = ship + Offset(cos(angle), sin(angle)) * 16;
    bullets.add(BulletShot(
        nose, Offset(cos(angle), sin(angle)) * 580 + vel * 0.35, 0.9, false));
    onEvent?.call(BlastEvent.shoot);
  }

  void hyperspace() {
    if (phase != BlastPhase.playing) return;
    ship = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
    vel = Offset.zero;
    invuln = 1.0;
    _burst(ship, 12, spread: 200);
    onEvent?.call(BlastEvent.hyperspace);
    if (rng.nextDouble() < 0.15) {
      invuln = 0;
      _die(); // the void sometimes bites back
    }
  }

  // ------------------------------------------------------------ collisions
  void _collisions() {
    final deadBullets = <BulletShot>[];
    final deadRocks = <RockBody>[];
    for (final b in bullets) {
      if (b.enemy) continue;
      var consumed = false;
      for (final r in rocks) {
        if ((b.p - r.p).distance < r.r + 5) {
          deadBullets.add(b);
          deadRocks.add(r);
          _smashRock(r);
          consumed = true;
          break;
        }
      }
      if (consumed) continue;
      final u = ufo;
      if (u != null && (b.p - u.p).distance < 28) {
        deadBullets.add(b);
        ufo = null;
        score += 200;
        popups.add(ScorePopup(u.p, '+200', 1.0));
        _burst(u.p, 18, spread: 220);
        shake = max(shake, 0.4);
        onEvent?.call(BlastEvent.bigBoom);
      }
    }
    bullets.removeWhere(deadBullets.contains);
    rocks.removeWhere(deadRocks.contains);

    // enemy bullets vs ship
    for (final b in bullets.where((b) => b.enemy).toList()) {
      if ((b.p - ship).distance < 13) {
        bullets.remove(b);
        _die();
        break;
      }
    }
    if (phase != BlastPhase.playing) return;

    // rocks vs ship
    for (final r in List<RockBody>.from(rocks)) {
      if ((r.p - ship).distance < r.r + 10) {
        rocks.remove(r);
        _burst(r.p, 8, spread: 160);
        _die();
        break;
      }
    }
    if (phase != BlastPhase.playing) return;
    final u = ufo;
    if (u != null && (u.p - ship).distance < 32) {
      ufo = null;
      _burst(u.p, 16, spread: 220);
      _die();
    }
  }

  void _smashRock(RockBody r) {
    rocksSmashed++;
    final pts = r.r > 40 ? 20 : (r.r > 20 ? 50 : 100);
    score += pts;
    popups.add(ScorePopup(r.p, '+$pts', 0.9));
    _burst(r.p, r.r > 40 ? 14 : 9, spread: 190);
    if (r.r > 40) {
      shake = max(shake, 0.28);
      onEvent?.call(BlastEvent.bigBoom);
    } else {
      onEvent?.call(BlastEvent.boom);
    }
    if (r.r > 20) {
      for (var i = 0; i < 2; i++) {
        final a = rng.nextDouble() * 2 * pi;
        rocks.add(RockBody(
          r.p,
          Offset(cos(a), sin(a)) * (70 + rng.nextDouble() * 70),
          r.r * 0.55,
          _rockVerts(),
          rng.nextDouble() * 2 * pi,
          (rng.nextDouble() - 0.5) * 3,
        ));
      }
    }
  }

  void _die() {
    if (invuln > 0 || phase != BlastPhase.playing) return;
    _burst(ship, 26, spread: 260);
    shake = 1.0;
    thrust = false;
    onEvent?.call(BlastEvent.playerHit);
    if (mode == 1) {
      // Score attack: unlimited respawns, brief pause.
      _setPhase(BlastPhase.respawning, deadline: 1.0);
      return;
    }
    lives--;
    if (lives <= 0) {
      _gameOver();
    } else {
      _setPhase(BlastPhase.respawning, deadline: 1.3);
    }
  }

  void _respawnShip() {
    ship = Offset(size.width / 2, size.height / 2);
    vel = Offset.zero;
    angle = -pi / 2;
    invuln = 2.5;
    _setPhase(BlastPhase.playing);
  }

  void _gameOver() {
    _setPhase(BlastPhase.gameOver);
    thrust = false;
    onEvent?.call(BlastEvent.playerHit);
  }

  // ---------------------------------------------------------------- waves
  void _beginWave() {
    wave++;
    final n = min(3 + difficulty + wave, [7, 9, 11][difficulty]);
    for (var i = 0; i < n; i++) {
      _spawnRock(44 + rng.nextDouble() * 10, _edgePos());
    }
    banner = 'WAVE $wave';
    bannerT = 1.6;
    onEvent?.call(BlastEvent.waveStart);
  }

  void _enterWaveBreak() {
    final bonus = wave * 100;
    score += bonus;
    popups.add(ScorePopup(
        Offset(size.width / 2, size.height * 0.4), '+$bonus WAVE BONUS', 1.4));
    banner = 'WAVE $wave CLEAR!';
    bannerT = 2.0;
    onEvent?.call(BlastEvent.waveClear);
    _setPhase(BlastPhase.waveBreak, deadline: 2.0);
  }

  Offset _edgePos() {
    final w = size.width, h = size.height;
    final m = 60.0;
    // Keep spawn points away from the ship so wave 1 is never unfair.
    for (var tries = 0; tries < 8; tries++) {
      final side = rng.nextInt(4);
      final Offset p;
      switch (side) {
        case 0:
          p = Offset(rng.nextDouble() * w, -m);
        case 1:
          p = Offset(w + m, rng.nextDouble() * h);
        case 2:
          p = Offset(rng.nextDouble() * w, h + m);
        default:
          p = Offset(-m, rng.nextDouble() * h);
      }
      if ((p - ship).distance > 170) return p;
    }
    return Offset(-m, -m);
  }

  void _spawnRock(double r, Offset p) {
    final a = rng.nextDouble() * 2 * pi;
    final base = [50.0, 70.0, 95.0][difficulty];
    final sp = base + rng.nextDouble() * (40 + wave * 8).clamp(0, 130);
    rocks.add(RockBody(
      p,
      Offset(cos(a), sin(a)) * sp,
      r,
      _rockVerts(),
      rng.nextDouble() * 2 * pi,
      (rng.nextDouble() - 0.5) * 2,
    ));
  }

  /// Rock appearance style (0..7). The engine owns the vertex profile so
  /// gameplay (collision radius) never depends on how the rock looks.
  int rockStyle = 0;

  // (vertex count, jitter range) per rock style. The engine owns the
  // vertex profile so gameplay never depends on how a rock looks.
  static const _rockCounts = [9, 12, 7, 6, 8, 11, 12, 8];
  static const _rockLo = [0.72, 0.90, 0.60, 0.75, 0.80, 0.55, 0.92, 0.70];
  static const _rockHi = [1.22, 1.10, 1.30, 1.20, 1.15, 1.45, 1.08, 1.25];

  List<double> _rockVerts() {
    final s = rockStyle.clamp(0, 7);
    final lo = _rockLo[s], hi = _rockHi[s];
    return List.generate(
        _rockCounts[s], (_) => lo + rng.nextDouble() * (hi - lo));
  }

  void _burst(Offset p, int n, {required double spread}) {
    for (var i = 0; i < n; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final sp = 40 + rng.nextDouble() * spread;
      particles.add(Spark(
        p,
        Offset(cos(a), sin(a)) * sp,
        0.45 + rng.nextDouble() * 0.45,
        0.9,
        2.5 + rng.nextDouble() * 3.5,
      ));
    }
  }

  // ------------------------------------------------------------- wrapping
  double _wx(double x, double m) {
    final w = size.width + m * 2;
    return (((x + m) % w) + w) % w - m;
  }

  double _wy(double y, double m) {
    final h = size.height + m * 2;
    return (((y + m) % h) + h) % h - m;
  }

  // ------------------------------------------------------- difficulty tune
  double _ufoInterval() => [26.0, 18.0, 12.0][difficulty];
  double _ufoBulletSpeed() => [240.0, 300.0, 360.0][difficulty];
  double _ufoError() => [0.38, 0.2, 0.09][difficulty];
}
