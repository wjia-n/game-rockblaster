import 'package:flutter/material.dart';

/// Visual theme catalog for Rock Blaster. Physical, toy-like, cinematic —
/// deep space tones, warm stone and brass, no neon, no holographic looks.
class RockThemeDef {
  final String id;
  final String name;
  final Color bg;
  final Color panel;
  final Color star;
  final Color rock;
  final Color rockDark;
  final Color ship;
  final Color accent;
  final Color text;
  final Color button;

  const RockThemeDef({
    required this.id,
    required this.name,
    required this.bg,
    required this.panel,
    required this.star,
    required this.rock,
    required this.rockDark,
    required this.ship,
    required this.accent,
    required this.text,
    required this.button,
  });
}

class RockThemes {
  static const List<RockThemeDef> all = [
    RockThemeDef(
      id: 'midnight',
      name: 'Midnight Harbor',
      bg: Color(0xFF0B1B33),
      panel: Color(0xFF14263F),
      star: Color(0xFFB9C7E4),
      rock: Color(0xFFC99B6A),
      rockDark: Color(0xFF7A5230),
      ship: Color(0xFFF2E7CF),
      accent: Color(0xFFE08A3C),
      text: Color(0xFFF2E7CF),
      button: Color(0xFF1E3A5F),
    ),
    RockThemeDef(
      id: 'ember',
      name: 'Ember Belt',
      bg: Color(0xFF231209),
      panel: Color(0xFF33200F),
      star: Color(0xFFD9BE9A),
      rock: Color(0xFFD9A05B),
      rockDark: Color(0xFF8A5A28),
      ship: Color(0xFFF6E3C0),
      accent: Color(0xFFD96C2C),
      text: Color(0xFFF6E3C0),
      button: Color(0xFF4A2E14),
    ),
    RockThemeDef(
      id: 'frost',
      name: 'Frost Field',
      bg: Color(0xFF0D1E2E),
      panel: Color(0xFF16293C),
      star: Color(0xFFCFE3F2),
      rock: Color(0xFFBFD9E8),
      rockDark: Color(0xFF6E8FA5),
      ship: Color(0xFFEFF6FB),
      accent: Color(0xFF7FB3D9),
      text: Color(0xFFEFF6FB),
      button: Color(0xFF24435A),
    ),
    RockThemeDef(
      id: 'velvet',
      name: 'Nebula Velvet',
      bg: Color(0xFF1C1226),
      panel: Color(0xFF2A1D36),
      star: Color(0xFFC9B3D6),
      rock: Color(0xFFB98AB5),
      rockDark: Color(0xFF6E4A6B),
      ship: Color(0xFFF0E2EC),
      accent: Color(0xFFC96F4A),
      text: Color(0xFFF0E2EC),
      button: Color(0xFF3E2C48),
    ),
    RockThemeDef(
      id: 'solar',
      name: 'Solar Winds',
      bg: Color(0xFF241A08),
      panel: Color(0xFF35280E),
      star: Color(0xFFE3CDA0),
      rock: Color(0xFFE0B25C),
      rockDark: Color(0xFF8A6528),
      ship: Color(0xFFF7EBCB),
      accent: Color(0xFFC97B2D),
      text: Color(0xFFF7EBCB),
      button: Color(0xFF4A3A16),
    ),
    RockThemeDef(
      id: 'moss',
      name: 'Moss & Stone',
      bg: Color(0xFF0E1F14),
      panel: Color(0xFF182E1F),
      star: Color(0xFFC4D4B4),
      rock: Color(0xFF9DB38A),
      rockDark: Color(0xFF55663F),
      ship: Color(0xFFEDF2DF),
      accent: Color(0xFFD08A3C),
      text: Color(0xFFEDF2DF),
      button: Color(0xFF27402C),
    ),
    RockThemeDef(
      id: 'copper',
      name: 'Copper Canyon',
      bg: Color(0xFF1F1410),
      panel: Color(0xFF2E211A),
      star: Color(0xFFD6BC9E),
      rock: Color(0xFFC47B4A),
      rockDark: Color(0xFF74421F),
      ship: Color(0xFFF3DFC0),
      accent: Color(0xFFE0A33C),
      text: Color(0xFFF3DFC0),
      button: Color(0xFF43301F),
    ),
    RockThemeDef(
      id: 'arctic',
      name: 'Arctic Night',
      bg: Color(0xFF101820),
      panel: Color(0xFF1B2530),
      star: Color(0xFFDCE8F2),
      rock: Color(0xFFD5DEE6),
      rockDark: Color(0xFF8E9DAA),
      ship: Color(0xFFF4F7FA),
      accent: Color(0xFF6FA8C9),
      text: Color(0xFFF4F7FA),
      button: Color(0xFF2A3A48),
    ),
    RockThemeDef(
      id: 'volcano',
      name: 'Volcanic Glass',
      bg: Color(0xFF1A0E0C),
      panel: Color(0xFF281814),
      star: Color(0xFFD4B8A8),
      rock: Color(0xFF8A6A5C),
      rockDark: Color(0xFF463229),
      ship: Color(0xFFEFE0D0),
      accent: Color(0xFFD95F3C),
      text: Color(0xFFEFE0D0),
      button: Color(0xFF3C251D),
    ),
    RockThemeDef(
      id: 'sandstorm',
      name: 'Sandstorm',
      bg: Color(0xFF1E1A10),
      panel: Color(0xFF2D2818),
      star: Color(0xFFDCCB9E),
      rock: Color(0xFFC9A86A),
      rockDark: Color(0xFF7A5F30),
      ship: Color(0xFFF5EAD0),
      accent: Color(0xFFB97B2D),
      text: Color(0xFFF5EAD0),
      button: Color(0xFF423A20),
    ),
    RockThemeDef(
      id: 'twilight',
      name: 'Twilight Harbor',
      bg: Color(0xFF0C1C1E),
      panel: Color(0xFF162C2E),
      star: Color(0xFFBDD4CC),
      rock: Color(0xFF9FB8A8),
      rockDark: Color(0xFF54665A),
      ship: Color(0xFFEAF2E8),
      accent: Color(0xFFD08A3C),
      text: Color(0xFFEAF2E8),
      button: Color(0xFF234042),
    ),
    RockThemeDef(
      id: 'charcoal',
      name: 'Charcoal Works',
      bg: Color(0xFF141414),
      panel: Color(0xFF232323),
      star: Color(0xFFC9C4BB),
      rock: Color(0xFF9A938A),
      rockDark: Color(0xFF54504A),
      ship: Color(0xFFEDE8DE),
      accent: Color(0xFFD98A3C),
      text: Color(0xFFEDE8DE),
      button: Color(0xFF33302B),
    ),
  ];

  /// Themes at index >= 6 are Pro-only. 'custom' is always Pro-only.
  static bool isProTheme(String id) {
    if (id == 'custom') return true;
    final i = all.indexWhere((t) => t.id == id);
    return i >= 6;
  }

  static RockThemeDef byId(String id, {RockThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  /// Build the user-designed custom theme from stored colors.
  static RockThemeDef customFrom(Map<String, int> c) {
    Color k(String key, int fallback) => Color(c[key] ?? fallback);
    return RockThemeDef(
      id: 'custom',
      name: 'My Creation',
      bg: k('bg', 0xFF0B1B33),
      panel: k('panel', 0xFF14263F),
      star: k('star', 0xFFB9C7E4),
      rock: k('rock', 0xFFC99B6A),
      rockDark: k('rockDark', 0xFF7A5230),
      ship: k('ship', 0xFFF2E7CF),
      accent: k('accent', 0xFFE08A3C),
      text: k('text', 0xFFF2E7CF),
      button: k('button', 0xFF1E3A5F),
    );
  }
}

/// Ship hull styles (drawn as vector paths — toy-like, physical).
class ShipStyles {
  static const names = [
    'Classic Arrow',
    'Toy Rocket',
    'Saucer',
    'Dart',
    'Shuttle',
    'Cruiser',
    'Wedge',
    'Blade',
    'Ring Runner',
  ];

  /// Index >= 5 needs Pro.
  static bool isPro(int i) => i >= 5;
}

/// Asteroid rock styles (vertex profile variants — chunky stone looks).
class RockStyles {
  static const names = [
    'Jagged',
    'Rounded',
    'Crystal',
    'Slab',
    'Chunky',
    'Spiky',
    'Pebble',
    'Boulder',
  ];

  /// Index >= 5 needs Pro.
  static bool isPro(int i) => i >= 5;
}

/// Difficulty tiers with clear progression.
class BlastDifficulties {
  static const names = ['Cadet', 'Pilot', 'Ace'];
  static const descriptions = [
    'Slow rocks, gentle UFOs. Learn the ropes.',
    'Faster rocks, more of them. UFOs shoot back.',
    'Relentless. PRO only. Prove yourself.',
  ];

  /// Ace (index 2) needs Pro.
  static bool isPro(int i) => i >= 2;
}

/// Game modes.
class BlastModes {
  static const names = ['Endless', 'Score Attack'];
  static const descriptions = [
    '3 lives. Survive the waves as long as you can.',
    '2 minutes, unlimited respawns. Max score wins.',
  ];
}
