///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsRu with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override String get version => '1.0.0';
	@override late final _Translations$nav$ru nav = _Translations$nav$ru._(_root);
	@override late final _Translations$navShort$ru navShort = _Translations$navShort$ru._(_root);
	@override late final _Translations$devices$ru devices = _Translations$devices$ru._(_root);
	@override late final _Translations$folders$ru folders = _Translations$folders$ru._(_root);
	@override late final _Translations$pair$ru pair = _Translations$pair$ru._(_root);
	@override late final _Translations$activity$ru activity = _Translations$activity$ru._(_root);
	@override late final _Translations$settings$ru settings = _Translations$settings$ru._(_root);
	@override late final _Translations$iceDialog$ru iceDialog = _Translations$iceDialog$ru._(_root);
}

// Path: nav
class _Translations$nav$ru implements Translations$nav$en {
	_Translations$nav$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get devices => 'Устройства';
	@override String get folders => 'Папки';
	@override String get pair => 'Связь';
	@override String get activity => 'Активность';
	@override String get settings => 'Настройки';
}

// Path: navShort
class _Translations$navShort$ru implements Translations$navShort$en {
	_Translations$navShort$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get devices => 'Устр.';
	@override String get folders => 'Папки';
	@override String get pair => 'Связь';
	@override String get activity => 'Статус';
	@override String get settings => 'Настр.';
}

// Path: devices
class _Translations$devices$ru implements Translations$devices$en {
	_Translations$devices$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Связанные устройства';
	@override String get thisDevice => 'Это устройство';
	@override String get online => 'В сети';
	@override String get empty => 'Нет связанных устройств';
	@override String get emptyHint => 'Откройте «Связь», чтобы подключить другое устройство.';
	@override String get errorLoad => 'Не удалось загрузить данные устройства';
	@override String get errorLoadPeers => 'Не удалось загрузить связанные устройства';
	@override String get remove => 'Удалить устройство';
}

// Path: folders
class _Translations$folders$ru implements Translations$folders$en {
	_Translations$folders$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get add => 'Добавить папку';
	@override String get empty => 'Нет общих папок';
	@override String get emptyHint => 'Добавьте папку для синхронизации между устройствами.';
	@override String get errorLoad => 'Не удалось загрузить папки';
	@override String get scanning => 'Сканирование...';
	@override String fileCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		zero: 'Нет файлов',
		one: '{count} файл',
		few: '{count} файла',
		many: '{count} файлов',
		other: '{count} файла',
	);
	@override String get scan => 'Сканировать';
	@override String scanned({required Object count}) => 'Просканировано файлов: {${count}}';
	@override String get alreadyAdded => 'Папка уже добавлена';
	@override String get remove => 'Удалить папку';
}

// Path: pair
class _Translations$pair$ru implements Translations$pair$en {
	_Translations$pair$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get scanHint => 'Отсканируйте этот код на другом устройстве';
	@override String get scanButton => 'Сканировать устройство';
	@override String get scanInstruction => 'Направьте камеру на QR-код другого устройства';
	@override String get toggleFlashlight => 'Включить фонарик';
	@override String get selfPairError => 'Нельзя связать устройство с самим собой';
	@override String paired({required Object name}) => 'Устройство {${name}} связано';
	@override String get invalidQr => 'Этот QR-код не является кодом point-machine';
}

// Path: activity
class _Translations$activity$ru implements Translations$activity$en {
	_Translations$activity$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String syncedToday({required Object bytes}) => 'Синхронизировано сегодня: {${bytes}}';
	@override String get upToDate => 'Все устройства актуальны';
	@override String get empty => 'Ничего не синхронизируется';
	@override String get emptyHint => 'Передачи и конфликты будут отображаться здесь по мере возникновения.';
}

// Path: settings
class _Translations$settings$ru implements Translations$settings$en {
	_Translations$settings$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get appearance => 'Внешний вид';
	@override String get themeSystem => 'Системная';
	@override String get themeLight => 'Светлая';
	@override String get themeDark => 'Тёмная';
	@override String get languageTitle => 'Язык';
	@override String get languageSubtitle => 'Язык интерфейса';
	@override String get discovery => 'Обнаружение';
	@override String get lanTitle => 'Локальная сеть (mDNS)';
	@override String get lanSubtitle => 'Найти устройства в одной сети';
	@override String get dhtTitle => 'Интернет (DHT)';
	@override String get dhtSubtitle => 'Найти устройства через интернет';
	@override String get backgroundTitle => 'Синхронизация в фоне';
	@override String get backgroundSubtitle => 'Продолжать синхронизацию при свернутом приложении';
	@override String get signaling => 'Сигналинг (STUN / TURN)';
	@override String get defaultStun => 'Используется STUN-сервер по умолчанию';
	@override String get addServer => 'Добавить сервер';
}

// Path: iceDialog
class _Translations$iceDialog$ru implements Translations$iceDialog$en {
	_Translations$iceDialog$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'STUN / TURN сервер';
	@override String get url => 'URL';
	@override String get urlHint => 'stun:host:3478';
	@override String get username => 'Имя пользователя (TURN)';
	@override String get credential => 'Пароль (TURN)';
	@override String get cancel => 'Отмена';
	@override String get add => 'Добавить';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'version' => '1.0.0',
			'nav.devices' => 'Устройства',
			'nav.folders' => 'Папки',
			'nav.pair' => 'Связь',
			'nav.activity' => 'Активность',
			'nav.settings' => 'Настройки',
			'navShort.devices' => 'Устр.',
			'navShort.folders' => 'Папки',
			'navShort.pair' => 'Связь',
			'navShort.activity' => 'Статус',
			'navShort.settings' => 'Настр.',
			'devices.title' => 'Связанные устройства',
			'devices.thisDevice' => 'Это устройство',
			'devices.online' => 'В сети',
			'devices.empty' => 'Нет связанных устройств',
			'devices.emptyHint' => 'Откройте «Связь», чтобы подключить другое устройство.',
			'devices.errorLoad' => 'Не удалось загрузить данные устройства',
			'devices.errorLoadPeers' => 'Не удалось загрузить связанные устройства',
			'devices.remove' => 'Удалить устройство',
			'folders.add' => 'Добавить папку',
			'folders.empty' => 'Нет общих папок',
			'folders.emptyHint' => 'Добавьте папку для синхронизации между устройствами.',
			'folders.errorLoad' => 'Не удалось загрузить папки',
			'folders.scanning' => 'Сканирование...',
			'folders.fileCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, zero: 'Нет файлов', one: '{count} файл', few: '{count} файла', many: '{count} файлов', other: '{count} файла', ), 
			'folders.scan' => 'Сканировать',
			'folders.scanned' => ({required Object count}) => 'Просканировано файлов: {${count}}',
			'folders.alreadyAdded' => 'Папка уже добавлена',
			'folders.remove' => 'Удалить папку',
			'pair.scanHint' => 'Отсканируйте этот код на другом устройстве',
			'pair.scanButton' => 'Сканировать устройство',
			'pair.scanInstruction' => 'Направьте камеру на QR-код другого устройства',
			'pair.toggleFlashlight' => 'Включить фонарик',
			'pair.selfPairError' => 'Нельзя связать устройство с самим собой',
			'pair.paired' => ({required Object name}) => 'Устройство {${name}} связано',
			'pair.invalidQr' => 'Этот QR-код не является кодом point-machine',
			'activity.syncedToday' => ({required Object bytes}) => 'Синхронизировано сегодня: {${bytes}}',
			'activity.upToDate' => 'Все устройства актуальны',
			'activity.empty' => 'Ничего не синхронизируется',
			'activity.emptyHint' => 'Передачи и конфликты будут отображаться здесь по мере возникновения.',
			'settings.appearance' => 'Внешний вид',
			'settings.themeSystem' => 'Системная',
			'settings.themeLight' => 'Светлая',
			'settings.themeDark' => 'Тёмная',
			'settings.languageTitle' => 'Язык',
			'settings.languageSubtitle' => 'Язык интерфейса',
			'settings.discovery' => 'Обнаружение',
			'settings.lanTitle' => 'Локальная сеть (mDNS)',
			'settings.lanSubtitle' => 'Найти устройства в одной сети',
			'settings.dhtTitle' => 'Интернет (DHT)',
			'settings.dhtSubtitle' => 'Найти устройства через интернет',
			'settings.backgroundTitle' => 'Синхронизация в фоне',
			'settings.backgroundSubtitle' => 'Продолжать синхронизацию при свернутом приложении',
			'settings.signaling' => 'Сигналинг (STUN / TURN)',
			'settings.defaultStun' => 'Используется STUN-сервер по умолчанию',
			'settings.addServer' => 'Добавить сервер',
			'iceDialog.title' => 'STUN / TURN сервер',
			'iceDialog.url' => 'URL',
			'iceDialog.urlHint' => 'stun:host:3478',
			'iceDialog.username' => 'Имя пользователя (TURN)',
			'iceDialog.credential' => 'Пароль (TURN)',
			'iceDialog.cancel' => 'Отмена',
			'iceDialog.add' => 'Добавить',
			_ => null,
		};
	}
}
