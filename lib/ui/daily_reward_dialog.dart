import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/daily_reward.dart';
import 'game_dialog.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Shows the 7-day calendar if today's reward is waiting.
Future<void> maybeShowDailyReward(BuildContext context, WidgetRef ref) async {
  if (!ref.read(dailyProvider.notifier).canClaim) return;
  await showDialog<void>(
      context: context, builder: (_) => const DailyRewardDialog());
}

class DailyRewardDialog extends ConsumerStatefulWidget {
  const DailyRewardDialog({super.key});

  @override
  ConsumerState<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<DailyRewardDialog> {
  late final int _today = ref.read(dailyProvider.notifier).nextDay;
  bool _claimed = false;

  void _claim() {
    ref.read(dailyProvider.notifier).claim();
    setState(() => _claimed = true);
  }

  @override
  Widget build(BuildContext context) {
    return GameDialog(
      title: L10n.t('dailyTitle'),
      titleIcon: UiArt.sized(UiArt.gift, 28),
      width: 360,
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < DailyReward.prizes.length; i++)
              _DayCell(
                day: i,
                today: i == _today,
                done: i < _today || (i == _today && _claimed),
              ),
          ],
        ),
      ),
      actions: [
        _claimed
            ? GameDialogButton(
                primary: true,
                onPressed: () => Navigator.pop(context),
                child: UiArt.sized(UiArt.check, 24))
            : GameDialogButton(
                primary: true, onPressed: _claim, label: L10n.t('dailyClaim')),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.today, required this.done});
  final int day;
  final bool today;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final big = day == DailyReward.prizes.length - 1;
    return Container(
      // 280 wide content: three equal cells per row, day 7 spans the row.
      width: big ? 280 : 88,
      constraints: BoxConstraints(minHeight: big ? 64 : 72),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: today ? const Color(0xFFFFE08A) : const Color(0xFFF3E3C3),
        border: Border.all(
            color: today ? const Color(0xFFB71C2C) : Colors.brown.shade200,
            width: today ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Opacity(
        opacity: done && !today ? 0.5 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.t('dailyDay', {'n': day + 1}),
                style: const TextStyle(fontSize: 11, color: UiArt.ink)),
            const SizedBox(height: 2),
            if (done)
              UiArt.sized(UiArt.check, 18)
            else
              RewardAmount(
                coins: DailyReward.prizes[day].coins,
                booster: DailyReward.prizes[day].booster?.name,
                qty: DailyReward.prizes[day].qty,
                size: big ? 18 : 14,
                style: TextStyle(
                    fontSize: big ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: UiArt.ink),
              ),
          ],
        ),
      ),
    );
  }
}
