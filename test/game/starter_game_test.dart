import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sushi_match/game/sushi_game.dart';
import 'package:sushi_match/services/wallet.dart';

import '../core/helpers.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Wallet.load();
  });

  test('a starter booster is spent when the level starts', () {
    Wallet.stock.value = {Booster.starterKnife: 1};
    SushiGame(level: testLevel(), starters: const [Booster.starterKnife]);
    expect(Wallet.count(Booster.starterKnife), 0);
    expect(Wallet.coins.value, Wallet.startingCoins);
  });

  test('an unowned starter is ignored, never bought with coins', () {
    SushiGame(level: testLevel(), starters: const [Booster.starterWasabi]);
    expect(Wallet.coins.value, Wallet.startingCoins);
  });
}
