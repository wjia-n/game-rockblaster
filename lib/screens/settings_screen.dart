import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rock_themes.dart';

/// Settings: audio toggles + volume, pilot name, and app info.
class SettingsScreen extends StatelessWidget {
  final SpaceAudio audio;
  final BlastSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  RockThemeDef _theme() => RockThemes.byId(
        settings.themeId,
        custom: settings.customTheme,
      );

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
            title: const Text('Settings',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _label('AUDIO', t),
              const SizedBox(height: 8),
              _toggle(
                'Music',
                'Menu + gameplay soundtrack',
                s.musicOn,
                (v) {
                  audio.configure(
                      musicOn: v, sfxOn: s.sfxOn, volume: s.volume);
                  s.setMusic(v);
                  if (v) audio.startMenuMusic();
                },
                t,
              ),
              _toggle(
                'Sound effects',
                'Lasers, booms, thrusters',
                s.sfxOn,
                (v) {
                  audio.configure(
                      musicOn: s.musicOn, sfxOn: v, volume: s.volume);
                  s.setSfx(v);
                  if (v) audio.click();
                },
                t,
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.panel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume',
                        style: TextStyle(
                            color: t.text,
                            fontWeight: FontWeight.w700)),
                    Slider(
                      value: s.volume,
                      activeColor: t.accent,
                      inactiveColor:
                          t.accent.withValues(alpha: 0.25),
                      onChanged: (v) {
                        audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            volume: v);
                        s.setVolume(v);
                      },
                      onChangeEnd: (_) => audio.click(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _label('PILOT', t),
              const SizedBox(height: 8),
              _tile(
                'Pilot name',
                s.playerName,
                t,
                onTap: () => _renameDialog(context),
              ),
              const SizedBox(height: 20),
              _label('LIFETIME STATS', t),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.panel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _stat('Runs flown', '${s.gamesPlayed}', t),
                    _stat('Rocks smashed', '${s.rocksSmashed}', t),
                    _stat('Waves cleared', '${s.wavesCleared}', t),
                    _stat('Best endless score', '${s.bestScore}', t),
                    _stat(
                        'Best score attack', '${s.bestAttack}', t,
                        last: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Rock Blaster v2.0 • by WAJIHA',
                    style: TextStyle(
                        color: t.text.withValues(alpha: 0.45),
                        fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _renameDialog(BuildContext context) {
    final t = _theme();
    final ctl = TextEditingController(text: settings.playerName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.panel,
        title: Text('Pilot name',
            style: TextStyle(color: t.text, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctl,
          maxLength: 16,
          autofocus: true,
          style: TextStyle(color: t.text),
          // Save on every keystroke; "Save" commits the full state.
          onChanged: (v) => settings.saveProfileNow(v),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Your pilot name',
            hintStyle:
                TextStyle(color: t.text.withValues(alpha: 0.4)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: t.accent)),
          ),
          TextButton(
            onPressed: () {
              audio.click();
              settings.setPlayerName(ctl.text);
              Navigator.of(context).pop();
            },
            child: Text('Save', style: TextStyle(color: t.accent)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, RockThemeDef t) => Text(text,
      style: TextStyle(
          color: t.accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2));

  Widget _toggle(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, RockThemeDef t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: t.text, fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: TextStyle(
                        color: t.text.withValues(alpha: 0.55),
                        fontSize: 12)),
              ],
            ),
          ),
          Switch(
              value: value,
              activeThumbColor: t.accent,
              onChanged: (v) {
                audio.click();
                onChanged(v);
              }),
        ],
      ),
    );
  }

  Widget _tile(
      String title, String value, RockThemeDef t, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: t.text.withValues(alpha: 0.6),
                          fontSize: 12)),
                  Text(value,
                      style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ],
              ),
            ),
            Icon(Icons.edit, color: t.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, RockThemeDef t,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: t.text.withValues(alpha: 0.65),
                      fontSize: 13))),
          Text(value,
              style: TextStyle(
                  color: t.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
