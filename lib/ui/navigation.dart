import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/restaurant.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'lives_ui.dart';
import 'restaurant_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'starter_picker.dart';

/// Levels in the game; grows by editing `Restaurant.shops`.
final int kLevelCount = Restaurant.totalLevels;

/// Checks the player has a life, lets them pick starter boosters, then opens
/// level [n]. With [replace] it takes the place of the current screen (the
/// "next level" button). The life is only spent on a loss (see
/// `SushiGame._sync`).
Future<void> startLevel(BuildContext context, WidgetRef ref, int n,
    {bool replace = false}) async {
  if (!await ensureLife(context, ref) || !context.mounted) return;
  final starters = await pickStarters(context, ref);
  if (starters == null || !context.mounted) return;
  final route = MaterialPageRoute<void>(
      builder: (_) => GameScreen(levelNumber: n, starters: starters));
  final nav = Navigator.of(context);
  await (replace ? nav.pushReplacement(route) : nav.push(route));
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

void openLevels(BuildContext context) =>
    _open(context, const LevelSelectScreen());

void openRestaurant(BuildContext context) =>
    _open(context, const RestaurantScreen());

void openShop(BuildContext context) =>
    _open(context, const BoosterShopScreen());

void openSettings(BuildContext context) =>
    _open(context, const SettingsScreen());
