import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rock_themes.dart';
import 'customize_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: logo, pilot profile name, mode + difficulty pickers, and
/// navigation to Play / Customize / Settings / Pro.
class MenuScreen extends StatefulWidget {
  final SpaceAudio audio;
  final BlastSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final TextEditingController _nameCtl;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.settings.playerName);
    _nameFocus = FocusNode();
    // Commit the full profile on focus loss (keystrokes are saved live).
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        widget.settings.setPlayerName(_nameCtl.text);
      }
    });
    widget.audio.startMenuMusic();
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) {
      if (mounted) {
        _nameCtl.text = widget.settings.playerName;
        widget.audio.startMenuMusic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = RockThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.6), width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/rockblaster_logo.png',
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ROCK BLASTER',
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                          Text(
                              'Best ${s.mode == 1 ? s.bestAttack : s.bestScore}  •  ${s.gamesPlayed} runs flown',
                              style: TextStyle(
                                  color: t.text.withValues(alpha: 0.6),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    if (!s.isPro)
                      GestureDetector(
                        onTap: () => _open(ProScreen(
                            audio: widget.audio, settings: s)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: t.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('PRO',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1008))),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Pilot profile name.
                _SectionLabel('PILOT NAME', t),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtl,
                  focusNode: _nameFocus,
                  maxLength: 16,
                  style: TextStyle(color: t.text, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: t.panel,
                    hintText: 'Your pilot name',
                    hintStyle: TextStyle(
                        color: t.text.withValues(alpha: 0.4)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.check, color: t.accent),
                      onPressed: () {
                        widget.audio.click();
                        s.setPlayerName(_nameCtl.text);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  onChanged: (v) {
                    // Save on every keystroke — never lose a name.
                    s.saveProfileNow(v);
                  },
                  onSubmitted: (v) {
                    widget.audio.click();
                    s.setPlayerName(v);
                  },
                ),
                const SizedBox(height: 16),
                _SectionLabel('MODE', t),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: i == 0 ? 8 : 0, left: i == 1 ? 8 : 0),
                          child: _ChoiceCard(
                            title: BlastModes.names[i],
                            subtitle: BlastModes.descriptions[i],
                            selected: s.mode == i,
                            locked: false,
                            theme: t,
                            onTap: () {
                              widget.audio.click();
                              s.setMode(i);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel('DIFFICULTY', t),
                const SizedBox(height: 6),
                Column(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ChoiceCard(
                          title: BlastDifficulties.names[i],
                          subtitle: BlastDifficulties.descriptions[i],
                          selected: s.difficulty == i,
                          locked:
                              BlastDifficulties.isPro(i) && !s.isPro,
                          theme: t,
                          onTap: () {
                            widget.audio.click();
                            if (BlastDifficulties.isPro(i) && !s.isPro) {
                              _open(ProScreen(
                                  audio: widget.audio, settings: s));
                            } else {
                              s.setDifficulty(i);
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    widget.audio.gameStart();
                    s.setPlayerName(_nameCtl.text);
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => GameScreen(
                                settings: s, audio: widget.audio)))
                        .then((_) {
                      if (mounted) widget.audio.startMenuMusic();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: const Color(0xFF1A1008),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('🚀  LAUNCH',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NavBtn('🎨 Customize', t, () => _open(
                          CustomizeScreen(
                              audio: widget.audio, settings: s))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NavBtn('⚙️ Settings', t, () => _open(
                          SettingsScreen(
                              audio: widget.audio, settings: s))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => _open(
                        ProScreen(audio: widget.audio, settings: s)),
                    child: Text(
                        s.isPro
                            ? '⭐ You are PRO — thank you!'
                            : '⭐ Go Pro — unlock everything',
                        style: TextStyle(
                            color: t.accent,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final RockThemeDef t;
  const _SectionLabel(this.text, this.t);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: t.accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2));
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool locked;
  final RockThemeDef theme;
  final VoidCallback onTap;
  const _ChoiceCard(
      {required this.title,
      required this.subtitle,
      required this.selected,
      required this.locked,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.accent.withValues(alpha: 0.22)
              : theme.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.accent
                : theme.accent.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: theme.text.withValues(alpha: 0.6),
                          fontSize: 11)),
                ],
              ),
            ),
            if (locked)
              Text('🔒',
                  style: TextStyle(
                      fontSize: 18, color: theme.text)),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final RockThemeDef t;
  final VoidCallback onTap;
  const _NavBtn(this.label, this.t, this.onTap);
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        side: BorderSide(color: t.accent.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
