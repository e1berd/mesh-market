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
	late final Translations$share$en share = Translations$share$en._(_root);
	late final Translations$activity$en activity = Translations$activity$en._(_root);
	late final Translations$schedule$en schedule = Translations$schedule$en._(_root);
	late final Translations$settings$en settings = Translations$settings$en._(_root);
	late final Translations$iceDialog$en iceDialog = Translations$iceDialog$en._(_root);
	late final Translations$addFolder$en addFolder = Translations$addFolder$en._(_root);
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

	/// en: 'Offline'
	String get offline => 'Offline';

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

	/// en: 'Synced storage'
	String get storageTitle => 'Synced storage';

	/// en: '(zero) {No folders} (one) {{n} folder} (other) {{n} folders}'
	String foldersCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No folders',
		one: '${n} folder',
		other: '${n} folders',
	);

	/// en: 'Syncing'
	String get syncing => 'Syncing';

	/// en: 'Connecting'
	String get connecting => 'Connecting';

	/// en: 'Needs attention'
	String get conflict => 'Needs attention';

	/// en: '{done} of {total} files'
	String filesProgress({required Object done, required Object total}) => '${done} of ${total} files';
}

// Path: folders
class Translations$folders$en {
	Translations$folders$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add folder'
	String get add => 'Add folder';

	/// en: 'Storage access is required to sync folders'
	String get storageDenied => 'Storage access is required to sync folders';

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

	/// en: '(zero) {Empty} (one) {{size}} (other) {{size}}'
	String folderSize({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'Empty',
		one: '${size}',
		other: '${size}',
	);

	/// en: 'Scan'
	String get scan => 'Scan';

	/// en: 'Scanned {count} files'
	String scanned({required Object count}) => 'Scanned ${count} files';

	/// en: 'Folder already added'
	String get alreadyAdded => 'Folder already added';

	/// en: 'Open folder'
	String get openFolder => 'Open folder';

	/// en: 'Could not open folder'
	String get openFailed => 'Could not open folder';

	/// en: 'Remove folder'
	String get remove => 'Remove folder';

	/// en: 'Send files'
	String get sendFiles => 'Send files';

	/// en: 'Receive files'
	String get receiveFiles => 'Receive files';

	/// en: 'Not available on remote'
	String get remoteMissing => 'Not available on remote';

	/// en: 'Available on remote'
	String get remoteAvailable => 'Available on remote';

	/// en: '(one) {{n} conflict} (other) {{n} conflicts}'
	String conflicts({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} conflict',
		other: '${n} conflicts',
	);

	/// en: 'Resolve conflicts'
	String get conflictsTitle => 'Resolve conflicts';

	/// en: 'Resolve automatically'
	String get resolveAuto => 'Resolve automatically';

	/// en: 'Keeps the most recently changed version of each file'
	String get resolveAutoHint => 'Keeps the most recently changed version of each file';

	/// en: 'Current'
	String get conflictCurrent => 'Current';

	/// en: 'Incoming'
	String get conflictIncoming => 'Incoming';

	/// en: 'Keep current'
	String get conflictKeepCurrent => 'Keep current';

	/// en: 'Use incoming'
	String get conflictUseIncoming => 'Use incoming';

	/// en: 'Text preview is unavailable for this file'
	String get conflictNoPreview => 'Text preview is unavailable for this file';

	/// en: 'Conflict resolved'
	String get conflictResolved => 'Conflict resolved';
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

	/// en: 'Device {name} paired'
	String paired({required Object name}) => 'Device ${name} paired';

	/// en: 'This QR code is not a Mesh Market device'
	String get invalidQr => 'This QR code is not a Mesh Market device';

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

	/// en: 'Saved. If the other device did not show a request, check internet or NFC'
	String get storedLocally => 'Saved. If the other device did not show a request, check internet or NFC';

	/// en: 'Pairing request'
	String get incomingTitle => 'Pairing request';

	/// en: '{name} wants to pair. Check the code matches on both devices.'
	String incomingBody({required Object name}) => '${name} wants to pair. Check the code matches on both devices.';

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

	/// en: 'Hold for NFC pairing'
	String get nfcButton => 'Hold for NFC pairing';

	/// en: 'Hold on one device and place both devices together'
	String get nfcHint => 'Hold on one device and place both devices together';

	/// en: 'NFC is active, keep the devices together…'
	String get nfcWaiting => 'NFC is active, keep the devices together…';

	/// en: 'NFC pairing failed'
	String get nfcFailed => 'NFC pairing failed';
}

// Path: share
class Translations$share$en {
	Translations$share$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Folder share request'
	String get incomingTitle => 'Folder share request';

	/// en: '{name} wants to share the folder “{folder}” with you. Choose where to save it.'
	String incomingBody({required Object name, required Object folder}) => '${name} wants to share the folder “${folder}” with you. Choose where to save it.';

	/// en: 'Choose location'
	String get choose => 'Choose location';

	/// en: 'Accept'
	String get accept => 'Accept';

	/// en: 'Reject'
	String get reject => 'Reject';

	/// en: 'Folder “{folder}” added'
	String accepted({required Object folder}) => 'Folder “${folder}” added';

	/// en: 'Share declined'
	String get declined => 'Share declined';
}

// Path: activity
class Translations$activity$en {
	Translations$activity$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '{bytes} synced today'
	String syncedToday({required Object bytes}) => '${bytes} synced today';

	/// en: 'All devices up to date'
	String get upToDate => 'All devices up to date';

	/// en: 'Remove entry'
	String get remove => 'Remove entry';

	/// en: 'Nothing syncing'
	String get empty => 'Nothing syncing';

	/// en: 'Transfers and conflicts will appear here as they happen.'
	String get emptyHint => 'Transfers and conflicts will appear here as they happen.';

	/// en: 'In progress'
	String get liveTitle => 'In progress';

	/// en: 'You'
	String get you => 'You';

	/// en: 'Transferring'
	String get liveTransferring => 'Transferring';

	/// en: 'All files synced'
	String get liveComplete => 'All files synced';

	/// en: 'Preparing'
	String get livePreparing => 'Preparing';

	/// en: '{done} of {total} files'
	String liveFiles({required Object done, required Object total}) => '${done} of ${total} files';

	/// en: 'Connecting'
	String get eventConnecting => 'Connecting';

	/// en: 'Connected'
	String get eventConnected => 'Connected';

	/// en: 'Disconnected'
	String get eventDisconnected => 'Disconnected';

	/// en: 'Received a file'
	String get eventReceived => 'Received a file';

	/// en: 'Sync conflict'
	String get eventConflict => 'Sync conflict';

	/// en: 'Direct TCP'
	String get transportTcp => 'Direct TCP';

	/// en: 'Local network'
	String get transportLan => 'Local network';

	/// en: 'Bluetooth'
	String get transportBluetooth => 'Bluetooth';

	/// en: 'Wi-Fi Direct'
	String get transportWifiDirect => 'Wi-Fi Direct';

	/// en: 'Multipeer'
	String get transportMultipeer => 'Multipeer';

	/// en: 'Wi-Fi Aware'
	String get transportWifiAware => 'Wi-Fi Aware';
}

// Path: schedule
class Translations$schedule$en {
	Translations$schedule$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Synchronization'
	String get title => 'Synchronization';

	/// en: 'Sync now'
	String get syncNow => 'Sync now';

	/// en: 'Sync immediately until you turn it off'
	String get syncNowHint => 'Sync immediately until you turn it off';

	/// en: 'Daily schedule'
	String get scheduleTitle => 'Daily schedule';

	/// en: 'Sync every day during this window'
	String get scheduleHint => 'Sync every day during this window';

	/// en: 'From'
	String get from => 'From';

	/// en: 'To'
	String get to => 'To';

	/// en: 'Syncing now'
	String get active => 'Syncing now';

	/// en: 'Paused'
	String get paused => 'Paused';
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

	/// en: 'Router port mapping'
	String get portMappingTitle => 'Router port mapping';

	/// en: 'Open a path through your router (UPnP, NAT-PMP, PCP)'
	String get portMappingSubtitle => 'Open a path through your router (UPnP, NAT-PMP, PCP)';

	/// en: 'Peer relay'
	String get peerRelayTitle => 'Peer relay';

	/// en: 'Reach peers through another of your devices when direct fails'
	String get peerRelaySubtitle => 'Reach peers through another of your devices when direct fails';

	/// en: 'Hole punching'
	String get holePunchTitle => 'Hole punching';

	/// en: 'Direct peer-to-peer UDP through NAT, no relay needed'
	String get holePunchSubtitle => 'Direct peer-to-peer UDP through NAT, no relay needed';

	/// en: 'Bluetooth'
	String get bluetoothTitle => 'Bluetooth';

	/// en: 'Use nearby Bluetooth when network sync fails'
	String get bluetoothSubtitle => 'Use nearby Bluetooth when network sync fails';

	/// en: 'Offline transports'
	String get offlineTransports => 'Offline transports';

	/// en: 'Wi-Fi Direct'
	String get wifiDirectTitle => 'Wi-Fi Direct';

	/// en: 'Fast peer-to-peer over Wi-Fi, no access point'
	String get wifiDirectSubtitle => 'Fast peer-to-peer over Wi-Fi, no access point';

	/// en: 'Multipeer'
	String get multipeerTitle => 'Multipeer';

	/// en: 'Apple peer-to-peer over Wi-Fi and Bluetooth'
	String get multipeerSubtitle => 'Apple peer-to-peer over Wi-Fi and Bluetooth';

	/// en: 'Wi-Fi Aware'
	String get wifiAwareTitle => 'Wi-Fi Aware';

	/// en: 'Serverless neighbor discovery and data path'
	String get wifiAwareSubtitle => 'Serverless neighbor discovery and data path';

	/// en: 'Local hotspot'
	String get hotspotTitle => 'Local hotspot';

	/// en: 'Raise a hotspot so peers can join and sync offline'
	String get hotspotSubtitle => 'Raise a hotspot so peers can join and sync offline';

	/// en: 'Create hotspot'
	String get hotspotCreate => 'Create hotspot';

	/// en: 'Stop hotspot'
	String get hotspotStop => 'Stop hotspot';

	/// en: 'Hotspot active — {ssid}'
	String hotspotActive({required Object ssid}) => 'Hotspot active — ${ssid}';

	/// en: 'Password: {password}'
	String hotspotPassword({required Object password}) => 'Password: ${password}';

	/// en: 'Could not start the hotspot'
	String get hotspotFailed => 'Could not start the hotspot';

	/// en: 'NFC pairing'
	String get nfcTitle => 'NFC pairing';

	/// en: 'Tap two devices together to pair'
	String get nfcSubtitle => 'Tap two devices together to pair';

	/// en: 'Sync in background'
	String get backgroundTitle => 'Sync in background';

	/// en: 'Keep syncing when app is not focused'
	String get backgroundSubtitle => 'Keep syncing when app is not focused';

	/// en: 'Activity logs'
	String get logsTitle => 'Activity logs';

	/// en: 'Log file'
	String get logPath => 'Log file';

	/// en: 'Change path'
	String get changeLogPath => 'Change path';

	/// en: 'Open location'
	String get openLogLocation => 'Open location';

	/// en: 'Clear logs'
	String get clearLogs => 'Clear logs';

	/// en: 'Log path updated'
	String get logPathChanged => 'Log path updated';

	/// en: 'Logs cleared'
	String get logsCleared => 'Logs cleared';

	/// en: 'Could not open log location'
	String get logOpenFailed => 'Could not open log location';

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

// Path: addFolder
class Translations$addFolder$en {
	Translations$addFolder$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add folder'
	String get title => 'Add folder';

	/// en: 'Change'
	String get change => 'Change';

	/// en: 'Folder name'
	String get nameLabel => 'Folder name';

	/// en: 'e.g. Photos'
	String get nameHint => 'e.g. Photos';

	/// en: 'Folder ID'
	String get idLabel => 'Folder ID';

	/// en: 'photos'
	String get idHint => 'photos';

	/// en: 'What is this?'
	String get idInfo => 'What is this?';

	/// en: 'Folder ID'
	String get idInfoTitle => 'Folder ID';

	/// en: 'The Folder ID is how your devices recognise this as the same folder. Devices that use the same ID treat it as one shared folder instead of creating a duplicate. It is generated from the folder name — give the folder the same name on each device and the IDs match automatically. You can also edit it by hand. Devices are still linked through pairing (QR); the ID is not a password.'
	String get idInfoBody => 'The Folder ID is how your devices recognise this as the same folder. Devices that use the same ID treat it as one shared folder instead of creating a duplicate. It is generated from the folder name — give the folder the same name on each device and the IDs match automatically. You can also edit it by hand. Devices are still linked through pairing (QR); the ID is not a password.';

	/// en: 'A folder with this ID already exists'
	String get idTaken => 'A folder with this ID already exists';

	/// en: 'This folder is already added'
	String get pathTaken => 'This folder is already added';

	/// en: 'Device access'
	String get access => 'Device access';

	/// en: 'Choose which paired devices can sync this folder'
	String get accessHint => 'Choose which paired devices can sync this folder';

	/// en: 'Pair a device first to share this folder'
	String get noPeers => 'Pair a device first to share this folder';

	/// en: 'Send files'
	String get send => 'Send files';

	/// en: 'Receive files'
	String get receive => 'Receive files';

	/// en: 'Add folder'
	String get create => 'Add folder';

	/// en: 'Got it'
	String get gotIt => 'Got it';
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
			'devices.offline' => 'Offline',
			'devices.empty' => 'No paired devices',
			'devices.emptyHint' => 'Open Pair to connect another device.',
			'devices.errorLoad' => 'Could not load identity',
			'devices.errorLoadPeers' => 'Could not load paired devices',
			'devices.remove' => 'Remove device',
			'devices.storageTitle' => 'Synced storage',
			'devices.foldersCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'No folders', one: '${n} folder', other: '${n} folders', ), 
			'devices.syncing' => 'Syncing',
			'devices.connecting' => 'Connecting',
			'devices.conflict' => 'Needs attention',
			'devices.filesProgress' => ({required Object done, required Object total}) => '${done} of ${total} files',
			'folders.add' => 'Add folder',
			'folders.storageDenied' => 'Storage access is required to sync folders',
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
			'folders.folderSize' => ({required num n, required Object size}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'Empty', one: '${size}', other: '${size}', ), 
			'folders.scan' => 'Scan',
			'folders.scanned' => ({required Object count}) => 'Scanned ${count} files',
			'folders.alreadyAdded' => 'Folder already added',
			'folders.openFolder' => 'Open folder',
			'folders.openFailed' => 'Could not open folder',
			'folders.remove' => 'Remove folder',
			'folders.sendFiles' => 'Send files',
			'folders.receiveFiles' => 'Receive files',
			'folders.remoteMissing' => 'Not available on remote',
			'folders.remoteAvailable' => 'Available on remote',
			'folders.conflicts' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} conflict', other: '${n} conflicts', ), 
			'folders.conflictsTitle' => 'Resolve conflicts',
			'folders.resolveAuto' => 'Resolve automatically',
			'folders.resolveAutoHint' => 'Keeps the most recently changed version of each file',
			'folders.conflictCurrent' => 'Current',
			'folders.conflictIncoming' => 'Incoming',
			'folders.conflictKeepCurrent' => 'Keep current',
			'folders.conflictUseIncoming' => 'Use incoming',
			'folders.conflictNoPreview' => 'Text preview is unavailable for this file',
			'folders.conflictResolved' => 'Conflict resolved',
			'pair.scanHint' => 'Scan this code on another device',
			'pair.scanButton' => 'Scan a device',
			'pair.scanInstruction' => 'Point the camera at another device QR code',
			'pair.toggleFlashlight' => 'Toggle flashlight',
			'pair.selfPairError' => 'Cannot pair this device with itself',
			'pair.paired' => ({required Object name}) => 'Device ${name} paired',
			'pair.invalidQr' => 'This QR code is not a Mesh Market device',
			'pair.nearbyTitle' => 'Nearby devices',
			'pair.nearbySearching' => 'Looking for devices on your network…',
			'pair.pairAction' => 'Pair',
			'pair.manualTitle' => 'Enter code manually',
			'pair.manualHint' => 'Paste a device code',
			'pair.pairing' => 'Pairing…',
			'pair.pairFailed' => 'Could not reach that device',
			'pair.storedLocally' => 'Saved. If the other device did not show a request, check internet or NFC',
			'pair.incomingTitle' => 'Pairing request',
			'pair.incomingBody' => ({required Object name}) => '${name} wants to pair. Check the code matches on both devices.',
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
			'pair.nfcButton' => 'Hold for NFC pairing',
			'pair.nfcHint' => 'Hold on one device and place both devices together',
			'pair.nfcWaiting' => 'NFC is active, keep the devices together…',
			'pair.nfcFailed' => 'NFC pairing failed',
			'share.incomingTitle' => 'Folder share request',
			'share.incomingBody' => ({required Object name, required Object folder}) => '${name} wants to share the folder “${folder}” with you. Choose where to save it.',
			'share.choose' => 'Choose location',
			'share.accept' => 'Accept',
			'share.reject' => 'Reject',
			'share.accepted' => ({required Object folder}) => 'Folder “${folder}” added',
			'share.declined' => 'Share declined',
			'activity.syncedToday' => ({required Object bytes}) => '${bytes} synced today',
			'activity.upToDate' => 'All devices up to date',
			'activity.remove' => 'Remove entry',
			'activity.empty' => 'Nothing syncing',
			'activity.emptyHint' => 'Transfers and conflicts will appear here as they happen.',
			'activity.liveTitle' => 'In progress',
			'activity.you' => 'You',
			'activity.liveTransferring' => 'Transferring',
			'activity.liveComplete' => 'All files synced',
			'activity.livePreparing' => 'Preparing',
			'activity.liveFiles' => ({required Object done, required Object total}) => '${done} of ${total} files',
			'activity.eventConnecting' => 'Connecting',
			'activity.eventConnected' => 'Connected',
			'activity.eventDisconnected' => 'Disconnected',
			'activity.eventReceived' => 'Received a file',
			'activity.eventConflict' => 'Sync conflict',
			'activity.transportTcp' => 'Direct TCP',
			'activity.transportLan' => 'Local network',
			'activity.transportBluetooth' => 'Bluetooth',
			'activity.transportWifiDirect' => 'Wi-Fi Direct',
			'activity.transportMultipeer' => 'Multipeer',
			'activity.transportWifiAware' => 'Wi-Fi Aware',
			'schedule.title' => 'Synchronization',
			'schedule.syncNow' => 'Sync now',
			'schedule.syncNowHint' => 'Sync immediately until you turn it off',
			'schedule.scheduleTitle' => 'Daily schedule',
			'schedule.scheduleHint' => 'Sync every day during this window',
			'schedule.from' => 'From',
			'schedule.to' => 'To',
			'schedule.active' => 'Syncing now',
			'schedule.paused' => 'Paused',
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
			'settings.portMappingTitle' => 'Router port mapping',
			'settings.portMappingSubtitle' => 'Open a path through your router (UPnP, NAT-PMP, PCP)',
			'settings.peerRelayTitle' => 'Peer relay',
			'settings.peerRelaySubtitle' => 'Reach peers through another of your devices when direct fails',
			'settings.holePunchTitle' => 'Hole punching',
			'settings.holePunchSubtitle' => 'Direct peer-to-peer UDP through NAT, no relay needed',
			'settings.bluetoothTitle' => 'Bluetooth',
			'settings.bluetoothSubtitle' => 'Use nearby Bluetooth when network sync fails',
			'settings.offlineTransports' => 'Offline transports',
			'settings.wifiDirectTitle' => 'Wi-Fi Direct',
			'settings.wifiDirectSubtitle' => 'Fast peer-to-peer over Wi-Fi, no access point',
			'settings.multipeerTitle' => 'Multipeer',
			'settings.multipeerSubtitle' => 'Apple peer-to-peer over Wi-Fi and Bluetooth',
			'settings.wifiAwareTitle' => 'Wi-Fi Aware',
			'settings.wifiAwareSubtitle' => 'Serverless neighbor discovery and data path',
			'settings.hotspotTitle' => 'Local hotspot',
			'settings.hotspotSubtitle' => 'Raise a hotspot so peers can join and sync offline',
			'settings.hotspotCreate' => 'Create hotspot',
			'settings.hotspotStop' => 'Stop hotspot',
			'settings.hotspotActive' => ({required Object ssid}) => 'Hotspot active — ${ssid}',
			'settings.hotspotPassword' => ({required Object password}) => 'Password: ${password}',
			'settings.hotspotFailed' => 'Could not start the hotspot',
			'settings.nfcTitle' => 'NFC pairing',
			'settings.nfcSubtitle' => 'Tap two devices together to pair',
			'settings.backgroundTitle' => 'Sync in background',
			'settings.backgroundSubtitle' => 'Keep syncing when app is not focused',
			'settings.logsTitle' => 'Activity logs',
			'settings.logPath' => 'Log file',
			'settings.changeLogPath' => 'Change path',
			'settings.openLogLocation' => 'Open location',
			'settings.clearLogs' => 'Clear logs',
			'settings.logPathChanged' => 'Log path updated',
			'settings.logsCleared' => 'Logs cleared',
			'settings.logOpenFailed' => 'Could not open log location',
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
			'addFolder.title' => 'Add folder',
			'addFolder.change' => 'Change',
			'addFolder.nameLabel' => 'Folder name',
			'addFolder.nameHint' => 'e.g. Photos',
			'addFolder.idLabel' => 'Folder ID',
			'addFolder.idHint' => 'photos',
			'addFolder.idInfo' => 'What is this?',
			'addFolder.idInfoTitle' => 'Folder ID',
			'addFolder.idInfoBody' => 'The Folder ID is how your devices recognise this as the same folder. Devices that use the same ID treat it as one shared folder instead of creating a duplicate. It is generated from the folder name — give the folder the same name on each device and the IDs match automatically. You can also edit it by hand. Devices are still linked through pairing (QR); the ID is not a password.',
			'addFolder.idTaken' => 'A folder with this ID already exists',
			'addFolder.pathTaken' => 'This folder is already added',
			'addFolder.access' => 'Device access',
			'addFolder.accessHint' => 'Choose which paired devices can sync this folder',
			'addFolder.noPeers' => 'Pair a device first to share this folder',
			'addFolder.send' => 'Send files',
			'addFolder.receive' => 'Receive files',
			'addFolder.create' => 'Add folder',
			'addFolder.gotIt' => 'Got it',
			_ => null,
		};
	}
}
