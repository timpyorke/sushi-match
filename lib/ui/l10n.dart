import 'l10n/strings_en.dart';
import 'l10n/strings_th.dart';

/// Minimal two-language string table (GDD: Thai + English from launch).
/// `{name}` placeholders are filled from [args].
abstract final class L10n {
  static const languages = {'en': 'English', 'th': 'ไทย'};

  /// Current language code; kept in step with the settings by their notifier.
  static String language = 'en';

  static String t(String key, [Map<String, Object> args = const {}]) {
    final table = _strings[language] ?? _strings['en']!;
    var s = table[key] ?? _strings['en']![key] ?? key;
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  static const _strings = <String, Map<String, String>>{
    'en': stringsEn,
    'th': stringsTh,
  };
}
