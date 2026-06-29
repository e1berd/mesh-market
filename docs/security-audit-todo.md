# Security Audit — TODO

> Аудит проведён 2026-06-29 по ветке `master` (v1.1.1). Чеклист исправлений
> по убыванию приоритета. Отмечайте `[x]` по мере закрытия.

## Контекст / модель доверия

Замысел здравый: `swarmSecret` (секрет папки) отделён от device-ключей, AEAD на
блоках, E2E поверх транспорта. Конфиденциальность **содержимого** в основном
держится, т.к. ключ папки выводится из *запомненного при спаривании*
agreement-ключа (`sync_service.dart:976`), а не из ключа «с провода». Всё
остальное (аутентификация пира, метаданные, целостность, спаривание, секреты на
диске и в сети) защищено слабо или никак.

---

## CRITICAL

- [ ] **C1. Личность пира не доказывается.** `sign()` (`identity.dart:23`) и поле
  `Hello.signature` (`messages.dart:64`) не используются: отправка с пустой
  подписью (`sync_service.dart:1032`), приём без проверки (`engine.dart:72`).
  Авторизация = заявленный `deviceId` (`sync_service.dart:885-889`,
  `_acceptTcp/_acceptBluetooth/_acceptMultipeer`). `deviceId` рассылается открыто
  (LAN-маяк, DHT, BLE).
  → **Фикс:** challenge–response, обе стороны подписывают nonce собеседника
  (proof-of-possession); проверять подпись до авторизации.

- [ ] **C2. Path traversal → удаление/перезапись файлов вне папки.** Входящий
  `meta.path` не валидируется: `store.delete` (`engine.dart:88`, без расшифровки!),
  `store.writeBytes` (`engine.dart:181`), `File('${root.path}${sep}$path')`
  (`file_store.dart:19`). Путь `../../.ssh/authorized_keys` выходит за корень.
  → **Фикс:** отклонять абсолютные пути и `..`; проверять, что
  `canonicalize(root/path)` остаётся под `root`, до delete/write/rename.
  *(самый дешёвый и самый опасный — делать первым)*

- [ ] **C3. `IndexSnapshot` (метаданные) идёт открытым текстом.** `FolderCipher`
  применяется только к `BlockPayload` (`engine.dart:159,167`). Пути/размеры/времена/
  SHA-хеши видят relay, MITM на сигналинге и любой, кто прошёл C1.
  → **Фикс:** запечатывать весь прикладной поток (включая индекс).

- [ ] **C4. `swarmSecret` передаётся открытым текстом по сети.** `ShareRequest`
  несёт `swarmSecret` base64 (`sync_service.dart:612-616`, `folder_share.dart:23`),
  а LAN-сигналинг — незашифрованный TCP (`lan_signaling.dart`). Сниффер в LAN
  перехватывает секрет.
  → **Фикс:** шифровать share под ECDH-ключом уже спаренного пира.

- [ ] **C5. Спаривание без защиты от MITM; SAS бесполезен.** `pairAt`
  (`sync_service.dart:627`) слепо принимает `PairResponse`. `pairingCode`
  (`pairing_code.dart`) считается только из публичных `deviceId`. Привязка
  `deviceId == hash(signingKey)` нигде не проверяется (считается лишь при создании,
  `identity.dart:40`).
  → **Фикс:** (1) проверять `deviceId == base32(sha256(signingKey)[:20])` при приёме
  payload; (2) двусторонний SAS поверх ECDH, сверяемый пользователем; (3) инициатор
  тоже подтверждает.

---

## HIGH

- [ ] **H1. Приватные ключи устройства на диске открыто.** `identity.dart:67` —
  base64-JSON, без Keychain/Keystore (`flutter_secure_storage` не в зависимостях).
- [ ] **H2. `swarmSecret` хранится открыто на диске.** `folder_codec.dart:9`,
  `folders_provider.dart:176`.
- [ ] **H3. Синхронизируемые файлы на диске не шифруются** (`engine.dart:181`) —
  обещание «blocks stored encrypted on disk» из `CLAUDE.md` не выполняется.
  → либо реализовать, либо убрать заявление из спеки.
- [ ] **H4. Нет проверки хеша блока после расшифровки** (`engine.dart:_maybeFinish`)
  — содержимое не сверяется с заявленными `blockHashes`.

---

## MEDIUM

- [ ] **M1. Нет forward secrecy** — статический agreement-ключ в `deriveFolderKey`
  (`sync_service.dart:977`); нужен эфемерный DH на сессию.
- [ ] **M2. WebRTC DTLS-fingerprint не пиннится** — MITM поверх plaintext-сигналинга.
- [ ] **M3. Relay видит метаданные** (`_handleRelayOpen`) и может служить усилителем.
- [ ] **M4. HKDF без привязки к контексту сессии/пирам** (`folder_key.dart`).
- [ ] **M5. Парсеры входящих сообщений без лимитов размера**
  (`SignalMessage.decode`, `SyncMessage.decode`, `BlockPayload`, `RelayFrame`) → DoS.
- [ ] **M6. STUN по умолчанию `stun.l.google.com`** (`config.dart:19`) раскрывает
  внешний IP; отключаемо, но включено по умолчанию.

---

## LOW / качество

- [ ] **L1.** Мёртвый код протокола: `OpenLink`, `Hello.signature`
  (`messages.dart:50`, `engine.dart:70`) — реализовать (C1) или удалить.
- [ ] **L2.** Повсеместный `catch (Object) { return; }` глушит ошибки
  (`_announcePairing`, `_watch`, `negotiator.dart:88`).
- [ ] **L3.** `debugPrint` логирует `deviceId`/адреса/метки папок — проверить, что
  подавляется в release, не логировать секреты.
- [ ] **L4.** `sync_service.dart` — 1418 строк (лимит 300); декомпозировать
  (discovery / relay / transport-выбор / сессии).

---

## Порядок исправления

1. C2 (path traversal) — изолированный фикс + тест на обход каталога.
2. C1 + C5 — proof-of-possession и `deviceId == hash(signingKey)`.
3. C4 + C3 — убрать plaintext `swarmSecret`/индекс.
4. H1/H2 — секреты в платформенное защищённое хранилище.
5. H3 — синхронизировать `CLAUDE.md` с реальным at-rest поведением.
