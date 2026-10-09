import 'package:flutter/material.dart';

import 'japan_map.dart';
import 'level_node.dart';
import 'map_art.dart';
import 'region_banner.dart';
import 'tile_map_painter.dart';

/// The scrollable map: tiles, route, banners and level nodes.
class TileMapView extends StatefulWidget {
  const TileMapView(
      {super.key,
      required this.layout,
      required this.cleared,
      required this.stars,
      required this.lockedShop,
      required this.onTap});
  final MapLayout layout;
  final int cleared;
  final Map<int, int> stars;

  /// Whether the restaurant at this shop index is locked.
  final bool Function(int shopIndex) lockedShop;
  final ValueChanged<int> onTap;

  @override
  State<TileMapView> createState() => _TileMapViewState();
}

class _TileMapViewState extends State<TileMapView>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final _sea =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();
  bool _positioned = false;
  MapArt? _art;

  @override
  void initState() {
    super.initState();
    MapArt.load().then((a) {
      if (mounted) setState(() => _art = a);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _sea.dispose();
    super.dispose();
  }

  /// Opens the map with the next level to play in the middle of the screen.
  void _focus(double y, double viewport) {
    if (_positioned) return;
    _positioned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(
          (y - viewport * 0.5).clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final cleared = widget.cleared;
    return LayoutBuilder(builder: (context, box) {
      const pad = 20.0;
      final width = box.maxWidth - pad * 2;
      final tile = width / kMapCols;
      final size = (tile - 2).clamp(34.0, 50.0);
      final nodeW = size + 12;
      final height = (layout.rows + 1) * tile;

      final next = (cleared + 1).clamp(1, layout.levelCount);
      _focus(layout.nodes[next - 1].dy * tile, box.maxHeight);

      final locked = {
        for (var s = 0; s < layout.shops.length; s++)
          if (widget.lockedShop(s)) s
      };

      return Stack(children: [
        Positioned.fill(
          // The painter does not clip itself; keep it off the header above.
          child: ClipRect(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: TileMapPainter(
                    layout: layout,
                    tile: tile,
                    art: _art,
                    scroll: _scroll,
                    topPad: 8,
                    sidePad: pad,
                    sea: _sea,
                    reached: layout.nodeDist[next - 1]),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(pad, 8, pad, 16),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var s = 0; s < layout.shops.length; s++)
                  if (layout.shops[s].firstLevel <= layout.levelCount)
                    Positioned(
                      left: tile * 0.3,
                      width: width - tile * 0.6,
                      top: (layout.bandTop(s) + 0.3) * tile,
                      height: tile * 1.4,
                      child: RegionBanner(
                        shopId: layout.shops[s].id,
                        art: _art,
                        nameKey: layout.shops[s].nameKey,
                        locked: locked.contains(s),
                        done: (cleared - (layout.shops[s].firstLevel - 1))
                            .clamp(
                                0,
                                layout.shops[s].lastLevel -
                                    layout.shops[s].firstLevel +
                                    1),
                        total: layout.shops[s].lastLevel -
                            layout.shops[s].firstLevel +
                            1,
                      ),
                    ),
                for (var n = 1; n <= layout.levelCount; n++)
                  Positioned(
                    left: layout.nodes[n - 1].dx * tile - nodeW / 2,
                    top: layout.nodes[n - 1].dy * tile - size / 2,
                    width: nodeW,
                    child: LevelNode(
                      level: n,
                      size: size,
                      locked: n > cleared + 1 || _lockedLevel(n, locked),
                      done: n <= cleared,
                      stars: widget.stars[n] ?? 0,
                      current: n == cleared + 1 && !_lockedLevel(n, locked),
                      boss: widget.layout.isShopEnd(n),
                      art: _art,
                      onTap: () => widget.onTap(n),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  bool _lockedLevel(int n, Set<int> lockedShops) {
    for (final s in lockedShops) {
      final shop = widget.layout.shops[s];
      if (n >= shop.firstLevel && n <= shop.lastLevel) return true;
    }
    return false;
  }
}
