import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = BlastSettings();
  await settings.load();
  final audio = SpaceAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  // Re-apply audio config whenever settings change (toggles, volume).
  settings.addListener(() {
    audio.configure(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      volume: settings.volume,
    );
  });
  runApp(RockBlasterApp(settings: settings, audio: audio));
}

class RockBlasterApp extends StatefulWidget {
  final BlastSettings settings;
  final SpaceAudio audio;
  const RockBlasterApp(
      {super.key, required this.settings, required this.audio});

  @override
  State<RockBlasterApp> createState() => _RockBlasterAppState();
}

class _RockBlasterAppState extends State<RockBlasterApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game screen additionally freezes its engine.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Rock Blaster',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: SplashScreen(
            audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
