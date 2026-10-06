import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/daily_reward.dart';
import 'l10n.dart';
import 'ui_art.dart';

const _boosterEmoji = {
  'chopsticks': '🥢',
  'shuffle': '🔀',
  'starterKnife': '🔪',
  'extraMoves': '➕',
  'freeSwap': '🔄',
  'starterWasabi': '🟢',
};

String _label(DailyPrize p) =>
    '🪙${p.coins}${p.booster == null ? '' : ' ${_boosterEmoji[p.booster!.name]}×${p.qty}'}';

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
    return AlertDialog(
      title: Text('🎁 ${L10n.t('dailyTitle')}'),
      content: SizedBox(
        width: 320,
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
            ? FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.check))
            : FilledButton(
                onPressed: _claim, child: Text(L10n.t('dailyClaim'))),
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
      width: big ? 148 : 66,
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
            Text(done ? '✅' : _label(DailyReward.prizes[day]),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: big ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: UiArt.ink)),
          ],
        ),
      ),
    );
  }
}
