import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_engine.dart';
import '../game/sushi_game.dart';
import '../services/wallet.dart';
import 'l10n.dart';
import 'shop_screen.dart';
import 'ui_art.dart';

/// Booster buttons under the board. Shows stock, or the coin price when the
/// stock is empty, plus a one-line hint while a booster is armed.
class BoosterBar extends ConsumerWidget {
  const BoosterBar({super.key, required this.game});
  final SushiGame game;

  static const _items = [
    (Booster.chopsticks, 'chopsticks'),
    (Booster.freeSwap, 'freeSwap'),
    (Booster.shuffle, 'shuffle'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([game.armed, game.hud]),
      builder: (context, _) {
        final armed = game.armed.value;
        final playing = game.hud.value.status == GameStatus.playing;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (armed != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    L10n.t(armed == Booster.chopsticks
                        ? 'hintChopsticks'
                        : 'hintFreeSwap'),
                    style: const TextStyle(
                        color: UiArt.ink, fontWeight: FontWeight.bold),
                  ),
                ),
              Row(
                children: [
                  for (final (b, key) in _items)
                    Expanded(
                        child: _BoosterButton(
                      booster: b,
                      label: L10n.t(key),
                      stock: wallet.count(b),
                      active: armed == b,
                      enabled: playing,
                      // Out of stock: the "+" opens the shop to buy more.
                      onTap: wallet.count(b) > 0
                          ? () => game.tapBooster(b)
                          : () => showBoosterShopSheet(context),
                    )),
                  _ShopButton(
                      enabled: playing,
                      onTap: () => showBoosterShopSheet(context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton(
      {required this.booster,
      required this.label,
      required this.stock,
      required this.active,
      required this.enabled,
      required this.onTap});
  final Booster booster;
  final String label;
  final int stock;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: UiArt.plankDecoration().copyWith(
            boxShadow: active
                ? const [BoxShadow(color: Color(0xCCFFD54F), blurRadius: 12)]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BoosterIcon(booster, size: 32),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: UiArt.ink, fontSize: 11)),
              Text(stock > 0 ? '×$stock' : '+',
                  style: const TextStyle(
                      color: UiArt.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the booster shop sheet without leaving the level.
class _ShopButton extends StatelessWidget {
  const _ShopButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 52,
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: UiArt.plankDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShopIcon(size: 32),
              Text(L10n.t('shop'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: UiArt.ink, fontSize: 11)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
