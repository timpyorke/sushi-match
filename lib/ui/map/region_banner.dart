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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = regionOf(shopId);
    final top = locked ? Colors.blueGrey.shade300 : style.top;
    final bottom = locked ? Colors.blueGrey.shade500 : style.bottom;
    final banner = art?['banner'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: banner != null
          ? BoxDecoration(
              image: DecorationImage(
                  image: DecodedImage(banner),
                  fit: BoxFit.fill,
                  colorFilter: locked
                      ? const ColorFilter.mode(
                          Color(0x99607D8B), BlendMode.srcATop)
                      : null))
          : BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, bottom]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
      child: Row(
        children: [
          UiArt.shop(shopId).sized(24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.t('zone_$shopId'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(L10n.t(nameKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Text(style.kanji,
              style: t.titleMedium?.copyWith(
                  color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (locked)
            const UiControlIcon(UiControl.lock, color: Colors.white)
          else
            Text('$done/$total',
                style: t.titleSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
