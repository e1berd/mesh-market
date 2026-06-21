import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:point_machine/i18n/strings.g.dart';
import 'package:point_machine/state/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads saved locale before the app starts', () async {
    SharedPreferences.setMockInitialValues({
      'app_config': jsonEncode({'localeCode': 'ru'}),
    });
    LocaleSettings.setLocaleRawSync('en');

    final config = await loadInitialConfig();

    expect(config.localeCode, 'ru');
    expect(LocaleSettings.currentLocale, AppLocale.ru);
  });
}
