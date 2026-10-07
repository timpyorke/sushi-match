import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/iap.dart';
import 'package:sushi_trio/services/store.dart';
import 'package:sushi_trio/services/wallet.dart';
import 'package:sushi_trio/ui/coin_shop_screen.dart';

import '../helpers/riverpod.dart';

class _FakeIap implements IapService {
  _FakeIap(this.result);
  final IapResult result;
  @override
  bool get available => true;
  @override
  String? priceOf(CoinPack pack) => null;
  @override
  Future<IapResult> buy(CoinPack pack) async => result;
}

void main() {
  testWidgets('stub store says coming soon and grants nothing', (tester) async {
    final c = testContainer();
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: CoinShopScreen())));
    await tester.tap(find.text(coinPacks.first.fallbackPrice));
    await tester.pump();
    expect(find.text('In-app purchases coming soon'), findsWidgets);
    expect(c.read(walletProvider).coins, Wallet.startingCoins);
  });

  testWidgets('successful purchase credits coins plus bonus', (tester) async {
    final c = ProviderContainer(overrides: [
      storeProvider.overrideWithValue(MemoryStore()),
      iapProvider.overrideWithValue(_FakeIap(IapResult.success)),
    ]);
    addTearDown(c.dispose);
    await tester
        .pumpWidget(scope(c, const MaterialApp(home: CoinShopScreen())));
    final pack = coinPacks[1];
    await tester.tap(find.text(pack.fallbackPrice));
    await tester.pump();
    expect(c.read(walletProvider).coins, Wallet.startingCoins + pack.total);
  });
}
