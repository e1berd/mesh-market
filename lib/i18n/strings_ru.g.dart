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
	@override late final _Translations$share$ru share = _Translations$share$ru._(_root);
	@override late final _Translations$activity$ru activity = _Translations$activity$ru._(_root);
	@override late final _Translations$schedule$ru schedule = _Translations$schedule$ru._(_root);
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
	@override String get offline => 'Не в сети';
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
	@override String get storageDenied => 'Для синхронизации нужен доступ к хранилищу';
	@override String get manageAccess => 'Управление доступом';
	@override String get access => 'Доступ устройств';
	@override String get localFolder => 'Локальная папка';
	@override String get localAvailable => 'Доступна';
	@override String get localMissing => 'Папка не найдена';
	@override String get noPeers => 'Свяжите устройство, чтобы делиться с ним папкой';
	@override String get empty => 'Нет общих папок';
	@override String get emptyHint => 'Добавьте папку для синхронизации между устройствами.';
	@override String get errorLoad => 'Не удалось загрузить папки';
	@override String get scanning => 'Сканирование...';
	@override String folderSize({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n,
		zero: 'Пусто',
		one: '${size}',
		few: '${size}',
		many: '${size}',
		other: '${size}',
	);
	@override String get scan => 'Сканировать';
	@override String scanned({required Object count}) => 'Просканировано файлов: ${count}';
	@override String get alreadyAdded => 'Папка уже добавлена';
	@override String get openFolder => 'Открыть папку';
	@override String get openFailed => 'Не удалось открыть папку';
	@override String get remove => 'Удалить папку';
	@override String get sendFiles => 'Отправлять файлы';
	@override String get receiveFiles => 'Получать файлы';
	@override String get remoteMissing => 'Нет на удалённом устройстве';
	@override String get remoteAvailable => 'Доступна на удалённом';
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
	@override String paired({required Object name}) => 'Устройство ${name} связано';
	@override String get invalidQr => 'Этот QR-код не является кодом Mesh Market';
	@override String get nearbyTitle => 'Устройства рядом';
	@override String get nearbySearching => 'Поиск устройств в вашей сети…';
	@override String get pairAction => 'Связать';
	@override String get manualTitle => 'Ввести код вручную';
	@override String get manualHint => 'Вставьте код устройства';
	@override String get pairing => 'Связывание…';
	@override String get pairFailed => 'Не удалось связаться с устройством';
	@override String get storedLocally => 'Сохранено — связь завершится, когда оба устройства будут в одной сети';
	@override String get incomingTitle => 'Запрос на связь';
	@override String incomingBody({required Object name}) => '${name} хочет связаться. Проверьте, что код совпадает на обоих устройствах.';
	@override String get verificationCode => 'Код проверки';
	@override String get accept => 'Принять';
	@override String get reject => 'Отклонить';
	@override String get codeButton => 'Связать через интернет';
	@override String get pairedDone => 'Устройство связано';
	@override String get yourCodeTitle => 'Код этого устройства';
	@override String get yourCodeHint => 'Введите его на другом устройстве для связи через интернет';
	@override String get showCode => 'Показать';
	@override String get hideCode => 'Скрыть';
	@override String get copyCode => 'Копировать';
	@override String get codeCopied => 'Код скопирован';
	@override String get remoteCodeTitle => 'Связать по коду';
	@override String get remoteCodeHint => 'Вставьте код другого устройства';
	@override String get fullscreen => 'На весь экран';
	@override String get codeEmpty => 'Введите код устройства';
	@override String get scanPaused => 'Поиск приостановлен';
	@override String get pauseScan => 'Приостановить поиск';
	@override String get resumeScan => 'Возобновить поиск';
	@override String get nfcButton => 'Связать касанием';
	@override String get nfcHint => 'Приложите устройство к другому для связи';
	@override String get nfcWaiting => 'Держите устройства вместе…';
	@override String get nfcFailed => 'Не удалось связать через NFC';
}

// Path: share
class _Translations$share$ru implements Translations$share$en {
	_Translations$share$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get incomingTitle => 'Запрос на доступ к папке';
	@override String incomingBody({required Object name, required Object folder}) => '${name} хочет открыть вам доступ к папке «${folder}». Выберите, куда её сохранить.';
	@override String get choose => 'Выбрать папку';
	@override String get accept => 'Принять';
	@override String get reject => 'Отклонить';
	@override String accepted({required Object folder}) => 'Папка «${folder}» добавлена';
	@override String get declined => 'Запрос отклонён';
}

// Path: activity
class _Translations$activity$ru implements Translations$activity$en {
	_Translations$activity$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String syncedToday({required Object bytes}) => 'Синхронизировано сегодня: ${bytes}';
	@override String get upToDate => 'Все устройства актуальны';
	@override String get remove => 'Удалить запись';
	@override String get empty => 'Ничего не синхронизируется';
	@override String get emptyHint => 'Передачи и конфликты будут отображаться здесь по мере возникновения.';
	@override String get eventConnecting => 'Подключение';
	@override String get eventConnected => 'Подключено';
	@override String get eventDisconnected => 'Отключено';
	@override String get eventReceived => 'Получен файл';
	@override String get eventConflict => 'Конфликт синхронизации';
	@override String get transportTcp => 'Прямой TCP';
	@override String get transportLan => 'Локальная сеть';
	@override String get transportBluetooth => 'Bluetooth';
	@override String get transportWifiDirect => 'Wi-Fi Direct';
	@override String get transportMultipeer => 'Multipeer';
	@override String get transportWifiAware => 'Wi-Fi Aware';
}

// Path: schedule
class _Translations$schedule$ru implements Translations$schedule$en {
	_Translations$schedule$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Синхронизация';
	@override String get syncNow => 'Синхронизировать сейчас';
	@override String get syncNowHint => 'Включить синхронизацию немедленно, пока не выключите';
	@override String get scheduleTitle => 'Ежедневное расписание';
	@override String get scheduleHint => 'Синхронизировать каждый день в этом окне';
	@override String get from => 'С';
	@override String get to => 'До';
	@override String get active => 'Идёт синхронизация';
	@override String get paused => 'На паузе';
}

// Path: settings
class _Translations$settings$ru implements Translations$settings$en {
	_Translations$settings$ru._(this._root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get appearance => 'Внешний вид';
	@override String get languageTitle => 'Язык';
	@override String get languageSubtitle => 'Язык интерфейса';
	@override String get languageEnglish => 'Английский';
	@override String get languageRussian => 'Русский';
	@override String get discovery => 'Обнаружение';
	@override String get lanTitle => 'Локальная сеть (mDNS)';
	@override String get lanSubtitle => 'Найти устройства в одной сети';
	@override String get dhtTitle => 'Интернет (DHT)';
	@override String get dhtSubtitle => 'Найти устройства через интернет';
	@override String get bluetoothTitle => 'Bluetooth';
	@override String get bluetoothSubtitle => 'Использовать Bluetooth рядом, если сеть недоступна';
	@override String get offlineTransports => 'Офлайн-транспорты';
	@override String get wifiDirectTitle => 'Wi-Fi Direct';
	@override String get wifiDirectSubtitle => 'Быстрая связь по Wi-Fi без точки доступа';
	@override String get multipeerTitle => 'Multipeer';
	@override String get multipeerSubtitle => 'Связь Apple по Wi-Fi и Bluetooth';
	@override String get wifiAwareTitle => 'Wi-Fi Aware';
	@override String get wifiAwareSubtitle => 'Обнаружение и передача без сервера';
	@override String get hotspotTitle => 'Локальная точка доступа';
	@override String get hotspotSubtitle => 'Поднять точку доступа, чтобы устройства подключились офлайн';
	@override String get hotspotCreate => 'Создать точку доступа';
	@override String get hotspotStop => 'Остановить точку доступа';
	@override String hotspotActive({required Object ssid}) => 'Точка доступа активна — ${ssid}';
	@override String hotspotPassword({required Object password}) => 'Пароль: ${password}';
	@override String get hotspotFailed => 'Не удалось запустить точку доступа';
	@override String get nfcTitle => 'Связь по NFC';
	@override String get nfcSubtitle => 'Поднесите два устройства друг к другу для связи';
	@override String get backgroundTitle => 'Синхронизация в фоне';
	@override String get backgroundSubtitle => 'Продолжать синхронизацию при свернутом приложении';
	@override String get logsTitle => 'Логи активности';
	@override String get logPath => 'Файл логов';
	@override String get changeLogPath => 'Изменить путь';
	@override String get openLogLocation => 'Открыть в проводнике';
	@override String get clearLogs => 'Очистить логи';
	@override String get logPathChanged => 'Путь к логам обновлён';
	@override String get logsCleared => 'Логи очищены';
	@override String get logOpenFailed => 'Не удалось открыть расположение логов';
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
			'devices.offline' => 'Не в сети',
			'devices.empty' => 'Нет связанных устройств',
			'devices.emptyHint' => 'Откройте «Связь», чтобы подключить другое устройство.',
			'devices.errorLoad' => 'Не удалось загрузить данные устройства',
			'devices.errorLoadPeers' => 'Не удалось загрузить связанные устройства',
			'devices.remove' => 'Удалить устройство',
			'folders.add' => 'Добавить папку',
			'folders.storageDenied' => 'Для синхронизации нужен доступ к хранилищу',
			'folders.manageAccess' => 'Управление доступом',
			'folders.access' => 'Доступ устройств',
			'folders.localFolder' => 'Локальная папка',
			'folders.localAvailable' => 'Доступна',
			'folders.localMissing' => 'Папка не найдена',
			'folders.noPeers' => 'Свяжите устройство, чтобы делиться с ним папкой',
			'folders.empty' => 'Нет общих папок',
			'folders.emptyHint' => 'Добавьте папку для синхронизации между устройствами.',
			'folders.errorLoad' => 'Не удалось загрузить папки',
			'folders.scanning' => 'Сканирование...',
			'folders.folderSize' => ({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(n, zero: 'Пусто', one: '${size}', few: '${size}', many: '${size}', other: '${size}', ), 
			'folders.scan' => 'Сканировать',
			'folders.scanned' => ({required Object count}) => 'Просканировано файлов: ${count}',
			'folders.alreadyAdded' => 'Папка уже добавлена',
			'folders.openFolder' => 'Открыть папку',
			'folders.openFailed' => 'Не удалось открыть папку',
			'folders.remove' => 'Удалить папку',
			'folders.sendFiles' => 'Отправлять файлы',
			'folders.receiveFiles' => 'Получать файлы',
			'folders.remoteMissing' => 'Нет на удалённом устройстве',
			'folders.remoteAvailable' => 'Доступна на удалённом',
			'pair.scanHint' => 'Отсканируйте этот код на другом устройстве',
			'pair.scanButton' => 'Сканировать устройство',
			'pair.scanInstruction' => 'Направьте камеру на QR-код другого устройства',
			'pair.toggleFlashlight' => 'Включить фонарик',
			'pair.selfPairError' => 'Нельзя связать устройство с самим собой',
			'pair.paired' => ({required Object name}) => 'Устройство ${name} связано',
			'pair.invalidQr' => 'Этот QR-код не является кодом Mesh Market',
			'pair.nearbyTitle' => 'Устройства рядом',
			'pair.nearbySearching' => 'Поиск устройств в вашей сети…',
			'pair.pairAction' => 'Связать',
			'pair.manualTitle' => 'Ввести код вручную',
			'pair.manualHint' => 'Вставьте код устройства',
			'pair.pairing' => 'Связывание…',
			'pair.pairFailed' => 'Не удалось связаться с устройством',
			'pair.storedLocally' => 'Сохранено — связь завершится, когда оба устройства будут в одной сети',
			'pair.incomingTitle' => 'Запрос на связь',
			'pair.incomingBody' => ({required Object name}) => '${name} хочет связаться. Проверьте, что код совпадает на обоих устройствах.',
			'pair.verificationCode' => 'Код проверки',
			'pair.accept' => 'Принять',
			'pair.reject' => 'Отклонить',
			'pair.codeButton' => 'Связать через интернет',
			'pair.pairedDone' => 'Устройство связано',
			'pair.yourCodeTitle' => 'Код этого устройства',
			'pair.yourCodeHint' => 'Введите его на другом устройстве для связи через интернет',
			'pair.showCode' => 'Показать',
			'pair.hideCode' => 'Скрыть',
			'pair.copyCode' => 'Копировать',
			'pair.codeCopied' => 'Код скопирован',
			'pair.remoteCodeTitle' => 'Связать по коду',
			'pair.remoteCodeHint' => 'Вставьте код другого устройства',
			'pair.fullscreen' => 'На весь экран',
			'pair.codeEmpty' => 'Введите код устройства',
			'pair.scanPaused' => 'Поиск приостановлен',
			'pair.pauseScan' => 'Приостановить поиск',
			'pair.resumeScan' => 'Возобновить поиск',
			'pair.nfcButton' => 'Связать касанием',
			'pair.nfcHint' => 'Приложите устройство к другому для связи',
			'pair.nfcWaiting' => 'Держите устройства вместе…',
			'pair.nfcFailed' => 'Не удалось связать через NFC',
			'share.incomingTitle' => 'Запрос на доступ к папке',
			'share.incomingBody' => ({required Object name, required Object folder}) => '${name} хочет открыть вам доступ к папке «${folder}». Выберите, куда её сохранить.',
			'share.choose' => 'Выбрать папку',
			'share.accept' => 'Принять',
			'share.reject' => 'Отклонить',
			'share.accepted' => ({required Object folder}) => 'Папка «${folder}» добавлена',
			'share.declined' => 'Запрос отклонён',
			'activity.syncedToday' => ({required Object bytes}) => 'Синхронизировано сегодня: ${bytes}',
			'activity.upToDate' => 'Все устройства актуальны',
			'activity.remove' => 'Удалить запись',
			'activity.empty' => 'Ничего не синхронизируется',
			'activity.emptyHint' => 'Передачи и конфликты будут отображаться здесь по мере возникновения.',
			'activity.eventConnecting' => 'Подключение',
			'activity.eventConnected' => 'Подключено',
			'activity.eventDisconnected' => 'Отключено',
			'activity.eventReceived' => 'Получен файл',
			'activity.eventConflict' => 'Конфликт синхронизации',
			'activity.transportTcp' => 'Прямой TCP',
			'activity.transportLan' => 'Локальная сеть',
			'activity.transportBluetooth' => 'Bluetooth',
			'activity.transportWifiDirect' => 'Wi-Fi Direct',
			'activity.transportMultipeer' => 'Multipeer',
			'activity.transportWifiAware' => 'Wi-Fi Aware',
			'schedule.title' => 'Синхронизация',
			'schedule.syncNow' => 'Синхронизировать сейчас',
			'schedule.syncNowHint' => 'Включить синхронизацию немедленно, пока не выключите',
			'schedule.scheduleTitle' => 'Ежедневное расписание',
			'schedule.scheduleHint' => 'Синхронизировать каждый день в этом окне',
			'schedule.from' => 'С',
			'schedule.to' => 'До',
			'schedule.active' => 'Идёт синхронизация',
			'schedule.paused' => 'На паузе',
			'settings.appearance' => 'Внешний вид',
			'settings.languageTitle' => 'Язык',
			'settings.languageSubtitle' => 'Язык интерфейса',
			'settings.languageEnglish' => 'Английский',
			'settings.languageRussian' => 'Русский',
			'settings.discovery' => 'Обнаружение',
			'settings.lanTitle' => 'Локальная сеть (mDNS)',
			'settings.lanSubtitle' => 'Найти устройства в одной сети',
			'settings.dhtTitle' => 'Интернет (DHT)',
			'settings.dhtSubtitle' => 'Найти устройства через интернет',
			'settings.bluetoothTitle' => 'Bluetooth',
			'settings.bluetoothSubtitle' => 'Использовать Bluetooth рядом, если сеть недоступна',
			'settings.offlineTransports' => 'Офлайн-транспорты',
			'settings.wifiDirectTitle' => 'Wi-Fi Direct',
			'settings.wifiDirectSubtitle' => 'Быстрая связь по Wi-Fi без точки доступа',
			'settings.multipeerTitle' => 'Multipeer',
			'settings.multipeerSubtitle' => 'Связь Apple по Wi-Fi и Bluetooth',
			'settings.wifiAwareTitle' => 'Wi-Fi Aware',
			'settings.wifiAwareSubtitle' => 'Обнаружение и передача без сервера',
			'settings.hotspotTitle' => 'Локальная точка доступа',
			'settings.hotspotSubtitle' => 'Поднять точку доступа, чтобы устройства подключились офлайн',
			'settings.hotspotCreate' => 'Создать точку доступа',
			'settings.hotspotStop' => 'Остановить точку доступа',
			'settings.hotspotActive' => ({required Object ssid}) => 'Точка доступа активна — ${ssid}',
			'settings.hotspotPassword' => ({required Object password}) => 'Пароль: ${password}',
			'settings.hotspotFailed' => 'Не удалось запустить точку доступа',
			'settings.nfcTitle' => 'Связь по NFC',
			'settings.nfcSubtitle' => 'Поднесите два устройства друг к другу для связи',
			'settings.backgroundTitle' => 'Синхронизация в фоне',
			'settings.backgroundSubtitle' => 'Продолжать синхронизацию при свернутом приложении',
			'settings.logsTitle' => 'Логи активности',
			'settings.logPath' => 'Файл логов',
			'settings.changeLogPath' => 'Изменить путь',
			'settings.openLogLocation' => 'Открыть в проводнике',
			'settings.clearLogs' => 'Очистить логи',
			'settings.logPathChanged' => 'Путь к логам обновлён',
			'settings.logsCleared' => 'Логи очищены',
			'settings.logOpenFailed' => 'Не удалось открыть расположение логов',
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
