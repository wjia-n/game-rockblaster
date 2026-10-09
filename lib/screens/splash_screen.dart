import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/rock_themes.dart';
import 'menu_screen.dart';

/// Single launch splash in two moments:
/// 1. WAJIHA company moment (official logo, unaltered).
/// 2. Game splash: game logo + name, animated loading line,
///    and the "Credits: WAJIHA" line with the company logo.
/// Audio is pre-warmed during the company moment so music starts reliably.
class SplashScreen extends StatefulWidget {
  final SpaceAudio audio;
  final BlastSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyMoment = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Company moment: pre-warm audio while the WAJIHA mark shows.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _companyMoment = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = RockThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF06080F),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        child: _companyMoment
            ? _companySplash()
            : _gameSplash(theme),
      ),
    );
  }

  Widget _companySplash() {
    return Center(
      key: const ValueKey('company'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/wajiha_logo.png',
            width: 128,
            height: 128,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          const Text('WAJIHA',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8)),
        ],
      ),
    );
  }

  Widget _gameSplash(RockThemeDef theme) {
    return Center(
      key: const ValueKey('game'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: theme.accent.withValues(alpha: 0.7), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/rockblaster_logo.png',
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 22),
          Text('ROCK BLASTER',
              style: TextStyle(
                  color: theme.text,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 6),
          Text('SMASH THE BELT. DODGE THE DEBRIS.',
              style: TextStyle(
                  color: theme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3)),
          const SizedBox(height: 30),
          SizedBox(
            width: 220,
            child: AnimatedBuilder(
              animation: _loader,
              builder: (_, _) => Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                          color: theme.accent.withValues(alpha: 0.5)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loader.value.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: theme.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _loader.value < 1
                        ? 'Fueling the rockets…'
                        : 'Ready!',
                    style: TextStyle(
                        color: theme.text.withValues(alpha: 0.75),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 44),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/wajiha_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text('Credits: WAJIHA',
                  style: TextStyle(
                      color: theme.text.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}
