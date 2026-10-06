import 'dart:async';

import 'package:flutter/material.dart';

import '../services/wallet.dart';
import 'l10n.dart';
import 'ui_art.dart';

String _mmss(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// True when the player has a life to spend. Otherwise offers to refill one
/// with coins (rewarded ads would slot in here later) and re-checks.
Future<bool> ensureLife(BuildContext context) async {
  Wallet.tick();
  if (Wallet.lives.value > 0) return true;
  await showDialog<void>(context: context, builder: (_) => const _NoLives());
  return Wallet.lives.value > 0;
}

class _NoLives extends StatefulWidget {
  const _NoLives();

  @override
  State<_NoLives> createState() => _NoLivesState();
}

class _NoLivesState extends State<_NoLives> {
  Timer? _timer;
  bool _broke = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(Wallet.tick));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Wallet.lives.value > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
    final left = Wallet.nextLifeIn;
    return AlertDialog(
      title: Text('💔 ${L10n.t('outOfLives')}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (left != null) Text(L10n.t('nextLifeIn', {'t': _mmss(left)})),
          if (_broke)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(L10n.t('notEnoughCoins'),
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.t('wait'))),
        FilledButton(
          onPressed: () {
            if (!Wallet.refillLifeWithCoins()) setState(() => _broke = true);
          },
          child: Text(L10n.t('refill', {'n': Wallet.lifeRefillCost})),
        ),
      ],
    );
  }
}

/// Hearts and coins strip for the level-select screen.
class WalletBar extends StatefulWidget {
  const WalletBar({super.key});

  @override
  State<WalletBar> createState() => _WalletBarState();
}

class _WalletBarState extends State<WalletBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(Wallet.tick));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Wallet.lives, Wallet.coins]),
      builder: (context, _) {
        final left = Wallet.nextLifeIn;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill('❤️ ${Wallet.lives.value}'
                '${left == null ? '' : '  ${_mmss(left)}'}'),
            const SizedBox(width: 8),
            _pill('🪙 ${Wallet.coins.value}'),
          ],
        );
      },
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: UiArt.plankDecoration(),
        child: Text(text,
            style:
                const TextStyle(color: UiArt.ink, fontWeight: FontWeight.bold)),
      );
}
