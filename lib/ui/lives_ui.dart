import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../services/store.dart';
import '../services/wallet.dart';
import 'coin_shop_screen.dart';
import 'game_dialog.dart';
import 'l10n.dart';
import 'ui_art.dart';

String _mmss(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// True when the player has a life to spend. Otherwise offers to refill one
/// with coins (rewarded ads would slot in here later) and re-checks.
Future<bool> ensureLife(BuildContext context, WidgetRef ref) async {
  if (ref.read(settingsProvider).testMode) return true;
  final wallet = ref.read(walletProvider.notifier);
  wallet.tick();
  if (ref.read(walletProvider).lives > 0) return true;
  await showDialog<void>(context: context, builder: (_) => const _NoLives());
  return ref.read(walletProvider).lives > 0;
}

class _NoLives extends ConsumerStatefulWidget {
  const _NoLives();

  @override
  ConsumerState<_NoLives> createState() => _NoLivesState();
}

class _NoLivesState extends ConsumerState<_NoLives> {
  Timer? _timer;
  bool _broke = false;

  @override
  void initState() {
    super.initState();
    // The state only changes when a life arrives; the countdown text needs a
    // redraw every second regardless.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(walletProvider.notifier).tick();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    if (wallet.lives > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
    final left = wallet.nextLifeIn(ref.read(clockProvider)());
    return GameDialog(
      title: L10n.t('outOfLives'),
      titleIcon: UiArt.sized(UiArt.heartBroken, 28),
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
        GameDialogButton(
          primary: true,
          onPressed: () {
            if (!ref.read(walletProvider.notifier).refillLifeWithCoins()) {
              setState(() => _broke = true);
            }
          },
          label: L10n.t('refill', {'n': Wallet.lifeRefillCost}),
        ),
        GameDialogButton(
            onPressed: () => Navigator.pop(context), label: L10n.t('wait')),
      ],
    );
  }
}

/// Hearts and coins strip for the level-select screen.
class WalletBar extends ConsumerStatefulWidget {
  const WalletBar({super.key, this.coinShop = false});

  /// Makes the coin pill open the coin store when tapped.
  final bool coinShop;

  @override
  ConsumerState<WalletBar> createState() => _WalletBarState();
}

class _WalletBarState extends ConsumerState<WalletBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The state only changes when a life arrives; the countdown text needs a
    // redraw every second regardless.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(walletProvider.notifier).tick();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final left = wallet.nextLifeIn(ref.read(clockProvider)());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(HeartAmount(
            '${wallet.lives}'
            '${left == null ? '' : '  ${_mmss(left)}'}',
            style: _pillStyle)),
        const SizedBox(width: 8),
        if (widget.coinShop)
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const CoinShopScreen())),
            child: _pill(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CoinAmount(wallet.coins, size: 20, style: _pillStyle),
                const SizedBox(width: 4),
                const UiControlIcon(UiControl.plus, size: 20, color: UiArt.ink),
              ],
            )),
          )
        else
          _pill(CoinAmount(wallet.coins, size: 20, style: _pillStyle)),
      ],
    );
  }

  static const _pillStyle =
      TextStyle(color: UiArt.ink, fontWeight: FontWeight.bold);

  Widget _pill(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: UiArt.plankDecoration(),
        child: child,
      );
}
