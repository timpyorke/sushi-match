import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import '../core/piece.dart';
import '../core/pos.dart';
import 'piece_painter.dart';
import 'tile_art.dart';

/// What flies off a cell: the burst sprite and the grain colour (null for
/// rice and sesame).
enum BurstFx {
  grain('clear_burst', null),
  gold('clear_burst', Color(0xFFFFD54F)),
  sack('rice_spill', Color(0xFFE9D3A8)),
  ice('ice_shards', Color(0xFFBFE8FA)),
  mat('nori_bits', Color(0xFFCDB872)),
  ember('smoke', Color(0xFFFF6A1F));

  const BurstFx(this.sprite, this._color);

  /// A `TileArt.fx` name.
  final String sprite;
  final Color? _color;

  Paint? get _paint => _color == null ? null : (Paint()..color = _color);
}

/// Short-lived effects drawn on the board's [layer]: grain bursts off
/// cleared cells and the flash over cells a special hits.
class BoardEffects {
  BoardEffects(this.layer, {required this.cell});

  final Component layer;

  /// Cell size in logical pixels.
  final double cell;

  static final _rice = Paint()..color = const Color(0xFFFFFDF5);
  static final _sesame = Paint()..color = const Color(0xFF3B2A20);
  static final _kindChips = {
    for (final e in PiecePainter.colors.entries)
      e.key: Paint()..color = e.value,
  };
  final _rng = math.Random();

  /// Cap on grain bursts alive at once; extra ones in a big combo are
  /// dropped (the pop animation still plays).
  static const _maxBursts = 18;
  int _liveBursts = 0;

  /// Grains flying off a cell, over the [fx] burst sprite. Grains take
  /// [kind]'s colour when given, else [fx]'s own (rice and sesame by
  /// default).
  void burst(Vector2 at,
      {BurstFx fx = BurstFx.grain, PieceKind? kind, int count = 7}) {
    if (_liveBursts >= _maxBursts) return;
    _liveBursts++;
    if (TileArt.ready) layer.add(_FxSprite(fx.sprite, at.clone(), cell));
    final paint = kind != null ? _kindChips[kind] : fx._paint;
    layer.add(_Burst(
      onGone: () => _liveBursts--,
      position: at.clone(),
      particle: Particle.generate(
        count: count,
        lifespan: 0.55,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 360),
          speed: Vector2(
              (_rng.nextDouble() - 0.5) * 240, -60 - _rng.nextDouble() * 170),
          child: CircleParticle(
            radius: i.isEven ? 2.8 : 2.0,
            paint: paint ?? (i.isEven ? _rice : _sesame),
          ),
        ),
      ),
    ));
  }

  /// White flash over every cell a special hits, as one component.
  void flash(Iterable<Pos> cells) {
    layer.add(_Flash([
      for (final p in cells)
        Rect.fromLTWH(p.col * cell, p.row * cell, cell, cell)
    ]));
  }
}

/// A burst sprite that grows and fades out over a third of a second.
class _FxSprite extends PositionComponent {
  _FxSprite(this.name, Vector2 at, this.cell)
      : super(position: at, anchor: Anchor.center, priority: 5);

  final String name;
  final double cell;
  double _t = 0;

  static const _life = 0.35;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final side = cell * (0.8 + 0.7 * k);
    TileArt.fx(canvas, name,
        Rect.fromCenter(center: Offset.zero, width: side, height: side), 1 - k);
  }
}

/// A grain burst that reports when it is gone, for [BoardEffects]'s cap.
class _Burst extends ParticleSystemComponent {
  _Burst({required this.onGone, super.position, super.particle});

  final void Function() onGone;

  @override
  void onRemove() {
    onGone();
    super.onRemove();
  }
}

/// Fading white rectangles over the cells a special hit.
class _Flash extends Component {
  _Flash(this.rects);

  final List<Rect> rects;
  final _paint = Paint();
  double _t = 0;

  static const _life = 0.3;
  static const _alpha = 0xAA / 0xFF;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    _paint.color = const Color(0xFFFFFFFF)
        .withValues(alpha: _alpha * (1 - _t / _life).clamp(0.0, 1.0));
    for (final r in rects) {
      canvas.drawRect(r, _paint);
    }
  }
}
