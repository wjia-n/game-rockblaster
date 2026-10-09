import 'package:flutter/material.dart';
import '../render/ship_art.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rock_themes.dart';
import 'pro_screen.dart';

/// Customize: theme picker (12 + custom), ship style picker (9),
/// rock style picker (8), and the custom theme color creator (Pro).
class CustomizeScreen extends StatelessWidget {
  final SpaceAudio audio;
  final BlastSettings settings;
  const CustomizeScreen(
      {super.key, required this.audio, required this.settings});

  RockThemeDef _theme() => RockThemes.byId(
        settings.themeId,
        custom: settings.customTheme,
      );

  void _needPro(BuildContext context) {
    audio.click();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProScreen(audio: audio, settings: settings)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = _theme();
        final s = settings;
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            backgroundColor: t.bg,
            foregroundColor: t.text,
            elevation: 0,
            title: const Text('Customize',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('SPACE THEME', t),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.92),
                  itemCount: RockThemes.all.length + 1,
                  itemBuilder: (_, i) {
                    final isCustom = i == RockThemes.all.length;
                    final id =
                        isCustom ? 'custom' : RockThemes.all[i].id;
                    final preview = isCustom
                        ? settings.customTheme
                        : RockThemes.all[i];
                    final locked = !s.isPro &&
                        (id == 'custom' ||
                            RockThemes.isProTheme(id));
                    final selected = s.themeId == id;
                    return GestureDetector(
                      onTap: () {
                        if (locked) {
                          _needPro(context);
                        } else {
                          audio.click();
                          s.setTheme(id);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: preview.panel,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected
                                  ? t.accent
                                  : t.accent.withValues(alpha: 0.2),
                              width: selected ? 2.5 : 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(preview.rock),
                                _dot(preview.ship),
                                _dot(preview.accent),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                  isCustom ? 'My Creation' : preview.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: preview.text,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            if (locked)
                              const Text('🔒',
                                  style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (!s.isPro)
                  Text('🔒 6 themes + the color creator are Pro',
                      style: TextStyle(
                          color: t.text.withValues(alpha: 0.55),
                          fontSize: 12)),
                const SizedBox(height: 20),
                _label('SHIP STYLE', t),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ShipStyles.names.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final locked =
                          !s.isPro && ShipStyles.isPro(i);
                      final selected = s.shipStyle == i;
                      return GestureDetector(
                        onTap: () {
                          if (locked) {
                            _needPro(context);
                          } else {
                            audio.click();
                            s.setShipStyle(i);
                          }
                        },
                        child: Container(
                          width: 84,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: t.panel,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: selected
                                    ? t.accent
                                    : t.accent.withValues(alpha: 0.2),
                                width: selected ? 2.5 : 1),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  painter: _ShipPreview(
                                      style: i,
                                      hull: t.ship,
                                      accent: t.accent),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Text(ShipStyles.names[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: t.text,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                              if (locked)
                                const Text('🔒',
                                    style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _label('ROCK STYLE', t),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0;
                        i < RockStyles.names.length;
                        i++)
                      GestureDetector(
                        onTap: () {
                          if (!s.isPro && RockStyles.isPro(i)) {
                            _needPro(context);
                          } else {
                            audio.click();
                            s.setRockStyle(i);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: s.rockStyle == i
                                ? t.accent.withValues(alpha: 0.25)
                                : t.panel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: s.rockStyle == i
                                    ? t.accent
                                    : t.accent.withValues(alpha: 0.2),
                                width: s.rockStyle == i ? 2 : 1),
                          ),
                          child: Text(
                              '${RockStyles.names[i]}${!s.isPro && RockStyles.isPro(i) ? ' 🔒' : ''}',
                              style: TextStyle(
                                  color: t.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _label('COLOR CREATOR  🔒 PRO', t),
                const SizedBox(height: 8),
                if (!s.isPro)
                  GestureDetector(
                    onTap: () => _needPro(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.panel,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                t.accent.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                          '🔒 Mix your own space colors with Pro — background, ship, rocks and more.',
                          style: TextStyle(
                              color:
                                  t.text.withValues(alpha: 0.65),
                              fontSize: 13)),
                    ),
                  )
                else
                  _ColorCreator(
                      audio: audio, settings: s, theme: t),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text, RockThemeDef t) => Text(text,
      style: TextStyle(
          color: t.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2));

  Widget _dot(Color c) => Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
            color: c, shape: BoxShape.circle),
      );
}

class _ShipPreview extends CustomPainter {
  final int style;
  final Color hull;
  final Color accent;
  _ShipPreview(
      {required this.style, required this.hull, required this.accent});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1.35);
    ShipArt.paintShip(canvas, style,
        hull: hull, accent: accent, thrust: false, tick: 0);
  }

  @override
  bool shouldRepaint(covariant _ShipPreview old) => false;
}

/// Pro-only color creator: pick each theme color from a warm palette.
class _ColorCreator extends StatelessWidget {
  final SpaceAudio audio;
  final BlastSettings settings;
  final RockThemeDef theme;
  const _ColorCreator(
      {required this.audio,
      required this.settings,
      required this.theme});

  static const _labels = {
    'bg': 'Background',
    'panel': 'Panels',
    'star': 'Stars',
    'rock': 'Rocks',
    'rockDark': 'Rock shade',
    'ship': 'Ship',
    'accent': 'Accents',
    'text': 'Text',
    'button': 'Buttons',
  };

  static const _palette = [
    0xFF0B1B33,
    0xFF14263F,
    0xFF1E3A5F,
    0xFF0E1F14,
    0xFF27402C,
    0xFF231209,
    0xFF4A2E14,
    0xFF1A0E0C,
    0xFF3C251D,
    0xFF141414,
    0xFF33302B,
    0xFFC99B6A,
    0xFFD9A05B,
    0xFFE0B25C,
    0xFF9DB38A,
    0xFFBFD9E8,
    0xFFD5DEE6,
    0xFFB98AB5,
    0xFFF2E7CF,
    0xFFF6E3C0,
    0xFFEFF6FB,
    0xFFE08A3C,
    0xFFD96C2C,
    0xFF7FB3D9,
    0xFFC96F4A,
    0xFFD95F3C,
    0xFF6FA8C9,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final key in _labels.keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(
                            settings.customColors[key]!),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: theme.accent
                                .withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_labels[key]!,
                        style: TextStyle(
                            color: theme.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in _palette)
                      GestureDetector(
                        onTap: () {
                          audio.click();
                          settings.setCustomColor(key, c);
                          settings.setTheme('custom');
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(c),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: settings
                                            .customColors[key] ==
                                        c
                                    ? theme.accent
                                    : Colors.white24,
                                width: settings
                                            .customColors[key] ==
                                        c
                                    ? 2.5
                                    : 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        OutlinedButton(
          onPressed: () {
            audio.click();
            settings.resetCustomColors();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.text,
            side: BorderSide(
                color: theme.accent.withValues(alpha: 0.5)),
          ),
          child: const Text('Reset colors'),
        ),
      ],
    );
  }
}
