// ignore_for_file: avoid_print
// Writes the GPT Image prompt pack for the icons that replace the emoji in
// the UI to docs/prompts/icons/: obstacle and goal icons, restaurant icons,
// restaurant furniture and a few UI icons, plus README.md. The markdown is
// generated, so change the style or an icon here and re-run.
//
//   dart run tool/gen_icon_prompts.dart
import 'dart:io';

part 'prompts/icons.dart';

const _outDir = 'docs/prompts/icons';

const _style =
    'Japanese anime-style chibi mobile-game icon, like the item icons of a '
    'cosy slice-of-life anime puzzle game. Drawn by hand by a professional '
    '2D game icon artist: flat cel colours with one crisp hard-edged shadow '
    'tone, thick dark-brown outline (#4A2A1A) round the whole silhouette with '
    'slight natural line-weight variation (thicker outside, thinner on inner '
    'details), one or two small flat white highlights on shiny surfaces, '
    'chunky rounded toy-like shapes, bold simple silhouette, limited warm '
    'Japanese palette, light from the top-left. Few, deliberate details: '
    'every icon reads at 24 pixels from its silhouette and main colour alone. '
    'Avoid the typical AI-art look: no airbrushed or soft gradient shading, '
    'no plastic or 3D-render sheen, no photographic texture, no texture '
    'noise, no random extra sparkles or particles, no melted or merged '
    'details, no blurry edges. No people unless asked, no text, no letters, '
    'no numbers, no logo, no watermark, no ground shadow, no glow, no aura. '
    'Outline weight matches a cartoon salmon-nigiri game icon.';

String _sameAsRef(String ref) =>
    'Use the reference image ($ref) only for style and palette: same outline '
    'weight, cel shading, highlights and level of detail. Draw the new items '
    'described below.';

class Icon {
  const Icon(this.file, this.emoji, this.desc);
  final String file;

  /// The emoji this icon replaces.
  final String emoji;
  final String desc;
}

/// A 2x2 sheet of up to four 512px cells; empty cells stay transparent.
class Sheet {
  const Sheet({required this.name, required this.title, required this.icons});

  /// Saved as `source/<name>_sheet.png`.
  final String name;
  final String title;
  final List<Icon> icons;
}

class Doc {
  const Doc({
    required this.file,
    required this.title,
    required this.intro,
    required this.folder,
    required this.out,
    required this.styleRef,
    required this.theme,
    required this.view,
    required this.sheets,
    required this.wiring,
    this.palette = const {},
  });

  /// Markdown file name without extension.
  final String file;
  final String title;
  final String intro;

  /// Asset folder the cut icons go to; sheets go to `<folder>/source/`.
  final String folder;

  /// Final icon size in pixels (square).
  final int out;

  /// Existing asset passed with the first sheet so the set matches the game.
  final String styleRef;

  /// Setting line shared by every prompt of this file.
  final String theme;
  final String view;
  final List<Sheet> sheets;

  /// Where the icons go in code once they exist.
  final String wiring;
  final Map<String, String> palette;
}

// ---------------------------------------------------------------------------
// Markdown.

String _block(String lang, String text) => '```$lang\n$text\n```\n';

const _cellNames = ['top-left', 'top-right', 'bottom-left', 'bottom-right'];

/// The image the Edit endpoint gets for sheet [i] of [d].
String _ref(Doc d, int i) =>
    i == 0 ? d.styleRef : '${d.folder}/source/${d.sheets.first.name}_sheet.png';

String _sheetPrompt(Doc d, int i) {
  final s = d.sheets[i];
  final n = s.icons.length;
  final rules = [
    'Icon sheet: 2x2 grid of 4 equal 512x512 cells, one icon per cell, no '
        'borders, no grid lines, no gutters, no labels, no numbers.',
    d.view,
    'Every icon at the same scale with the same outline weight, centred '
        'with about 10% empty margin.',
    if (n < 4)
      'Only the first $n cells hold an icon; the other '
          '${n == 3 ? 'cell stays' : 'cells stay'} empty.',
    'Everything outside the icons is fully transparent.',
  ];
  final cells = [
    for (var c = 0; c < n; c++)
      'f${c + 1} (${_cellNames[c]}) ${s.icons[c].file}: ${s.icons[c].desc}'
  ].join('\n');
  return [
    _style,
    _sameAsRef(_ref(d, i)),
    d.theme,
    rules.join(' '),
    '${s.title}:\n$cells',
  ].join('\n\n');
}

String _cutCommands(Doc d, Sheet s) {
  final src = '${d.folder}/source/${s.name}_sheet.png';
  final n = d.out;
  return [
    for (var i = 0; i < s.icons.length; i++)
      'magick $src -resize 1024x1024! '
          '-crop 512x512+${(i % 2) * 512}+${(i ~/ 2) * 512} +repage '
          '-trim +repage -resize ${n}x$n -background none -gravity center '
          '-extent ${n}x$n ${d.folder}/${s.icons[i].file}.png',
  ].join('\n');
}

String _doc(Doc d) {
  final b = StringBuffer()
    ..writeln('# GPT Image prompts: ${d.title}')
    ..writeln()
    ..writeln('<!-- Generated by tool/gen_icon_prompts.dart. Edit that file '
        'and re-run instead of editing this one. -->')
    ..writeln()
    ..writeln(d.intro)
    ..writeln()
    ..writeln('- Sheets go in `${d.folder}/source/`; cut icons are '
        '${d.out}×${d.out} px in `${d.folder}/`. See [README.md](README.md) '
        'for settings.')
    ..writeln('- Wiring: ${d.wiring}');
  if (d.palette.isNotEmpty) {
    b.writeln('- Colours: ${d.palette.entries.map((e) => '${e.key} '
        '`${e.value}`').join(', ')}, outline `#4A2A1A`');
  }
  for (var i = 0; i < d.sheets.length; i++) {
    final s = d.sheets[i];
    b
      ..writeln()
      ..writeln('## ${i + 1}. ${s.title}')
      ..writeln()
      ..writeln('Edit endpoint with `${_ref(d, i)}` as the input image · '
          '`size: 1024x1024` · `background: transparent` · save as '
          '`${s.name}_sheet.png`.')
      ..writeln()
      ..writeln('| Cell | File | Replaces |')
      ..writeln('| ---- | ---- | -------- |');
    for (var c = 0; c < s.icons.length; c++) {
      final icon = s.icons[c];
      b.writeln('| f${c + 1} ${_cellNames[c]} | `${icon.file}.png` | '
          '${icon.emoji} |');
    }
    b
      ..writeln()
      ..write(_block('text', _sheetPrompt(d, i)))
      ..writeln()
      ..writeln('Cut:')
      ..writeln()
      ..write(_block('bash', _cutCommands(d, s)));
  }
  return b.toString();
}

String _readme(List<Doc> docs) {
  final b = StringBuffer()
    ..writeln('# GPT Image prompts: icons')
    ..writeln()
    ..writeln('<!-- Generated by tool/gen_icon_prompts.dart. Edit that file '
        'and re-run instead of editing this one. -->')
    ..writeln()
    ..writeln('Ready-to-paste prompts for the icons that replace the emoji '
        'still used in the UI: obstacle and goal icons, restaurant icons, '
        'restaurant furniture and a few dialog icons. The style matches the '
        'booster icons and the [board tiles](../tiles/README.md). To change '
        'the style or an icon, edit `tool/gen_icon_prompts.dart` and run:')
    ..writeln()
    ..writeln('```bash')
    ..writeln('dart run tool/gen_icon_prompts.dart')
    ..writeln('```')
    ..writeln()
    ..writeln('## How to use')
    ..writeln()
    ..writeln('- Model `gpt-image-1`, `size: 1024x1024`, '
        '`background: transparent`, `quality: high`, `output_format: png`.')
    ..writeln('- Every file is made of **2×2 sheets of four 512×512 cells**, '
        'read left→right, top→bottom (f1 f2 / f3 f4). Each cell becomes one '
        'icon; a sheet with fewer icons leaves the last cells empty.')
    ..writeln('- Use the **Edit** endpoint for every sheet. The first sheet '
        'of a file gets an existing game asset as the input image so the set '
        'matches the game; generate it a few times and keep the best. Every '
        'later sheet in the file gets that first sheet, so the set shares '
        'one palette and outline.')
    ..writeln('- Save sheets in `<folder>/source/` under the name the section '
        'gives, then run its **Cut** commands (ImageMagick). Each icon is '
        'trimmed to its outline, scaled to fit and centred on a square '
        'transparent canvas.')
    ..writeln('- Add new folders to `pubspec.yaml` and swap the emoji for '
        '`Image.asset` where each file\'s **Wiring** line says.')
    ..writeln()
    ..writeln('## Files')
    ..writeln()
    ..writeln('| File | Folder | Size | Icons |')
    ..writeln('| ---- | ------ | ---- | ----- |');
  for (final d in docs) {
    final icons = [
      for (final s in d.sheets)
        for (final i in s.icons) '${i.emoji} ${i.file}',
    ];
    final title = '${d.title[0].toUpperCase()}${d.title.substring(1)}';
    b.writeln('| [$title](${d.file}.md) | `${d.folder}` | ${d.out} px | '
        '${icons.join(', ')} |');
  }
  b
    ..writeln()
    ..writeln('## Quality checklist')
    ..writeln()
    ..writeln('- [ ] Every icon reads at 24 px: shrink the cut file and check '
        'the silhouette and main colour alone tell what it is.')
    ..writeln('- [ ] Obstacle icons match their board tiles in '
        '[../tiles/board.md](../tiles/board.md) (colours, shapes).')
    ..writeln('- [ ] Restaurant icons stand out on their banner colour and '
        'keep the thin white outer rim.')
    ..writeln('- [ ] Transparent sheets have no white halo or leftover '
        'background between icons, and empty cells are really empty.')
    ..writeln('- [ ] It reads as anime chibi: flat cel shading, dark-brown '
        'outline, rounded toy-like shapes. No airbrush gradients, 3D sheen, '
        'photo texture, text or stray sparkles.')
    ..writeln('- [ ] Icons sit well next to `assets/sprites/boosters/*.png` '
        'and `assets/ui/heart.png` (outline weight, shading).');
  return b.toString();
}

void main() {
  final docs = [_obstacles, _shops, _furniture, _ui];
  Directory(_outDir).createSync(recursive: true);
  for (final d in docs) {
    File('$_outDir/${d.file}.md').writeAsStringSync(_doc(d));
  }
  File('$_outDir/README.md').writeAsStringSync(_readme(docs));
  final n = docs.fold<int>(
      0, (n, d) => n + d.sheets.fold<int>(0, (n, s) => n + s.icons.length));
  print('Wrote ${docs.length} icon files ($n icons) and README.md to '
      '$_outDir/');
}
