import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load resolves accessors for every supported locale', () async {
    expect(AppLocalizations.delegate.supportedLocales, hasLength(8));
    for (final locale in AppLocalizations.delegate.supportedLocales) {
      final appLocalizations = await AppLocalizations.load(locale);

      expect(AppLocalizations.current, same(appLocalizations));
      expect(appLocalizations.dashboard, isNotEmpty);
      expect(appLocalizations.proxies, isNotEmpty);
      expect(appLocalizations.settings, isNotEmpty);
      expect(appLocalizations.zhTW, isNotEmpty);
      expect(appLocalizations.youkomixErrNetworkUnreachable, isNotEmpty);
      expect(appLocalizations.secondsCount(30), contains('30'));
      expect(appLocalizations.geoUpdated('geoip'), contains('geoip'));
    }
  });

  test('delegate recognizes only supported locales', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
    expect(
      AppLocalizations.delegate.isSupported(const Locale('zh', 'TW')),
      isTrue,
    );
    expect(AppLocalizations.delegate.isSupported(const Locale('de')), isFalse);
    expect(
      AppLocalizations.delegate.shouldReload(AppLocalizations.delegate),
      isFalse,
    );
  });

  test(
    'resolveEffectiveAppLocale matches system locale and falls back to zh_CN',
    () {
      expect(
        resolveEffectiveAppLocale(null, const [Locale('zh', 'HK')]),
        const Locale('zh', 'TW'),
      );
      expect(
        resolveEffectiveAppLocale(null, const [Locale('ja', 'JP')]),
        const Locale('ja'),
      );
      expect(
        resolveEffectiveAppLocale(null, const [Locale('en', 'US')]),
        const Locale('en'),
      );
      expect(
        resolveEffectiveAppLocale(null, const [Locale('de', 'DE')]),
        const Locale('zh', 'CN'),
      );
      expect(
        resolveEffectiveAppLocale(null, const []),
        const Locale('zh', 'CN'),
      );
      expect(
        resolveEffectiveAppLocale('zh_TW', const [Locale('en', 'US')]),
        const Locale('zh', 'TW'),
      );
    },
  );
}
