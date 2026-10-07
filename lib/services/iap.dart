import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet.dart';

/// A coin bundle sold for real money.
class CoinPack {
  const CoinPack(this.id, this.coins, this.bonus, this.fallbackPrice);

  /// Store product id; must match the id configured in Play Console / App
  /// Store Connect.
  final String id;
  final int coins;

  /// Extra coins on top of [coins], shown as "+N bonus".
  final int bonus;

  /// Price shown until the store reports a localised one.
  final String fallbackPrice;

  int get total => coins + bonus;
}

const coinPacks = [
  CoinPack('coins_100', 100, 0, '\$0.99'),
  CoinPack('coins_550', 500, 50, '\$4.99'),
  CoinPack('coins_1200', 1000, 200, '\$9.99'),
  CoinPack('coins_3300', 2500, 800, '\$24.99'),
];

enum IapResult { success, cancelled, unavailable, failed }

/// Boundary to the platform store. Swap [StubIapService] for an
/// `in_app_purchase` backed implementation by overriding [iapProvider].
abstract interface class IapService {
  /// False while no store is wired up (the shop then shows "coming soon").
  bool get available;

  /// Localised price for [pack], or null to use [CoinPack.fallbackPrice].
  String? priceOf(CoinPack pack);

  Future<IapResult> buy(CoinPack pack);
}

class StubIapService implements IapService {
  const StubIapService();

  @override
  bool get available => false;

  @override
  String? priceOf(CoinPack pack) => null;

  @override
  Future<IapResult> buy(CoinPack pack) async => IapResult.unavailable;
}

final iapProvider = Provider<IapService>((ref) => const StubIapService());

/// Runs a purchase and credits the wallet only on success.
Future<IapResult> buyCoinPack(WidgetRef ref, CoinPack pack) async {
  final result = await ref.read(iapProvider).buy(pack);
  if (result == IapResult.success) {
    ref.read(walletProvider.notifier).earn(pack.total);
  }
  return result;
}
