import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ui_art.dart';
import 'japan_map.dart';
import 'map_art.dart';

/// Draws the tile grid, the route between levels and its cleared part.
class TileMapPainter extends CustomPainter {
  TileMapPainter(
      {required this.layout,
      required this.tile,
      required this.reached,
      required this.scroll,
      this.topPad = 0,
      this.art})
      : super(repaint: scroll);

  /// The map scrolls under a painter that stays the size of the viewport, so
  /// only the rows on screen are ever recorded and rasterised.
  final ScrollController scroll;
  final double topPad;

  final MapLayout layout;
  final double tile;

  /// Distance along the route up to the next level to play.
  final double reached;

  /// Decoded sprites; `null` until loaded, then shapes are drawn instead.
  final MapArt? art;

  // Shared paints: this runs thousands of times per frame.
  static final _spritePaint = Paint()..filterQuality = FilterQuality.medium;
  static final _fadePaint = Paint()..filterQuality = FilterQuality.medium;
  static Paint _fadedPaint(double alpha) =>
      _fadePaint..color = Color.fromRGBO(255, 255, 255, alpha);

  /// Draws [img] inside [rc], keeping its proportions. [flipX] mirrors it
  /// first, then [turns] rotates it clockwise in quarter turns.
  void _sprite(Canvas canvas, ui.Image? img, Rect rc,
      {double scale = 1,
      Alignment align = Alignment.center,
      double alpha = 1,
      int turns = 0,
      bool flipX = false}) {
    if (img == null) return;
    final transformed = turns != 0 || flipX;
    if (transformed) {
      canvas.save();
      canvas.translate(rc.center.dx, rc.center.dy);
      canvas.rotate(turns * 1.5707963267948966);
      if (flipX) canvas.scale(-1, 1);
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
    if (transformed) canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    canvas.translate(0, topPad - offset);
    // Only the rows on screen: the map is 168 rows tall.
    final clip = canvas.getLocalClipBounds();
    final first = (clip.top / tile).floor().clamp(0, layout.rows);
    final last = (clip.bottom / tile).ceil().clamp(0, layout.rows);
    // Land sprites drawn in the first pass; their coast and scenery go on
    // top in a second pass so the coast can spill over into the sea.
    final land = <(Rect, int, int)>[];
    final inner = <(Rect, int)>[];
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
            final turns = _innerTurns(c, r);
            if (turns != null) inner.add((rect, turns));
          }
          continue;
        }
        final base = (c + r) % 2 == 0
            ? region.land
            : Color.lerp(region.land, Colors.white, 0.12)!;
        final id = layout.shops[shop].id;
        if (a != null && a.region(id, 'land_a') != null) {
          final ground = hash < 2
              ? ((c + r) % 2 == 0 ? 'land_c' : 'land_d')
              : ((c + r) % 2 == 0 ? 'land_a' : 'land_b');
          _sprite(canvas, a.region(id, ground), rect);
          land.add((rect, c, r));
          continue;
        }
        canvas.drawRect(rect, fill..color = base);
        if (_sea(c, r + 1)) {
          canvas.drawRect(
              Rect.fromLTWH(
                  rect.left, rect.bottom - tile * 0.2, tile + 0.5, tile * 0.2),
              fill..color = Color.lerp(region.land, Colors.brown, 0.55)!);
        }
      }
    }
    final a = art;
    if (a != null) {
      for (final (rect, c, r) in land) {
        _coast(canvas, a, rect, c, r);
      }
      for (final (rect, turns) in inner) {
        _sprite(canvas, a['cliff_inner'], rect, turns: turns);
      }
    }
    _scenery(canvas, first, last, fill);
    _route(canvas);
  }

  /// Decorations whose box reaches rows [first] to [last]. They are placed
  /// off the route and the level plates (see [MapLayout.scenery]).
  void _scenery(Canvas canvas, int first, int last, Paint fill) {
    const half = MapLayout.sceneryScale / 2;
    for (final sc in layout.scenery) {
      if (sc.at.dy + half < first || sc.at.dy - half > last) continue;
      final centre = sc.at * tile;
      final a = art;
      final img = a?.region(layout.shops[sc.shop].id, sc.kind);
      if (img != null) {
        _sprite(
            canvas,
            img,
            Rect.fromCenter(
                center: centre,
                width: tile * MapLayout.sceneryScale,
                height: tile * MapLayout.sceneryScale));
        continue;
      }
      final shape = switch (sc.kind) {
        'mountain' => MapTile.mountain,
        'forest' => MapTile.forest,
        'city' => MapTile.city,
        _ => null,
      };
      if (shape != null) {
        _deco(
            canvas,
            Rect.fromCenter(center: centre, width: tile, height: tile),
            shape,
            fill);
      }
    }
  }

  /// Whether ([c], [r]) is sea. The map edge counts as sea, so the land ends
  /// in a cliff there too.
  bool _sea(int c, int r) =>
      c < 0 ||
      c >= kMapCols ||
      r < 0 ||
      r >= layout.rows ||
      layout.tileAt(c, r) == MapTile.sea;

  /// Quarter turns for the inner-corner cliff on sea tile ([c], [r]), or null
  /// if it isn't one: land on two adjacent sides and on the diagonal between
  /// them. The sprite has its land above and to the left.
  int? _innerTurns(int c, int r) {
    // Turn 0: up + left, 1: up + right, 2: down + right, 3: down + left.
    const dirs = [(0, -1, -1, 0), (0, -1, 1, 0), (0, 1, 1, 0), (0, 1, -1, 0)];
    for (var t = 0; t < 4; t++) {
      final (ax, ay, bx, by) = dirs[t];
      if (!_sea(c + ax, r + ay) &&
          !_sea(c + bx, r + by) &&
          !_sea(c + ax + bx, r + ay + by)) {
        return t;
      }
    }
    return null;
  }

  /// A stable pseudo-random number for cell ([c], [r]), so the coast looks
  /// varied but the same on every frame.
  static int _noise(int c, int r, int salt) {
    var h = c * 374761393 + r * 668265263 + salt * 1442695041;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  /// Coast: a cliff along every side of a land tile that faces the sea.
  ///
  /// The sprites are drawn for one orientation and rotated clockwise into
  /// place: `cliff` has the sea below, `cliff_l` below and to the left, and
  /// `cliff_u` on every side but the top. Two sea sides that meet take the
  /// corner piece and three take the U, so strips never overlap at a corner.
  /// The corner and U pieces have a wavy outer edge, so they are drawn a
  /// little larger to reach the sea on every side.
  /// Each piece is mirrored at random (a mirrored `cliff_l` is the next
  /// corner round), so neighbouring strips don't repeat the same rocks.
  static const _cornerScale = 1.08;

  void _coast(Canvas canvas, MapArt a, Rect rect, int c, int r) {
    // Sides as quarter turns from the bottom: 0 bottom, 1 left, 2 top,
    // 3 right (a clockwise turn takes the bottom to the left).
    final sea = [
      _sea(c, r + 1),
      _sea(c - 1, r),
      _sea(c, r - 1),
      _sea(c + 1, r),
    ];
    final count = sea.where((s) => s).length;
    final flip = _noise(c, r, 1).isOdd;
    final cliff = a['cliff'];
    if (count == 4) {
      _sprite(canvas, a['cliff_u'], rect, scale: _cornerScale, flipX: flip);
      _sprite(canvas, cliff, rect, turns: 2, flipX: !flip);
      return;
    }
    if (count == 3 && a['cliff_u'] != null) {
      // The U's open side is its top (side 2); turn it onto the land side.
      final land = sea.indexOf(false);
      _sprite(canvas, a['cliff_u'], rect,
          turns: (land + 2) % 4, scale: _cornerScale, flipX: flip);
      return;
    }
    if (count == 2 && a['cliff_l'] != null) {
      for (var s = 0; s < 4; s++) {
        // Adjacent sides s and s + 1: the L turned s times covers them; the
        // mirrored L (sea right and below) needs one more turn.
        if (sea[s] && sea[(s + 1) % 4]) {
          _sprite(canvas, a['cliff_l'], rect,
              turns: flip ? (s + 1) % 4 : s, scale: _cornerScale, flipX: flip);
          return;
        }
      }
    }
    for (var s = 0; s < 4; s++) {
      if (sea[s]) {
        _sprite(canvas, cliff, rect,
            turns: s, flipX: _noise(c, r, 2 + s).isOdd);
      }
    }
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
      old.tile != tile || old.art != art || old.reached != reached;
}
