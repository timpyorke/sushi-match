import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/event.dart';
import '../core/piece.dart';
import '../game/piece_painter.dart';
import '../services/events.dart';
import 'game_dialog.dart';
import 'l10n.dart';
import 'ui_art.dart';

String timeLeftLabel(Duration d) {
  if (d.inHours >= 24) {
    return L10n.t('eventDays', {'d': d.inDays, 'h': d.inHours % 24});
  }
  return L10n.t('eventHours', {'h': d.inHours + 1});
}

Widget eventSprite(PieceKind kind, double size) =>
    PiecePainter.spriteOf(kind).image(
        width: size,
        cacheWidth: (size * 3).round(),
        height: size,
        errorBuilder: (_, __, ___) => SizedBox(width: size, height: size));

/// Shows the event once, the first time the player sees it.
Future<void> maybeShowEventStart(BuildContext context, WidgetRef ref) async {
  final events = ref.read(eventProvider.notifier);
  events.refresh();
  if (!events.unseen) return;
  events.markSeen();
  await showEventDialog(context);
}

Future<void> showEventDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const EventDialog());

class EventDialog extends ConsumerWidget {
  const EventDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(eventProvider);
    final event = s.active;
    if (event == null) return const SizedBox.shrink();
    final notifier = ref.read(eventProvider.notifier);
    final left = timeLeftLabel(event.timeLeft(DateTime.now()));
    return GameDialog(
      title: event.title(L10n.language),
      titleIcon: UiArt.sized(UiArt.gift, 28),
      width: 360,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          eventSprite(event.kind, 56),
          const SizedBox(height: 4),
          Text(L10n.t('eventStartBody', {'fish': L10n.t(event.kind.name)}),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
              '${L10n.t('eventProgress', {'n': s.collected})}  ·  '
              '${L10n.t('eventEndsIn', {'t': left})}',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          for (var i = 0; i < event.milestones.length; i++)
            _MilestoneRow(
              milestone: event.milestones[i],
              reached: s.collected >= event.milestones[i].target,
              claimed: s.claimed.contains(i),
              onClaim: () => notifier.claim(i),
            ),
        ],
      ),
      actions: [
        GameDialogButton(
            primary: true,
            onPressed: () => Navigator.pop(context),
            label: L10n.t('eventClose')),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow(
      {required this.milestone,
      required this.reached,
      required this.claimed,
      required this.onClaim});
  final EventMilestone milestone;
  final bool reached;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: claimed ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: reached && !claimed
              ? const Color(0xFFFFE08A)
              : const Color(0xFFF3E3C3),
          border: Border.all(color: Colors.brown.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 44,
                child: Text('${milestone.target}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: UiArt.ink))),
            Expanded(
              child: RewardAmount(
                coins: milestone.coins,
                booster: milestone.booster,
                qty: milestone.qty,
              ),
            ),
            if (claimed)
              UiArt.sized(UiArt.check, 18)
            else if (reached)
              FilledButton(
                  onPressed: onClaim, child: Text(L10n.t('eventClaim')))
            else
              const UiControlIcon(UiControl.lock, size: 18),
          ],
        ),
      ),
    );
  }
}
