import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const RockBlasterApp());

class RockBlasterApp extends StatelessWidget {
  const RockBlasterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.aquaDepth,
      title: 'Rock Blaster',
      tagline: 'Blast asteroids and dodge the debris field',
      emoji: '☄️',
      slug: 'rockblaster',
      howToPlay: '• Hold ◀ ▶ to steer, ▲ to thrust\n'
          '• Tap 🔥 to shoot rocks apart\n'
          '• 🌀 hyperspace teleports you (risky!)\n'
          '• Clear every rock to warp to the next wave',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          RockBlasterScreen(players: players, callbacks: cb),
    );
  }
}
