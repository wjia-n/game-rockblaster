import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/rock_themes.dart';

/// Pro screen: Free-vs-Pro comparison table, Pro purchase, tip jar
/// (coffee/chocolate), restore purchases, and an honest "available after
/// store setup" state while the products are not yet configured.
class ProScreen extends StatefulWidget {
  final SpaceAudio audio;
  final BlastSettings settings;
  const ProScreen({super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;

  RockThemeDef _theme() => RockThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _store.init();
    if (mounted) setState(() => _loading = false);
  }

  
  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme();
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(
          backgroundColor: t.bg,
          foregroundColor: t.text,
          elevation: 0,
          title: const Text('Rock Blaster PRO',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: t.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: t.accent.withValues(alpha: 0.5), width: 2),
                ),
                child: Column(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 6),
                    Text(
                        s.isPro
                            ? 'You are PRO — thank you!'
                            : 'Unlock the full asteroid belt',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        s.isPro
                            ? 'Every theme, ship, rock and difficulty is yours.'
                            : 'One payment. Yours forever. No subscriptions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.text.withValues(alpha: 0.65),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _table(t, s.isPro),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (s.isPro)
                _thanksCard(t)
              else
                _buySection(t),
              const SizedBox(height: 16),
              _tipJar(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _table(RockThemeDef t, bool isPro) {
    const rows = [
      ['Endless + Score Attack', true, true],
      ['Cadet + Pilot difficulty', true, true],
      ['6 space themes', true, true],
      ['5 ship styles', true, true],
      ['5 rock styles', true, true],
      ['Ace difficulty 🔥', false, true],
      ['All 12 themes', false, true],
      ['All 9 ship styles', false, true],
      ['All 8 rock styles', false, true],
      ['Custom color creator', false, true],
    ];
    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                    width: 52,
                    child: Text('FREE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.text.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w800,
                            fontSize: 12))),
                SizedBox(
                    width: 52,
                    child: Text('PRO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12))),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: i.isOdd
                    ? t.bg.withValues(alpha: 0.35)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(rows[i][0] as String,
                          style: TextStyle(
                              color: t.text, fontSize: 13))),
                  SizedBox(
                      width: 52,
                      child: Text(
                          (rows[i][1] as bool) ? '✓' : '—',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: t.text.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w800))),
                  SizedBox(
                      width: 52,
                      child: Text('✓',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: t.accent,
                              fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buySection(RockThemeDef t) {
    if (!_store.available || !_store.storeReady) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '🛰 Pro purchases will appear here once the store products are set up in Play Console.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: t.text.withValues(alpha: 0.65), fontSize: 13),
        ),
      );
    }
    final p = _store.proProduct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: _store.purchaseError,
          builder: (_, err, _) => err == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(err,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _store.purchaseInProgress,
          builder: (_, busy, _) => ElevatedButton(
            onPressed: busy || p == null
                ? null
                : () {
                    widget.audio.click();
                    _store.buyPro();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: const Color(0xFF1A1008),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(strokeWidth: 2.5))
                : Text(
                    p == null
                        ? 'PRO — coming soon'
                        : '⭐ Go PRO — ${p.price}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            widget.audio.click();
            _store.restore();
          },
          child: Text('Restore purchases',
              style: TextStyle(
                  color: t.accent, fontWeight: FontWeight.w700)),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _store.lastThanks,
          builder: (_, msg, _) => msg == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(msg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: t.accent,
                          fontWeight: FontWeight.w700)),
                ),
        ),
      ],
    );
  }

  Widget _thanksCard(RockThemeDef t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        '⭐ PRO is active on this device. Fly safe, pilot!',
        textAlign: TextAlign.center,
        style:
            TextStyle(color: t.text, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _tipJar(RockThemeDef t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('☕ Tip jar',
              style: TextStyle(
                  color: t.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Fuel the indie dream — every tip keeps the rockets flying.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 12),
          if (!_loading &&
              (!_store.available || !_store.storeReady))
            Text(
              '🛰 Tips will appear here once the store products are set up in Play Console.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.text.withValues(alpha: 0.55),
                  fontSize: 12),
            )
          else
            Row(
              children: [
                Expanded(
                    child: _tipBtn(
                        _store.coffeeProduct, '☕', 'Coffee', t)),
                const SizedBox(width: 10),
                Expanded(
                    child: _tipBtn(_store.chocolateProduct,
                        '🍫', 'Chocolate', t)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tipBtn(
      ProductDetails? p, String emoji, String label, RockThemeDef t) {
    return OutlinedButton(
      onPressed: p == null
          ? null
          : () {
              widget.audio.click();
              _store.buyTip(p);
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        side: BorderSide(color: t.accent.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text('$emoji $label${p == null ? '' : '\n${p.price}'}',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}