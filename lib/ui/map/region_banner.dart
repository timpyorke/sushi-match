import 'package:flutter/material.dart';

import '../l10n.dart';
import '../ui_art.dart';
import 'japan_map.dart';
import 'map_art.dart';

/// Name banner of one restaurant, shown above its levels.
class RegionBanner extends StatelessWidget {
  const RegionBanner(
      {super.key,
      required this.shopId,
      this.art,
      required this.nameKey,
      required this.locked,
      required this.done,
      required this.total});
  final String shopId, nameKey;
  final MapArt? art;
  final bool locked;
  final int done, total;

  /// The cream board inside the banner sprite's red frame, as fractions of
  /// the sprite (the ropes take its top third).
  static const _boardInsets =
      (left: 0.08, top: 0.39, right: 0.08, bottom: 0.18);

  @override
  Widget build(BuildContext context) {
    final banner = art?['banner'];
    if (banner == null) return _plain(context);
    return DecoratedBox(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: DecodedImage(banner),
              fit: BoxFit.fill,
              colorFilter: locked
                  ? const ColorFilter.mode(Color(0x99607D8B), BlendMode.srcATop)
                  : null)),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        const b = _boardInsets;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              w * b.left, h * b.top, w * b.right, h * b.bottom),
          // Shrinks the text to the board rather than spilling over the frame.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: w * (1 - b.left - b.right),
              child: _content(context, UiArt.ink),
            ),
          ),
        );
      }),
    );
  }

  /// Gradient fallback while the banner sprite loads.
  Widget _plain(BuildContext context) {
    final style = regionOf(shopId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: locked
                ? [Colors.blueGrey.shade300, Colors.blueGrey.shade500]
                : [style.top, style.bottom]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: _content(context, Colors.white),
    );
  }

  /// Shop icon, zone and restaurant name, kanji and progress, in [ink].
  Widget _content(BuildContext context, Color ink) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        UiArt.shop(shopId).sized(24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L10n.t('zone_$shopId'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall
                      ?.copyWith(color: ink, fontWeight: FontWeight.bold)),
              Text(L10n.t(nameKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: ink.withAlpha(180))),
            ],
          ),
        ),
        Text(regionOf(shopId).kanji,
            style: t.titleMedium?.copyWith(
                color: ink.withAlpha(140), fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        if (locked)
          UiControlIcon(UiControl.lock, color: ink)
        else
          Text('$done/$total',
              style: t.titleSmall
                  ?.copyWith(color: ink, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
