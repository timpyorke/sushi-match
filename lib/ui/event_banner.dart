import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio.dart';
import '../services/events.dart';
import 'event_dialog.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// Home-screen card for the running weekly event; empty when there is none.
class EventBanner extends ConsumerWidget {
  const EventBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(eventProvider);
    final event = s.active;
    if (event == null) return const SizedBox.shrink();
    final goal = event.goal;
    final claimable = s.claimable;
    final left = timeLeftLabel(event.timeLeft(DateTime.now()));
    return GestureDetector(
      onTap: () {
        Audio.play(Sfx.tap);
        showEventDialog(context);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: UiArt.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: UiArt.ink, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            eventSprite(event.kind, 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title(L10n.language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: UiArt.ink)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        minHeight: 8,
                        value: goal == 0
                            ? 0
                            : (s.collected / goal).clamp(0.0, 1.0)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                      '${s.collected}/$goal  ·  '
                      '${L10n.t('eventEndsIn', {'t': left})}',
                      style: const TextStyle(fontSize: 11, color: UiArt.ink)),
                ],
              ),
            ),
            if (claimable > 0)
              Badge(
                label: Text('$claimable'),
                child: const Image(image: UiArt.gift, width: 24, height: 24),
              )
            else
              const Icon(Icons.chevron_right, color: UiArt.ink),
          ],
        ),
      ),
    );
  }
}
