part of 'board_component.dart';

/// Plays back the engine's [BoardStep]s as animations on the views.
extension _Playback on BoardComponent {
  Future<void> _play(List<BoardStep> steps) async {
    // Falls and the refill that follows run together for a snappier feel.
    final pending = <Future<void>>[];
    for (final step in steps) {
      if (step is! RefillStep) {
        await Future.wait(pending);
        pending.clear();
      }
      switch (step) {
        case SwapStep(:final a, :final b):
          Audio.play(Sfx.swap);
          await _swapViews(a, b);
        case InvalidSwapStep(:final a, :final b):
          Audio.play(Sfx.invalid);
          await _swapViews(a, b);
          await _swapViews(a, b);
        case SpecialActivateStep():
          await _playSpecial(step);
        case TransformStep(:final changes):
          changes.forEach((id, t) => _views[id]?.special = t);
          await _wait(0.25);
        case ClearStep():
          await _playClear(step);
        case FallStep(:final moves):
          pending.addAll(_relocate(
              moves, (v, m) => _land(v, _center(m.to), _dist(m.from, m.to))));
        case RefillStep(:final pieces):
          for (final r in pieces) {
            final v = _spawnView(r.piece, r.to, from: _center(r.start));
            pending.add(_land(v, _center(r.to), _dist(r.start, r.to)));
          }
          await Future.wait(pending);
          pending.clear();
        case NoriStep(:final layers):
          layers.forEach(_background.setNori);
        case BagStep(:final hits):
          await _playBags(hits);
        case DeliverStep(:final delivered):
          Audio.play(Sfx.chime);
          final pops = _removeViews(delivered, fx: BurstFx.gold);
          _haptic(HapticFeedback.mediumImpact);
          await pops;
        case UnlockStep(:final cells, :final kind):
          await _playUnlock(cells, kind);
        case BombStep(:final ticks, :final exploded):
          ticks.forEach((id, left) => _views[id]?.timer = left);
          final pops = _removeViews(exploded, fx: BurstFx.ember);
          if (exploded.isNotEmpty) {
            Audio.play(Sfx.boom);
            _shake();
            _haptic(HapticFeedback.heavyImpact);
          }
          await pops;
          await _wait(0.12);
        case IgniteStep(:final pos, :final pieceId):
          _views[pieceId]?.burning = true;
          _fx.burst(_center(pos), fx: BurstFx.ember);
          await _wait(0.18);
        case CatHitStep(:final hits):
          await _playCatHits(hits);
        case CatMoveStep(:final catId, :final to):
          await _playCatMove(catId, to);
        case MatSpreadStep(:final pos, :final pieceId):
          await _removeViews([ClearedPiece(pieceId, pos)], burst: false);
          _background.spreadMat(pos);
          _fx.burst(_center(pos), fx: BurstFx.mat);
          await _wait(0.1);
        case IceStep(:final hits):
          Audio.play(Sfx.crack);
          for (final h in hits) {
            _views[h.pieceId]?.ice = h.layers;
            if (h.layers == 0) _fx.burst(_center(h.pos), fx: BurstFx.ice);
          }
          await _wait(0.12);
        case ConveyorStep(:final moves):
          await Future.wait(
              _relocate(moves, (v, m) => _moveTo(v, _center(m.to), 0.3)));
        case ShuffleStep(:final positions):
          Audio.play(Sfx.shuffle);
          _at.clear();
          final moves = <Future<void>>[];
          positions.forEach((id, p) {
            final v = _views[id];
            if (v == null) return;
            _at[p] = v;
            moves.add(_moveTo(v, _center(p), 0.4));
          });
          await Future.wait(moves);
        case TurnEndStep():
          break;
      }
    }
    await Future.wait(pending);
  }

  Future<void> _playSpecial(SpecialActivateStep step) async {
    _fx.flash(step.affected);
    if (step.type == SpecialType.wasabi ||
        step.comboWith == SpecialType.wasabi) {
      _shake();
      Audio.play(Sfx.boom);
    } else {
      Audio.play(Sfx.special);
    }
    await _wait(0.12);
  }

  Future<void> _playClear(ClearStep step) async {
    Audio.play(Sfx.forCascade(step.cascade));
    // Fewer grains once the board is busy: deep cascades and big blasts
    // would otherwise spawn hundreds of particles at once.
    final grains = step.cascade >= 2 || step.cleared.length > 12 ? 4 : 7;
    final pops = _removeViews(step.cleared, grains: grains);
    _haptic(step.created.isEmpty
        ? HapticFeedback.lightImpact
        : HapticFeedback.mediumImpact);
    await pops;
    for (final s in step.created) {
      final v = _spawnView(s.piece, s.pos)..scale = Vector2.zero();
      v.add(ScaleEffect.to(Vector2.all(1),
          EffectController(duration: 0.18, curve: Curves.easeOutBack)));
    }
  }

  Future<void> _playBags(List<BagHit> hits) async {
    Audio.play(Sfx.crack);
    for (final h in hits) {
      _background.setBag(h.pos, h.layers);
      _fx.burst(_center(h.pos),
          fx: h.layers == 0 ? BurstFx.sack : BurstFx.grain);
    }
    await _wait(0.15);
  }

  Future<void> _playUnlock(List<Pos> cells, PieceKind kind) async {
    Audio.play(Sfx.unlock);
    for (final p in cells) {
      final badge = _keys.remove(p);
      if (badge == null) continue;
      _fx.burst(_center(p), kind: kind);
      badge.add(ScaleEffect.to(Vector2.zero(),
          EffectController(duration: 0.25, curve: Curves.easeIn),
          onComplete: badge.removeFromParent));
    }
    _haptic(HapticFeedback.mediumImpact);
    await _wait(0.2);
  }

  Future<void> _playCatHits(List<CatHit> hits) async {
    Audio.play(Sfx.meow);
    final runs = <Future<void>>[];
    for (final h in hits) {
      final cat = _cats[h.catId];
      if (cat == null) continue;
      cat.hp = h.hp;
      if (h.hp > 0) {
        cat.play(CatAnim.hit);
        cat.add(SequenceEffect([
          RotateEffect.by(0.25, EffectController(duration: 0.06)),
          RotateEffect.by(-0.5, EffectController(duration: 0.12)),
          RotateEffect.by(0.25, EffectController(duration: 0.06)),
        ]));
        continue;
      }
      // Out of lives: the cat bolts off the board.
      _cats.remove(h.catId);
      cat.faceRight = true; // bolts off to the right
      cat.play(CatAnim.flee);
      final done = Completer<void>();
      cat.add(MoveByEffect(
          Vector2(BoardComponent.cell * 2.5, -BoardComponent.cell * 0.6),
          EffectController(duration: 0.4, curve: Curves.easeIn),
          onComplete: () {
        cat.removeFromParent();
        done.complete();
      }));
      runs.add(done.future);
    }
    _haptic(HapticFeedback.lightImpact);
    await Future.wait(runs);
    await _wait(0.1);
  }

  Future<void> _playCatMove(int catId, Pos to) async {
    final cat = _cats[catId];
    if (cat == null) return;
    final dest = _center(to);
    if (dest.x != cat.position.x) cat.faceRight = dest.x > cat.position.x;
    cat.play(CatAnim.prowl);
    await _moveTo(cat, dest, 0.3);
    cat.play(CatAnim.eat);
  }

  /// Pops the views of [pieces] off the board, each with a [fx] burst of
  /// [grains] grains unless [burst] is false.
  Future<void> _removeViews(Iterable<ClearedPiece> pieces,
      {BurstFx fx = BurstFx.grain, int grains = 7, bool burst = true}) {
    final pops = <Future<void>>[];
    for (final c in pieces) {
      final v = _views.remove(c.pieceId);
      if (v == null) continue;
      if (identical(_at[c.pos], v)) _at.remove(c.pos);
      if (burst) _fx.burst(v.position, fx: fx, count: grains);
      pops.add(_pop(v));
    }
    return Future.wait(pops);
  }

  /// Moves the views [moves] carry to their new cells and starts [animate]
  /// on each.
  List<Future<void>> _relocate(Iterable<FallMove> moves,
      Future<void> Function(PieceComponent, FallMove) animate) {
    for (final m in moves) {
      _at.remove(m.from);
    }
    final runs = <Future<void>>[];
    for (final m in moves) {
      final v = _views[m.pieceId];
      if (v == null) continue;
      _at[m.to] = v;
      runs.add(animate(v, m));
    }
    return runs;
  }

  Future<void> _swapViews(Pos a, Pos b) async {
    final va = _at[a], vb = _at[b];
    if (va == null || vb == null) return;
    _at[a] = vb;
    _at[b] = va;
    await Future.wait([
      _moveTo(va, _center(b), 0.16),
      _moveTo(vb, _center(a), 0.16),
    ]);
  }
}
