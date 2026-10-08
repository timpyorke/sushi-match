import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'japan_map.dart';
import 'map_art.dart';
import 'level_node.dart';
import '../l10n.dart';
import '../ui_art.dart';

/// Draws the tile grid, the route between levels and its cleared part.
class TileMapPainter extends CustomPainter {
  TileMapPainter(
      {required this.layout,
      required this.tile,
      required this.lockedShops,
      required this.reached,
      this.art});

  final MapLayout layout;
  final double tile;

  /// Shop indexes whose restaurant is still locked: their land is dimmed.
  final Set<int> lockedShops;

  /// Distance along the route up to the next level to play.
  final double reached;

  /// Decoded sprites; `null` until loaded, then shapes are drawn instead.
  final MapArt? art;

  // Shared paints: this runs thousands of times per frame.
  static final _spritePaint = Paint()..filterQuality = FilterQuality.medium;
  static final _fadePaint = Paint()..filterQuality = FilterQuality.medium;
  static Paint _fadedPaint(double alpha) =>
      _fadePaint..color = Color.fromRGBO(255, 255, 255, alpha);

  /// Draws [img] inside [rc], keeping its proportions.
  void _sprite(Canvas canvas, ui.Image? img, Rect rc,
      {double scale = 1,
      Alignment align = Alignment.center,
      double alpha = 1,
      int turns = 0}) {
    if (img == null) return;
    if (turns != 0) {
      canvas.save();
      canvas.translate(rc.center.dx, rc.center.dy);
      canvas.rotate(turns * 1.5707963267948966);
      canvas.translate(-rc.center.dx, -rc.center.dy);
    }
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final k = (rc.width / img.width) < (rc.height / img.height)
        ? rc.width / img.width
        : rc.height / img.height;
    final w = img.width * k * scale, h = img.height * k * scale;
    final dst = align.inscribe(Size(w, h), rc);
    canvas.drawImageRect(
        img, src, dst, alpha < 1 ? _fadedPaint(alpha) : _spritePaint);
    if (turns != 0) canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    // Only the rows on screen: the map is 168 rows tall.
    final clip = canvas.getLocalClipBounds();
    final first = (clip.top / tile).floor().clamp(0, layout.rows);
    final last = (clip.bottom / tile).ceil().clamp(0, layout.rows);
    for (var r = first; r < last; r++) {
      final shop = layout.shopOfRow(r);
      final region = regionOf(layout.shops[shop].id);
      for (var c = 0; c < kMapCols; c++) {
        final rect = Rect.fromLTWH(c * tile, r * tile, tile + 0.5, tile + 0.5);
        final type = layout.tileAt(c, r);
        final hash = (c * 7 + r * 13 + c * r) % 11;
        final a = art;
        if (type == MapTile.sea) {
          if (a != null) {
            final sea = hash == 0
                ? 'sea_c'
                : hash == 1
                    ? 'sea_d'
                    : (c + r) % 2 == 0
                        ? 'sea_a'
                        : 'sea_b';
            _sprite(canvas, a[sea], rect);
            if (hash == 5) _sprite(canvas, a['wave_crest'], rect, scale: 0.5);
          }
          continue;
        }
        final base = (c + r) % 2 == 0
            ? region.land
            : Color.lerp(region.land, Colors.white, 0.12)!;
        final id = layout.shops[shop].id;
        final below =
            r + 1 >= layout.rows ? MapTile.sea : layout.tileAt(c, r + 1);
        if (a != null && a.region(id, 'land_a') != null) {
          final land = hash < 2
              ? ((c + r) % 2 == 0 ? 'land_c' : 'land_d')
              : ((c + r) % 2 == 0 ? 'land_a' : 'land_b');
          _sprite(canvas, a.region(id, land), rect);
          // Coast: a cliff along every side that faces the sea. The map edge
          // counts as sea, so the land ends in a cliff there too.
          bool sea(int cc, int rr) =>
              cc < 0 ||
              cc >= kMapCols ||
              rr < 0 ||
              rr >= layout.rows ||
              layout.tileAt(cc, rr) == MapTile.sea;
          final left = sea(c - 1, r), right = sea(c + 1, r);
          if (below == MapTile.sea) {
            _sprite(
                canvas,
                a[left && !right
                    ? 'cliff_left'
                    : right && !left
                        ? 'cliff_right'
                        : 'cliff'],
                rect);
          }
          if (left) _sprite(canvas, a['cliff'], rect, turns: 1);
          if (right) _sprite(canvas, a['cliff'], rect, turns: 3);
          if (sea(c, r - 1)) _sprite(canvas, a['cliff'], rect, turns: 2);
          final deco = switch (type) {
            MapTile.mountain => 'mountain',
            MapTile.forest => 'forest',
            MapTile.city => 'city',
            _ => null,
          };
          // Scenery stays off the route and the level plates so they read
          // clearly, and is drawn a little smaller.
          if (deco != null && !layout.nearRoute(c, r)) {
            _sprite(canvas, a.region(id, deco), rect, scale: 0.75);
          }
          if (lockedShops.contains(shop)) {
            _sprite(canvas, a['fog'], rect, alpha: 0.9);
          }
          continue;
        }
        canvas.drawRect(rect, fill..color = base);
        if (below == MapTile.sea) {
          canvas.drawRect(
              Rect.fromLTWH(
                  rect.left, rect.bottom - tile * 0.2, tile + 0.5, tile * 0.2),
              fill..color = Color.lerp(region.land, Colors.brown, 0.55)!);
        }
        _deco(canvas, rect, type, fill);
        if (lockedShops.contains(shop)) {
          canvas.drawRect(rect, fill..color = const Color(0x66455A64));
        }
      }
    }
    _route(canvas);
  }

  void _deco(Canvas canvas, Rect rc, MapTile type, Paint p) {
    final u = tile;
    switch (type) {
      case MapTile.mountain:
        final body = Path()
          ..moveTo(rc.left + u * 0.1, rc.top + u * 0.75)
          ..lineTo(rc.left + u * 0.5, rc.top + u * 0.15)
          ..lineTo(rc.left + u * 0.9, rc.top + u * 0.75)
          ..close();
        canvas.drawPath(body, p..color = const Color(0xFF8D8D8D));
        final cap = Path()
          ..moveTo(rc.left + u * 0.38, rc.top + u * 0.33)
          ..lineTo(rc.left + u * 0.5, rc.top + u * 0.15)
          ..lineTo(rc.left + u * 0.62, rc.top + u * 0.33)
          ..close();
        canvas.drawPath(cap, p..color = Colors.white);
      case MapTile.forest:
        canvas.drawCircle(Offset(rc.left + u * 0.35, rc.top + u * 0.55),
            u * 0.22, p..color = const Color(0xFF2E7D32));
        canvas.drawCircle(Offset(rc.left + u * 0.65, rc.top + u * 0.45),
            u * 0.2, p..color = const Color(0xFF43A047));
      case MapTile.city:
        for (final (dx, h) in [(0.15, 0.4), (0.4, 0.55), (0.65, 0.3)]) {
          canvas.drawRect(
              Rect.fromLTWH(
                  rc.left + u * dx, rc.top + u * (0.8 - h), u * 0.2, u * h),
              p..color = const Color(0xFFF5E6C8));
          canvas.drawRect(
              Rect.fromLTWH(
                  rc.left + u * dx, rc.top + u * (0.8 - h), u * 0.2, u * 0.08),
              p..color = const Color(0xFFB71C2C));
        }
      case MapTile.land:
      case MapTile.sea:
        break;
    }
  }

  void _spriteRoute(Canvas canvas, MapArt a) {
    final clip = canvas.getLocalClipBounds().inflate(tile);
    final dot = Rect.fromCenter(
        center: Offset.zero, width: tile * 0.6, height: tile * 0.6);
    final done = a['route_done'], todo = a['route_dot'];
    for (final (d, at) in layout.routeStones) {
      final p = at * tile;
      if (p.dy < clip.top || p.dy > clip.bottom) continue;
      _sprite(canvas, d <= reached ? done : todo, dot.shift(p));
    }
  }

  void _route(Canvas canvas) {
    final a = art;
    if (a != null && a['route_dot'] != null && a['route_done'] != null) {
      _spriteRoute(canvas, a);
      return;
    }
    Path poly(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx * tile, pts.first.dy * tile);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx * tile, p.dy * tile);
      }
      return path;
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dash = tile * 0.22;
    for (final m in poly(layout.path).computeMetrics()) {
      stroke
        ..strokeWidth = tile * 0.12
        ..color = UiArt.ink.withValues(alpha: 0.45);
      for (var d = 0.0; d < m.length; d += dash * 2) {
        canvas.drawPath(m.extractPath(d, d + dash), stroke);
      }
    }
    if (reached > 0) {
      stroke
        ..strokeWidth = tile * 0.16
        ..color = const Color(0xFFB71C2C);
      canvas.drawPath(poly(layout.pathUpTo(reached)), stroke);
    }
  }

  @override
  bool shouldRepaint(TileMapPainter old) =>
      old.tile != tile ||
      old.art != art ||
      old.reached != reached ||
      old.lockedShops.length != lockedShops.length ||
      !old.lockedShops.containsAll(lockedShops);
}

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

class _TileMapViewState extends State<TileMapView> {
  final _scroll = ScrollController();
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
      const pad = 0.0;
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

      return SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(pad, 8, pad, 16),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: TileMapPainter(
                        layout: layout,
                        tile: tile,
                        lockedShops: locked,
                        art: _art,
                        reached: layout.nodeDist[next - 1]),
                  ),
                ),
              ),
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
                      done: (cleared - (layout.shops[s].firstLevel - 1)).clamp(
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
      );
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
