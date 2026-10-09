import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/rock_themes.dart';

/// Persisted settings + stats for Rock Blaster. Survives app restarts.
///
/// Stores: audio toggles, the renameable player profile (as ONE JSON string —
/// Android's SharedPreferences stores StringLists as an unordered StringSet,
/// so we never use a StringList for ordered/profile data), theme and style
/// choices (incl. custom theme colors), game-mode setup, Pro unlock state,
/// and lifetime stats.
class BlastSettings extends ChangeNotifier {
  static const _kMusic = 'rockblaster_music_on';
  static const _kSfx = 'rockblaster_sfx_on';
  static const _kVolume = 'rockblaster_volume';
  static const _kProfile = 'rockblaster_player_name'; // legacy single key
  static const _kProfileOldJson =
      'rockblaster_profile_json'; // legacy JSON key
  /// Order-safe profile storage: ONE order-preserving JSON string via
  /// setString — {"names": ["Ace Pilot"]}. Never use setStringList for
  /// this (Android stores StringLists as an unordered StringSet).
  static const _kProfileJson = 'rockblaster_player_names_json';
  static const _kTheme = 'rockblaster_theme_id';
  static const _kShip = 'rockblaster_ship_style';
  static const _kRock = 'rockblaster_rock_style';
  static const _kMode = 'rockblaster_mode'; // 0 endless, 1 score attack
  static const _kDifficulty = 'rockblaster_difficulty'; // 0 cadet 1 pilot 2 ace
  static const _kBest = 'rockblaster_best';
  static const _kBestAttack = 'rockblaster_best_attack';
  static const _kGames = 'rockblaster_games_played';
  static const _kRocks = 'rockblaster_rocks_smashed';
  static const _kWaves = 'rockblaster_waves_cleared';
  static const _kIsPro = 'rockblaster_is_pro';
  static const _kCustomPrefix = 'rockblaster_custom_';

  static const defaultName = 'Ace Pilot';

  static String encodeProfile(String name) => jsonEncode({
        'names': [name.trim().isEmpty ? defaultName : name.trim()]
      });

  /// Decodes the order-safe JSON key, then falls back through the two
  /// legacy keys, then the default. Corrupt data never throws.
  static String decodeProfile(String? raw, String? legacy) {
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) {
          // Current format: {"names": ["Name"]}.
          final names = d['names'];
          if (names is List && names.isNotEmpty) {
            final s = '${names.first}'.trim();
            if (s.isNotEmpty) return s;
          }
          // Legacy format: {"name": "Name"}.
          if (d['name'] is String) {
            final s = (d['name'] as String).trim();
            if (s.isNotEmpty) return s;
          }
        }
      } catch (_) {}
    }
    if (legacy != null && legacy.trim().isNotEmpty) return legacy.trim();
    return defaultName;
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = defaultName;
  String themeId = 'midnight';
  int shipStyle = 0;
  int rockStyle = 0;
  int mode = 0;
  int difficulty = 0;
  int bestScore = 0;
  int bestAttack = 0;
  int gamesPlayed = 0;
  int rocksSmashed = 0;
  int wavesCleared = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Midnight Harbor.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'bg': 0xFF0B1B33,
    'panel': 0xFF14263F,
    'star': 0xFFB9C7E4,
    'rock': 0xFFC99B6A,
    'rockDark': 0xFF7A5230,
    'ship': 0xFFF2E7CF,
    'accent': 0xFFE08A3C,
    'text': 0xFFF2E7CF,
    'button': 0xFF1E3A5F,
  };

  RockThemeDef get customTheme => RockThemes.customFrom(customColors);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Profile: prefer the order-safe JSON key; migrate both legacy keys once.
    playerName = decodeProfile(p.getString(_kProfileJson),
        p.getString(_kProfileOldJson) ?? p.getString(_kProfile));
    themeId = p.getString(_kTheme) ?? 'midnight';
    shipStyle = (p.getInt(_kShip) ?? 0).clamp(0, ShipStyles.names.length - 1);
    rockStyle = (p.getInt(_kRock) ?? 0).clamp(0, RockStyles.names.length - 1);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    bestScore = p.getInt(_kBest) ?? 0;
    bestAttack = p.getInt(_kBestAttack) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    rocksSmashed = p.getInt(_kRocks) ?? 0;
    wavesCleared = p.getInt(_kWaves) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfileJson, encodeProfile(playerName));
    await p.remove(_kProfile); // drop the legacy keys for good
    await p.remove(_kProfileOldJson);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kShip, shipStyle);
    await p.setInt(_kRock, rockStyle);
    await p.setInt(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kBest, bestScore);
    await p.setInt(_kBestAttack, bestAttack);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kRocks, rocksSmashed);
    await p.setInt(_kWaves, wavesCleared);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || RockThemes.isProTheme(themeId)) {
      themeId = 'midnight';
      changed = true;
    }
    if (ShipStyles.isPro(shipStyle)) {
      shipStyle = 0;
      changed = true;
    }
    if (RockStyles.isPro(rockStyle)) {
      rockStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  /// Keystroke-save: writes ONLY the order-safe profile JSON string —
  /// cheap enough to call on every keystroke. Call [setPlayerName] on
  /// focus loss / submit to commit the full state.
  Future<void> saveProfileNow(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kProfileJson, encodeProfile(playerName));
    } catch (_) {}
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || RockThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setShipStyle(int v) async {
    v = v.clamp(0, ShipStyles.names.length - 1);
    if (!isPro && ShipStyles.isPro(v)) return;
    shipStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setRockStyle(int v) async {
    v = v.clamp(0, RockStyles.names.length - 1);
    if (!isPro && RockStyles.isPro(v)) return;
    rockStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 1);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) v = 1; // Ace is a Pro feature
    difficulty = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished run. Returns true when it set a new best.
  Future<bool> recordGame(
      {required int score,
      required int mode,
      required int rocks,
      required int waves}) async {
    gamesPlayed++;
    rocksSmashed += rocks;
    wavesCleared += waves;
    var newBest = false;
    if (mode == 1) {
      if (score > bestAttack) {
        bestAttack = score;
        newBest = true;
      }
    } else {
      if (score > bestScore) {
        bestScore = score;
        newBest = true;
      }
    }
    notifyListeners();
    await _save();
    return newBest;
  }
}
