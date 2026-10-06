import 'package:flutter/material.dart';

import '../core/level.dart';
import 'l10n.dart';
import 'ui_art.dart';

/// A diner who places the level's goals as a food order.
class Customer {
  const Customer(this.emoji, this.nameKey);
  final String emoji;
  final String nameKey;

  String get name => L10n.t(nameKey);

  static const roster = [
    Customer('👵', 'cust0'),
    Customer('👨‍💼', 'cust1'),
    Customer('👧', 'cust2'),
    Customer('🐱', 'cust3'),
    Customer('🧑‍🎤', 'cust4'),
    Customer('👴', 'cust5'),
  ];

  /// Customers take turns across levels so every plate has a face.
  static Customer forLevel(int levelId) =>
      roster[(levelId - 1) % roster.length];
}

/// "I'd like 20 Salmon and 15 Tamago, please!" built from the level goals.
String orderText(List<LevelGoal> goals) {
  final items = [
    for (final g in goals)
      switch (g.type) {
        GoalType.collect =>
          L10n.t('itemCollect', {'n': g.count, 'piece': L10n.t(g.piece!.name)}),
        GoalType.score => L10n.t('itemScore', {'n': g.count}),
        GoalType.clearNori => L10n.t('itemNori'),
        GoalType.breakIce => L10n.t('itemIce'),
        GoalType.breakBag => L10n.t('itemBag'),
      },
  ];
  final joined = items.length < 2
      ? items.join()
      : '${items.take(items.length - 1).join(', ')} '
          '${L10n.t('and')} ${items.last}';
  return L10n.t('orderIntro', {'items': joined});
}

/// Customer avatar with a speech bubble stating the order.
class OrderBubble extends StatelessWidget {
  const OrderBubble({super.key, required this.level});
  final LevelConfig level;

  @override
  Widget build(BuildContext context) {
    final customer = Customer.forLevel(level.id);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: UiArt.plankDecoration(),
      child: Row(
        children: [
          Text(customer.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(customer.name,
                    style: t.labelSmall?.copyWith(
                        color: UiArt.ink, fontWeight: FontWeight.bold)),
                Text(orderText(level.goals),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: UiArt.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
