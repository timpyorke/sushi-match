// ignore_for_file: avoid_print
// Writes the GPT Image prompt pack for every character in docs/Charecter.md to
// docs/prompts/: one file per character plus README.md. The markdown is
// generated, so change the style or a character here and re-run.
//
//   dart run tool/gen_prompts.dart
import 'dart:io';

part 'prompts/characters.dart';

const _outDir = 'docs/prompts';

const _style =
    'Japanese anime-style chibi (SD, super-deformed) mobile-game character '
    'sprite, like a cosy slice-of-life anime game. Drawn by hand by a '
    'professional 2D anime game illustrator: flat cel colours with one crisp '
    'hard-edged shadow tone, thick dark-brown outline (#4A2A1A) with slight '
    'natural line-weight variation (thicker on the outer silhouette and under '
    'shapes, thinner on inner details), one small flat white highlight per '
    'shiny surface, limited warm Japanese-restaurant palette, chibi '
    'proportions (head about half of total height). Big expressive anime eyes '
    'with a flat-colour iris, one darker band at the top and two white '
    'catch-lights, both eyes matching in size and shape (unless the eyes are '
    'described otherwise below), tiny simple nose, small expressive mouth, '
    'anime blush on the cheeks (soft pink ovals with fine diagonal lines). '
    'Hair drawn as a few clean anime locks with one flat shine band. Simple '
    'chibi hands with clearly separated fingers. Animals are anime mascot '
    'characters with the same eyes and blush. Use anime emotion symbols '
    '(sweat drops, sparkles, anger marks, ^^ eyes) only where a frame asks '
    'for them. Few, deliberate details: every prop and accessory clearly '
    'shaped and readable, nothing extra beyond the description. Avoid the '
    'typical AI-art look: no airbrushed or soft gradient shading, no plastic '
    'or 3D-render sheen, no over-smoothed skin, no random extra sparkles or '
    'particles, no melted or merged details, no extra or fused fingers, no '
    'blurry edges. No texture noise, no text, no logo, no watermark, no '
    'ground shadow, no glow, no aura, fully transparent background. Outline '
    'weight matches a cartoon salmon-nigiri game icon.';

const _sameAsRef = 'Use the character in the reference image exactly: same '
    'face, hair, outfit, props, colours, outline and art style.';

class Anim {
  const Anim(this.name, this.use, this.playback, this.title, this.frames,
      {this.grounded = true, this.extra});

  /// File prefix: assets/sprites/customers/<id>/<name>_<n>.png.
  final String name;
  final String use;
  final String playback;

  /// What the sheet shows, including the view.
  final String title;
  final List<String> frames;

  /// Whether every frame stands on the same ground line (false for hops).
  final bool grounded;
  final String? extra;
}

class Character {
  const Character({
    required this.file,
    required this.en,
    required this.th,
    required this.role,
    required this.looks,
    required this.personality,
    required this.palette,
    required this.pose,
    required this.props,
    this.signature,
    this.gait,
    this.talk,
    this.happy,
    this.sad,
    this.blink = 'eyes blinking, fully closed',
    this.walk,
    this.anims,
    this.folder = 'customers',
  });

  /// `NN-name`: the doc file, the asset folder and the master image name.
  /// Numbers follow docs/Charecter.md; append new characters at the end.
  final String file;
  final String en;
  final String th;
  final String role;
  final String looks;
  final String personality;
  final Map<String, String> palette;

  /// Rest pose, used by the master image, idle and talk.
  final String pose;

  /// Separate pieces for the cut-out parts sheet besides head, body and limbs.
  final List<String> props;
  final Anim? signature;
  final String? gait;
  final String? talk;
  final List<String>? happy;
  final List<String>? sad;
  final String blink;
  final List<String>? walk;

  /// Replaces the standard customer set (idle, talk, happy, sad, walk).
  final List<Anim>? anims;

  /// Folder under assets/sprites/ for the frames.
  final String folder;

  List<Anim> get allAnims =>
      anims ?? [..._customerAnims(this), if (signature != null) signature!];
}

List<Anim> _customerAnims(Character c) => [
      Anim('idle', 'while the level is playing', 'loop at 4 fps',
          'Idle breathing loop, front three-quarter view', [
        'neutral, ${c.pose}, gentle expression.',
        'body rises very slightly, shoulders up a little.',
        'same as f1.',
        'same as f1 but ${c.blink}.',
      ]),
      Anim('talk', 'when the order bubble appears', 'loop at 8 fps',
          'Talking loop, front three-quarter view', [
        'mouth closed in a soft expression, ${c.pose}.',
        'mouth small and open in an "o" shape.',
        'mouth open wider, ${c.talk}.',
        'mouth half open, returning to the rest pose.',
      ]),
      Anim('happy', 'goals complete', 'play once at 10 fps and hold f4',
          'Happy reaction, front three-quarter view', c.happy!,
          grounded: false),
      Anim(
          'sad',
          'level failed',
          'play once at 6 fps and hold f4',
          'Sad reaction, front three-quarter view, still cute and gentle '
              '(disappointed, not crying hard)',
          c.sad!),
      Anim(
          'walk',
          'customer enters or leaves',
          'loop at 8 fps (flip horizontally to walk right)',
          'Side-view walk cycle facing left, ${c.gait}',
          c.walk ??
              [
                'contact pose, left foot forward.',
                'passing pose, feet together, body slightly higher.',
                'contact pose, right foot forward.',
                'passing pose, feet together, body slightly higher.',
              ]),
    ];

String _block(String text) => '```text\n$text\n```\n';

String _master(Character c) => '$_style\n\n'
    'Character: ${c.en}, ${c.looks} ${c.personality}\n\n'
    'Single full-body character, front three-quarter view facing slightly '
    'left, ${c.pose}, centered with about 10% empty margin on every side.';

String _bust(Character c) => '$_style\n\n'
    'Character: ${c.en}, ${c.looks}\n\n'
    'Head-and-shoulders bust portrait, front view, centered, fits inside a '
    'circle with a small margin. Big readable shapes that still read clearly '
    'at 48 pixels.';

String _sheet(Anim a) {
  final grounded = a.grounded
      ? ', standing on the same ground line'
      : '; the ground line may change only for hops and leaps';
  const cells = ['top-left', 'top-right', 'bottom-left', 'bottom-right'];
  final frames = [
    for (var i = 0; i < 4; i++) 'f${i + 1} (${cells[i]}): ${a.frames[i]}'
  ].join('\n');
  return '$_sameAsRef\n\n'
      'Sprite sheet: 2x2 grid of 4 equal 512x512 cells, one frame per cell, '
      'no borders, no grid lines, no numbers, no glow or aura around the '
      'character, fully transparent background. '
      'The character has the exact same size and scale in every cell, '
      'centered horizontally$grounded. Only the pose changes between '
      'frames.\n\n'
      '${a.title}:\n$frames${a.extra == null ? '' : '\n${a.extra}'}';
}

String _parts(Character c) {
  final parts = [
    'head with hair and headwear, no eyes and no mouth',
    'body with outfit, no arms and no head',
    'left arm, right arm',
    'left foot, right foot',
    ...c.props,
    'three anime eye pairs: happy ^^ arcs, closed lines, sad teary eyes with '
        'tilted brows',
    'three mouths: soft smile, open "o", small frown',
  ].map((p) => '- $p').join('\n');
  return '$_sameAsRef\n\n'
      'Character parts sheet for 2D cut-out animation, front view, every part '
      'at the same scale, separated by generous empty space, no labels, fully '
      'transparent background:\n$parts';
}

String _characterDoc(Character c) {
  final b = StringBuffer()
    ..writeln('# GPT Image prompts: ${c.en}')
    ..writeln()
    ..writeln('<!-- Generated by tool/gen_prompts.dart. Edit that file and '
        're-run instead of editing this one. -->')
    ..writeln()
    ..writeln('**${c.th} / ${c.en}** · ${c.role}. See `docs/Charecter.md` '
        'for the full profile and [README.md](README.md) for how to use '
        'these prompts.')
    ..writeln()
    ..writeln('- Personality: ${c.personality}')
    ..writeln('- Colours: ${c.palette.entries.map((e) => '${e.key} '
        '`${e.value}`').join(', ')}, outline `#4A2A1A`')
    ..writeln('- Frames go in `assets/sprites/${c.folder}/${c.file}/'
        '<anim>_<n>.png`')
    ..writeln()
    ..writeln('## 1. Master reference')
    ..writeln()
    ..writeln('Text → image. Keep the best result as `${c.file}_master.png`.')
    ..writeln()
    ..write(_block(_master(c)))
    ..writeln()
    ..writeln('### Bust portrait')
    ..writeln()
    ..writeln('For the order bubble and small UI spots.')
    ..writeln()
    ..write(_block(_bust(c)))
    ..writeln()
    ..writeln('## 2. Animation sheets')
    ..writeln()
    ..writeln('Edit endpoint, with `${c.file}_master.png` as the input '
        'image.');
  for (final a in c.allAnims) {
    b
      ..writeln()
      ..writeln('### ${a.name}: ${a.use} · ${a.playback}')
      ..writeln()
      ..write(_block(_sheet(a)));
  }
  b
    ..writeln()
    ..writeln('## 3. Alternative: parts sheet for animation in code')
    ..writeln()
    ..writeln('If the frames come out inconsistent, generate the parts and '
        'animate them in Flutter/Flame with rotation, translation and '
        'squash.')
    ..writeln()
    ..write(_block(_parts(c)));
  return b.toString();
}

String _readme() {
  final b = StringBuffer()
    ..writeln('# GPT Image prompts: characters')
    ..writeln()
    ..writeln('<!-- Generated by tool/gen_prompts.dart. Edit that file and '
        're-run instead of editing this one. -->')
    ..writeln()
    ..writeln('Ready-to-paste prompts for every character in '
        '`docs/Charecter.md`, in a Japanese anime chibi style whose outline and '
        'gloss match `assets/sprites/sushi/*.png`. To change the style or a character, '
        'edit `tool/gen_prompts.dart` and run:')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart run tool/gen_prompts.dart')
    ..writeln('```')
    ..writeln()
    ..writeln('Prompts for the board tiles and the level map are in '
        '[tiles/README.md](tiles/README.md), the icons that replace the '
        'emoji in [icons/README.md](icons/README.md).')
    ..writeln()
    ..writeln('## How to use')
    ..writeln()
    ..writeln('- Model `gpt-image-1` with `size: 1024x1024`, `background: '
        'transparent`, `output_format: png` and `quality: high`.')
    ..writeln('- **Step 1.** Generate the master reference a few times and '
        'keep the best one as `<id>_master.png` (`<id>` is the character file name, '
        'such as `00-granny-sakura`).')
    ..writeln('- **Step 2.** Generate each animation sheet with the **Edit** '
        'endpoint (image → image), passing the master as the input image so '
        'the face and outfit stay the same in every frame.')
    ..writeln('- Every sheet is a **2×2 grid of 4 frames, 512×512 each**, '
        'read left→right, top→bottom (f1 f2 / f3 f4).')
    ..writeln('- Save the master and sheets in '
        '`assets/sprites/customers/<id>/source/` as `<id>_master.png` and '
        '`<anim>_sheet.png`, then cut them into 256px frames, the same size '
        'as the sushi sprites:')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart run tool/cut_sprites.dart <id>')
    ..writeln('```')
    ..writeln()
    ..writeln('- The frames land next to `source/` as `<anim>_<n>.png` (for '
        'example `00-granny-sakura/idle_0.png`), keeping the art\'s '
        'proportions, lined up on the feet and without any faint aura. Add '
        'the folder to `pubspec.yaml` and set `sprite:` on the customer in '
        '`lib/ui/customer_order.dart`. The boss cat goes in '
        '`assets/sprites/obstacles/` instead.')
    ..writeln('- If the frames of a sheet don\'t match each other, use the '
        'parts sheet at the end of each file and animate in code instead.')
    ..writeln()
    ..writeln('Customers get idle, talk, happy, sad and walk, plus one '
        'signature move. The boss cat gets the board animations from '
        '`docs/Charecter.md`: idle, prowl, eat, hit and flee.')
    ..writeln()
    ..writeln('## Characters')
    ..writeln()
    ..writeln('| Character | Role | Animations |')
    ..writeln('| --------- | ---- | ---------- |');
  for (final c in _characters) {
    final anims = c.allAnims.map((a) => a.name).toSet().join(', ');
    b.writeln('| [${c.en}](${c.file}.md) (${c.th}) | ${c.role} | $anims |');
  }
  b
    ..writeln()
    ..writeln('## Quality checklist')
    ..writeln()
    ..writeln('- [ ] The background is really transparent, with no white halo '
        'around the outline. If there is one, add "no white outline around '
        'the silhouette" to the prompt and run it again.')
    ..writeln('- [ ] All 4 frames in a sheet have the same size and ground '
        'line (except hops). If not, run it again and stress "exact same '
        'size and scale".')
    ..writeln('- [ ] It reads as Japanese anime: big anime eyes with '
        'catch-lights, crisp cel shading, blush lines, anime hair locks. If '
        'it looks like a western cartoon, run it again.')
    ..writeln('- [ ] It does not look AI-generated: hands have the right '
        'fingers, both eyes match, props and accessories are clean and '
        'complete (no melted straps, buttons or patterns), shading is flat cel '
        'with no airbrushed gradients or plastic sheen, and there are no '
        'stray sparkles or random details. Fix small slips by hand in an '
        'image editor rather than re-rolling a sheet that is otherwise good.')
    ..writeln('- [ ] The character is recognisable at 64px from the '
        'silhouette alone.')
    ..writeln('- [ ] The colours match the hex codes listed in the '
        'character\'s file across all sheets.')
    ..writeln('- [ ] The character sits well next to '
        '`assets/sprites/sushi/salmon.png` (outline weight, shading, '
        'highlights).');
  return b.toString();
}

void main() {
  Directory(_outDir).createSync(recursive: true);
  for (final c in _characters) {
    File('$_outDir/${c.file}.md').writeAsStringSync(_characterDoc(c));
  }
  File('$_outDir/README.md').writeAsStringSync(_readme());
  print('Wrote ${_characters.length} character files and README.md to '
      '$_outDir/');
}
