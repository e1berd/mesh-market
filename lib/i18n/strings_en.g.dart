///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: '1.0.0'
	String get version => '1.0.0';

	late final Translations$nav$en nav = Translations$nav$en._(_root);
	late final Translations$navShort$en navShort = Translations$navShort$en._(_root);
	late final Translations$devices$en devices = Translations$devices$en._(_root);
	late final Translations$folders$en folders = Translations$folders$en._(_root);
	late final Translations$pair$en pair = Translations$pair$en._(_root);
	late final Translations$activity$en activity = Translations$activity$en._(_root);
	late final Translations$settings$en settings = Translations$settings$en._(_root);
	late final Translations$iceDialog$en iceDialog = Translations$iceDialog$en._(_root);
}

// Path: nav
class Translations$nav$en {
	Translations$nav$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Devices'
	String get devices => 'Devices';

	/// en: 'Folders'
	String get folders => 'Folders';

	/// en: 'Pair'
	String get pair => 'Pair';

	/// en: 'Activity'
	String get activity => 'Activity';

	/// en: 'Settings'
	String get settings => 'Settings';
}

// Path: navShort
class Translations$navShort$en {
	Translations$navShort$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Devices'
	String get devices => 'Devices';

	/// en: 'Folders'
	String get folders => 'Folders';

	/// en: 'Pair'
	String get pair => 'Pair';

	/// en: 'Activity'
	String get activity => 'Activity';

	/// en: 'Settings'
	String get settings => 'Settings';
}

// Path: devices
class Translations$devices$en {
	Translations$devices$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Paired devices'
	String get title => 'Paired devices';

	/// en: 'This device'
	String get thisDevice => 'This device';

	/// en: 'Online'
	String get online => 'Online';

	/// en: 'No paired devices'
	String get empty => 'No paired devices';

	/// en: 'Open Pair to connect another device.'
	String get emptyHint => 'Open Pair to connect another device.';

	/// en: 'Could not load identity'
	String get errorLoad => 'Could not load identity';

	/// en: 'Could not load paired devices'
	String get errorLoadPeers => 'Could not load paired devices';

	/// en: 'Remove device'
	String get remove => 'Remove device';
}

// Path: folders
class Translations$folders$en {
	Translations$folders$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add folder'
	String get add => 'Add folder';

	/// en: 'Manage access'
	String get manageAccess => 'Manage access';

	/// en: 'Device access'
	String get access => 'Device access';

	/// en: 'Local folder'
	String get localFolder => 'Local folder';

	/// en: 'Available'
	String get localAvailable => 'Available';

	/// en: 'Folder not found'
	String get localMissing => 'Folder not found';

	/// en: 'Pair a device to share this folder with it'
	String get noPeers => 'Pair a device to share this folder with it';

	/// en: 'No shared folders'
	String get empty => 'No shared folders';

	/// en: 'Add a folder to start syncing across your devices.'
	String get emptyHint => 'Add a folder to start syncing across your devices.';

	/// en: 'Could not load folders'
	String get errorLoad => 'Could not load folders';

	/// en: 'Scanning...'
	String get scanning => 'Scanning...';

	/// en: '(zero) {No files} (one) {{count} file} (other) {{count} files}'
	String fileCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No files',
		one: '{count} file',
		other: '{count} files',
	);

	/// en: 'Scan'
	String get scan => 'Scan';

	/// en: 'Scanned {$count} files'
	String scanned({required Object count}) => 'Scanned {${count}} files';

	/// en: 'Folder already added'
	String get alreadyAdded => 'Folder already added';

	/// en: 'Remove folder'
	String get remove => 'Remove folder';
}

// Path: pair
class Translations$pair$en {
	Translations$pair$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Scan this code on another device'
	String get scanHint => 'Scan this code on another device';

	/// en: 'Scan a device'
	String get scanButton => 'Scan a device';

	/// en: 'Point the camera at another device QR code'
	String get scanInstruction => 'Point the camera at another device QR code';

	/// en: 'Toggle flashlight'
	String get toggleFlashlight => 'Toggle flashlight';

	/// en: 'Cannot pair this device with itself'
	String get selfPairError => 'Cannot pair this device with itself';

	/// en: 'Device {$name} paired'
	String paired({required Object name}) => 'Device {${name}} paired';

	/// en: 'This QR code is not a point-machine device'
	String get invalidQr => 'This QR code is not a point-machine device';

	/// en: 'Nearby devices'
	String get nearbyTitle => 'Nearby devices';

	/// en: 'Looking for devices on your network…'
	String get nearbySearching => 'Looking for devices on your network…';

	/// en: 'Pair'
	String get pairAction => 'Pair';

	/// en: 'Enter code manually'
	String get manualTitle => 'Enter code manually';

	/// en: 'Paste a device code'
	String get manualHint => 'Paste a device code';

	/// en: 'Pairing…'
	String get pairing => 'Pairing…';

	/// en: 'Could not reach that device'
	String get pairFailed => 'Could not reach that device';

	/// en: 'Saved — pairing finishes when both devices are on the same network'
	String get storedLocally => 'Saved — pairing finishes when both devices are on the same network';

	/// en: 'Pairing request'
	String get incomingTitle => 'Pairing request';

	/// en: '{$name} wants to pair. Check the code matches on both devices.'
	String incomingBody({required Object name}) => '{${name}} wants to pair. Check the code matches on both devices.';

	/// en: 'Verification code'
	String get verificationCode => 'Verification code';

	/// en: 'Accept'
	String get accept => 'Accept';

	/// en: 'Reject'
	String get reject => 'Reject';

	/// en: 'Pair over the internet'
	String get codeButton => 'Pair over the internet';

	/// en: 'Device paired'
	String get pairedDone => 'Device paired';

	/// en: 'Your device code'
	String get yourCodeTitle => 'Your device code';

	/// en: 'Enter this on another device to pair over the internet'
	String get yourCodeHint => 'Enter this on another device to pair over the internet';

	/// en: 'Show'
	String get showCode => 'Show';

	/// en: 'Hide'
	String get hideCode => 'Hide';

	/// en: 'Copy'
	String get copyCode => 'Copy';

	/// en: 'Code copied'
	String get codeCopied => 'Code copied';

	/// en: 'Pair with a code'
	String get remoteCodeTitle => 'Pair with a code';

	/// en: 'Paste the other device's code'
	String get remoteCodeHint => 'Paste the other device\'s code';

	/// en: 'View fullscreen'
	String get fullscreen => 'View fullscreen';

	/// en: 'Enter a device code'
	String get codeEmpty => 'Enter a device code';

	/// en: 'Scanning paused'
	String get scanPaused => 'Scanning paused';

	/// en: 'Pause scanning'
	String get pauseScan => 'Pause scanning';

	/// en: 'Resume scanning'
	String get resumeScan => 'Resume scanning';
}

// Path: activity
class Translations$activity$en {
	Translations$activity$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '{$bytes} synced today'
	String syncedToday({required Object bytes}) => '{${bytes}} synced today';

	/// en: 'All devices up to date'
	String get upToDate => 'All devices up to date';

	/// en: 'Nothing syncing'
	String get empty => 'Nothing syncing';

	/// en: 'Transfers and conflicts will appear here as they happen.'
	String get emptyHint => 'Transfers and conflicts will appear here as they happen.';

	/// en: 'Connected'
	String get eventConnected => 'Connected';

	/// en: 'Disconnected'
	String get eventDisconnected => 'Disconnected';

	/// en: 'Received a file'
	String get eventReceived => 'Received a file';

	/// en: 'Sync conflict'
	String get eventConflict => 'Sync conflict';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Language'
	String get languageTitle => 'Language';

	/// en: 'Interface language'
	String get languageSubtitle => 'Interface language';

	/// en: 'English'
	String get languageEnglish => 'English';

	/// en: 'Russian'
	String get languageRussian => 'Russian';

	/// en: 'Discovery'
	String get discovery => 'Discovery';

	/// en: 'Local network (mDNS)'
	String get lanTitle => 'Local network (mDNS)';

	/// en: 'Find peers on the same network'
	String get lanSubtitle => 'Find peers on the same network';

	/// en: 'Internet (DHT)'
	String get dhtTitle => 'Internet (DHT)';

	/// en: 'Find peers across networks'
	String get dhtSubtitle => 'Find peers across networks';

	/// en: 'Sync in background'
	String get backgroundTitle => 'Sync in background';

	/// en: 'Keep syncing when app is not focused'
	String get backgroundSubtitle => 'Keep syncing when app is not focused';

	/// en: 'Signaling (STUN / TURN)'
	String get signaling => 'Signaling (STUN / TURN)';

	/// en: 'Using default STUN server'
	String get defaultStun => 'Using default STUN server';

	/// en: 'Add server'
	String get addServer => 'Add server';
}

// Path: iceDialog
class Translations$iceDialog$en {
	Translations$iceDialog$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'STUN / TURN server'
	String get title => 'STUN / TURN server';

	/// en: 'URL'
	String get url => 'URL';

	/// en: 'stun:host:3478'
	String get urlHint => 'stun:host:3478';

	/// en: 'Username (TURN)'
	String get username => 'Username (TURN)';

	/// en: 'Credential (TURN)'
	String get credential => 'Credential (TURN)';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Add'
	String get add => 'Add';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'version' => '1.0.0',
			'nav.devices' => 'Devices',
			'nav.folders' => 'Folders',
			'nav.pair' => 'Pair',
			'nav.activity' => 'Activity',
			'nav.settings' => 'Settings',
			'navShort.devices' => 'Devices',
			'navShort.folders' => 'Folders',
			'navShort.pair' => 'Pair',
			'navShort.activity' => 'Activity',
			'navShort.settings' => 'Settings',
			'devices.title' => 'Paired devices',
			'devices.thisDevice' => 'This device',
			'devices.online' => 'Online',
			'devices.empty' => 'No paired devices',
			'devices.emptyHint' => 'Open Pair to connect another device.',
			'devices.errorLoad' => 'Could not load identity',
			'devices.errorLoadPeers' => 'Could not load paired devices',
			'devices.remove' => 'Remove device',
			'folders.add' => 'Add folder',
			'folders.manageAccess' => 'Manage access',
			'folders.access' => 'Device access',
			'folders.localFolder' => 'Local folder',
			'folders.localAvailable' => 'Available',
			'folders.localMissing' => 'Folder not found',
			'folders.noPeers' => 'Pair a device to share this folder with it',
			'folders.empty' => 'No shared folders',
			'folders.emptyHint' => 'Add a folder to start syncing across your devices.',
			'folders.errorLoad' => 'Could not load folders',
			'folders.scanning' => 'Scanning...',
			'folders.fileCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'No files', one: '{count} file', other: '{count} files', ), 
			'folders.scan' => 'Scan',
			'folders.scanned' => ({required Object count}) => 'Scanned {${count}} files',
			'folders.alreadyAdded' => 'Folder already added',
			'folders.remove' => 'Remove folder',
			'pair.scanHint' => 'Scan this code on another device',
			'pair.scanButton' => 'Scan a device',
			'pair.scanInstruction' => 'Point the camera at another device QR code',
			'pair.toggleFlashlight' => 'Toggle flashlight',
			'pair.selfPairError' => 'Cannot pair this device with itself',
			'pair.paired' => ({required Object name}) => 'Device {${name}} paired',
			'pair.invalidQr' => 'This QR code is not a point-machine device',
			'pair.nearbyTitle' => 'Nearby devices',
			'pair.nearbySearching' => 'Looking for devices on your network…',
			'pair.pairAction' => 'Pair',
			'pair.manualTitle' => 'Enter code manually',
			'pair.manualHint' => 'Paste a device code',
			'pair.pairing' => 'Pairing…',
			'pair.pairFailed' => 'Could not reach that device',
			'pair.storedLocally' => 'Saved — pairing finishes when both devices are on the same network',
			'pair.incomingTitle' => 'Pairing request',
			'pair.incomingBody' => ({required Object name}) => '{${name}} wants to pair. Check the code matches on both devices.',
			'pair.verificationCode' => 'Verification code',
			'pair.accept' => 'Accept',
			'pair.reject' => 'Reject',
			'pair.codeButton' => 'Pair over the internet',
			'pair.pairedDone' => 'Device paired',
			'pair.yourCodeTitle' => 'Your device code',
			'pair.yourCodeHint' => 'Enter this on another device to pair over the internet',
			'pair.showCode' => 'Show',
			'pair.hideCode' => 'Hide',
			'pair.copyCode' => 'Copy',
			'pair.codeCopied' => 'Code copied',
			'pair.remoteCodeTitle' => 'Pair with a code',
			'pair.remoteCodeHint' => 'Paste the other device\'s code',
			'pair.fullscreen' => 'View fullscreen',
			'pair.codeEmpty' => 'Enter a device code',
			'pair.scanPaused' => 'Scanning paused',
			'pair.pauseScan' => 'Pause scanning',
			'pair.resumeScan' => 'Resume scanning',
			'activity.syncedToday' => ({required Object bytes}) => '{${bytes}} synced today',
			'activity.upToDate' => 'All devices up to date',
			'activity.empty' => 'Nothing syncing',
			'activity.emptyHint' => 'Transfers and conflicts will appear here as they happen.',
			'activity.eventConnected' => 'Connected',
			'activity.eventDisconnected' => 'Disconnected',
			'activity.eventReceived' => 'Received a file',
			'activity.eventConflict' => 'Sync conflict',
			'settings.appearance' => 'Appearance',
			'settings.languageTitle' => 'Language',
			'settings.languageSubtitle' => 'Interface language',
			'settings.languageEnglish' => 'English',
			'settings.languageRussian' => 'Russian',
			'settings.discovery' => 'Discovery',
			'settings.lanTitle' => 'Local network (mDNS)',
			'settings.lanSubtitle' => 'Find peers on the same network',
			'settings.dhtTitle' => 'Internet (DHT)',
			'settings.dhtSubtitle' => 'Find peers across networks',
			'settings.backgroundTitle' => 'Sync in background',
			'settings.backgroundSubtitle' => 'Keep syncing when app is not focused',
			'settings.signaling' => 'Signaling (STUN / TURN)',
			'settings.defaultStun' => 'Using default STUN server',
			'settings.addServer' => 'Add server',
			'iceDialog.title' => 'STUN / TURN server',
			'iceDialog.url' => 'URL',
			'iceDialog.urlHint' => 'stun:host:3478',
			'iceDialog.username' => 'Username (TURN)',
			'iceDialog.credential' => 'Credential (TURN)',
			'iceDialog.cancel' => 'Cancel',
			'iceDialog.add' => 'Add',
			_ => null,
		};
	}
}
