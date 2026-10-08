import '../gen/assets.gen.dart';
import 'l10n.dart';

/// Animations every customer sprite has (see `docs/prompts/README.md`).
enum CustomerAnim {
  idle(4),
  talk(6),
  happy(6),
  sad(4),
  walk(6),

  /// The customer's own flourish; its file name, speed and trigger come from
  /// [Customer.signature].
  signature(8);

  const CustomerAnim(this.fps);

  /// Playback speed; the calm loops run slower so the diner doesn't fidget.
  final double fps;
}

/// What makes a customer play their [Signature] animation.
enum SignatureCue {
  /// The order bubble settles in at the start of the level.
  start,

  /// The order is served (level won).
  served,

  /// Three moves or fewer left.
  lowMoves,

  /// A combo praise pops up.
  combo,

  /// One of the level's goals was just completed.
  goal,

  /// Every few moves, as a break from standing still.
  idle,
}

/// A customer's own animation (`<name>_0..3`), from `docs/prompts`.
class Signature {
  const Signature(this.name, this.cue, {this.fps = 8, this.loop = false});
  final String name;
  final SignatureCue cue;
  final double fps;

  /// Loops play twice, the rest once.
  final bool loop;

  int get loops => loop ? 2 : 1;
}

/// A diner who places the level's goals as a food order.
class Customer {
  Customer(this.nameKey, {this.art, this.signature});
  final String nameKey;

  /// The extra animation beyond [CustomerAnim]'s shared ones; null for none.
  final Signature? signature;

  /// Every frame in the customer's sprite folder
  /// (`Assets.sprites.customers.<folder>.values`); null until the art exists,
  /// in which case nothing is drawn.
  final List<AssetGenImage>? art;

  bool get hasSprite => art != null;

  /// The frames by `<anim>_<i>`, whatever the image format.
  late final Map<String, AssetGenImage> _frames = {
    for (final a in art!) a.path.split('/').last.split('.').first: a,
  };

  /// Frames per animation.
  static const frameCount = 4;

  String get name => L10n.t(nameKey);

  AssetGenImage frame(CustomerAnim anim, int i) {
    final name = anim == CustomerAnim.signature ? signature!.name : anim.name;
    return _frames['${name}_$i']!;
  }

  /// Playback speed of [anim] for this customer.
  double fpsOf(CustomerAnim anim) =>
      anim == CustomerAnim.signature && signature != null
          ? signature!.fps
          : anim.fps;

  static final roster = [
    Customer('cust0',
        art: Assets.sprites.customers.a00GrannySakura.values,
        signature: const Signature('bow', SignatureCue.start)),
    Customer('cust1',
        art: Assets.sprites.customers.a01MrTanaka.values,
        signature: const Signature('watch', SignatureCue.lowMoves, loop: true)),
    Customer('cust2',
        art: Assets.sprites.customers.a02LittleMei.values,
        signature:
            const Signature('clap', SignatureCue.combo, fps: 10, loop: true)),
    Customer('cust3',
        art: Assets.sprites.customers.a03LuckyCat.values,
        signature:
            const Signature('beckon', SignatureCue.start, fps: 6, loop: true)),
    Customer('cust4',
        art: Assets.sprites.customers.a04Yuki.values,
        signature: const Signature('photo', SignatureCue.served)),
    Customer('cust5',
        art: Assets.sprites.customers.a05GrandpaTaro.values,
        signature: const Signature('nod', SignatureCue.goal, fps: 6)),
    Customer('cust6',
        art: Assets.sprites.customers.a06Ryo.values,
        signature: const Signature('carry', SignatureCue.start)),
    Customer('cust7',
        art: Assets.sprites.customers.a07AuntieKiku.values,
        signature: const Signature('inspect', SignatureCue.start)),
    Customer('cust8',
        art: Assets.sprites.customers.a08Masa.values,
        signature: const Signature('auction', SignatureCue.lowMoves, fps: 10)),
    Customer('cust9',
        art: Assets.sprites.customers.a09TacoNeesan.values,
        signature:
            const Signature('flip', SignatureCue.idle, fps: 10, loop: true)),
    Customer('cust10',
        art: Assets.sprites.customers.a10Oto.values,
        signature:
            const Signature('drum', SignatureCue.combo, fps: 10, loop: true)),
    Customer('cust11',
        art: Assets.sprites.customers.a11AuntHana.values,
        signature: const Signature('bargain', SignatureCue.start)),
    Customer('cust12',
        art: Assets.sprites.customers.a12Ume.values,
        signature: const Signature('fan', SignatureCue.start)),
    Customer('cust13',
        art: Assets.sprites.customers.a13Haru.values,
        signature: const Signature('tea', SignatureCue.start, fps: 6)),
    Customer('cust14',
        art: Assets.sprites.customers.a14MonkGenjo.values,
        signature:
            const Signature('meditate', SignatureCue.idle, fps: 4, loop: true)),
    Customer('cust15',
        art: Assets.sprites.customers.a15CaptainUmi.values,
        signature: const Signature('tale', SignatureCue.start)),
    Customer('cust16',
        art: Assets.sprites.customers.a16Yukiko.values,
        signature: const Signature('stretch', SignatureCue.start)),
    Customer('cust17',
        art: Assets.sprites.customers.a17ChefKuma.values,
        signature: const Signature('taste', SignatureCue.served, fps: 6)),
  ];

  /// Customers take turns across levels so every plate has a face.
  static Customer forLevel(int levelId) =>
      roster[(levelId - 1) % roster.length];
}
