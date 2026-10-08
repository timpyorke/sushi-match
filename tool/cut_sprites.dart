// Cuts the 2x2 character sheets in assets/sprites/customers/<id>/source/
// into square 256px frames next to them (<anim>_0.png … <anim>_3.png). Run
// tool/to_webp.sh afterwards: the game bundles the frames as WebP.
//
//   dart run tool/cut_sprites.dart [id …]   # default: every character
//   dart run tool/cut_sprites.dart --obstacles [id …]
//
// Generated sheets are rarely square and rarely a clean grid, so a plain
// crop-and-resize squashes the art and lets neighbouring frames bleed in.
// Instead each frame is the opaque area between the empty gaps that separate
// the four figures. All four frames of a sheet share one scale and one
// crop box so the character stays the same size, keeps its ground line and
// keeps any hop, and frames are lined up on the character's feet so idle
// loops don't drift sideways. Faint pixels (the soft aura some sheets come with) are
// dropped.
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const customerRoot = 'assets/sprites/customers';
const obstacleRoot = 'assets/sprites/obstacles';
const size = 256;
const margin = 6;

/// Pixels fainter than this count as background.
const minAlpha = 200;

void main(List<String> args) {
  final root = args.contains('--obstacles') ? obstacleRoot : customerRoot;
  final requestedIds = args.where((arg) => arg != '--obstacles').toList();
  final ids = requestedIds.isNotEmpty
      ? requestedIds
      : [
          for (final d in Directory(root).listSync().whereType<Directory>())
            d.uri.pathSegments.where((s) => s.isNotEmpty).last,
        ]
    ..sort();
  for (final id in ids) {
    final src = Directory('$root/$id/source');
    if (!src.existsSync()) {
      stderr.writeln('$id: no source/ folder, skipped');
      continue;
    }
    final sheets = src
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('_sheet.png'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final sheet in sheets) {
      final anim = sheet.uri.pathSegments.last.replaceAll('_sheet.png', '');
      final frames = cut(img.decodePng(sheet.readAsBytesSync())!);
      for (var i = 0; i < frames.length; i++) {
        File('$root/$id/${anim}_$i.png')
            .writeAsBytesSync(img.encodePng(frames[i]));
      }
      stdout.writeln('$id/$anim: ${frames.length} frames');
    }
  }
}

bool _solid(img.Image im, int x, int y) => im.getPixel(x, y).a >= minAlpha;

/// The empty row (or column) nearest the middle of [lo, hi), or the middle
/// itself when the figures touch.
int _split(int lo, int hi, bool Function(int) empty) {
  final mid = (lo + hi) ~/ 2;
  for (var d = 0; d < (hi - lo) ~/ 4; d++) {
    if (empty(mid - d)) return mid - d;
    if (empty(mid + d)) return mid + d;
  }
  return mid;
}

List<img.Image> cut(img.Image sheet) {
  final w = sheet.width, h = sheet.height;
  bool emptyRow(int y, int x0, int x1) {
    for (var x = x0; x < x1; x++) {
      if (_solid(sheet, x, y)) return false;
    }
    return true;
  }

  bool emptyCol(int x, int y0, int y1) {
    for (var y = y0; y < y1; y++) {
      if (_solid(sheet, x, y)) return false;
    }
    return true;
  }

  final rowSplit = _split(0, h, (y) => emptyRow(y, 0, w));
  final regions = <Rectangle<int>>[];
  for (final (y0, y1) in [(0, rowSplit), (rowSplit, h)]) {
    final colSplit = _split(0, w, (x) => emptyCol(x, y0, y1));
    regions
      ..add(Rectangle(0, y0, colSplit, y1 - y0))
      ..add(Rectangle(colSplit, y0, w - colSplit, y1 - y0));
  }

  // Each figure's opaque box, relative to its nominal grid cell so a hop
  // stays a hop, then shifted sideways so the feet line up.
  final cellW = w / 2, cellH = h / 2;
  final boxes = <Rectangle<int>?>[];
  final feet = <double>[];
  for (var i = 0; i < 4; i++) {
    final r = regions[i];
    final cx = (i % 2 * cellW).round(), cy = (i ~/ 2 * cellH).round();
    int? minX, minY, maxX, maxY;
    for (var y = r.top; y < r.bottom; y++) {
      for (var x = r.left; x < r.right; x++) {
        if (!_solid(sheet, x, y)) continue;
        minX = min(minX ?? x, x);
        maxX = max(maxX ?? x, x);
        minY = min(minY ?? y, y);
        maxY = max(maxY ?? y, y);
      }
    }
    if (minX == null) {
      boxes.add(null);
      feet.add(0);
      continue;
    }
    boxes.add(
        Rectangle(minX - cx, minY! - cy, maxX! - minX + 1, maxY! - minY + 1));
    // Mean x of the bottom tenth of the figure.
    var sum = 0, n = 0;
    for (var y = maxY - (maxY - minY) ~/ 10; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        if (_solid(sheet, x, y)) {
          sum += x - cx;
          n++;
        }
      }
    }
    feet.add(sum / max(n, 1));
  }
  final placed = [
    for (var i = 0; i < 4; i++)
      if (boxes[i] case final b?) b.left - feet[i].round(),
  ];
  // Box around every figure once its feet are at x = 0.
  final left = placed.reduce(min);
  final right = [
    for (var i = 0; i < 4; i++)
      if (boxes[i] case final b?) b.right - feet[i].round(),
  ].reduce(max);
  final top = boxes.whereType<Rectangle<int>>().map((b) => b.top).reduce(min);
  final bottom =
      boxes.whereType<Rectangle<int>>().map((b) => b.bottom).reduce(max);
  final union = Rectangle(left, top, right - left, bottom - top);
  final scale = (size - 2 * margin) / max(union.width, union.height);
  final offX = ((size - union.width * scale) / 2).round();
  final offY = size - margin - (union.height * scale).round();

  return [
    for (var i = 0; i < 4; i++)
      () {
        final r = regions[i];
        final cx = (i % 2 * cellW).round() + feet[i].round(),
            cy = (i ~/ 2 * cellH).round();
        // Copy only this figure's solid pixels, cropped to the shared box.
        final crop =
            img.Image(width: union.width, height: union.height, numChannels: 4);
        for (var y = 0; y < union.height; y++) {
          for (var x = 0; x < union.width; x++) {
            final sx = cx + union.left + x, sy = cy + union.top + y;
            if (sx < r.left ||
                sx >= r.right ||
                sy < r.top ||
                sy >= r.bottom ||
                !_solid(sheet, sx, sy)) {
              continue;
            }
            crop.setPixel(x, y, sheet.getPixel(sx, sy));
          }
        }
        final scaled = img.copyResize(crop,
            width: (union.width * scale).round(),
            height: (union.height * scale).round(),
            interpolation: img.Interpolation.average);
        final out = img.Image(width: size, height: size, numChannels: 4);
        return img.compositeImage(out, scaled, dstX: offX, dstY: offY);
      }(),
  ];
}
