# Wear: phone-synced watch, and sign-in without typing (WO-P6)

Play rejects the wear build while its only way in is typing school, login and
password on the watch keyboard (WO-P6). Most watches have no LTE, so a watch
paired with a phone should not talk to mobireg at all: the phone syncs and the
watch shows what the phone sends.

## Decisions (agreed 2026-10-28/29)

- **Paired watch = phone mode.** The phone syncs with mobireg and sends the
  result to the watch over the Wear Data Layer (Bluetooth when near, Wi-Fi or
  Google's relay otherwise). The watch holds no mobireg password in this mode.
- **Standalone watch** (LTE / Wi-Fi, no phone app) signs in itself: a password
  saved in the user's Google account (Credential Manager) first, Demo mode, and
  a small "Type it on the watch" link as the last resort.
- The phone offers Android's "Save password?" prompt after a login, so a
  standalone watch has something to find.
- **Freshness:** the phone forwards a snapshot after every sync, including the
  background sync it runs when a mobireg push arrives.
- **Delivery:** the latest snapshot is a Data Layer data item, so a watch out
  of range gets it on reconnect. It holds school data, never the password.
- **Actions** that need the server (full message text, star, delete, mark
  read, send) are relayed: the watch asks the phone, the phone does it and
  answers, even when the phone app is closed.

## Snapshot

The phone's sync cache (the raw provider views and mail folders the watch
already hydrates from) plus the active account's provider type, student and
display names, gzipped, with a format version. A watch that reads a newer
version than it knows says so ("update BSharp") instead of guessing. One data
item, path `/bsharp/snapshot`; the payload is an Asset, since raw views run to
100-150 KB before compression.

## Relay

Watch -> phone request as a Data Layer message on `/bsharp/relay` with a
request id, operation and arguments; the phone answers on
`/bsharp/relay-result`. On the phone a native `WearableListenerService` wakes
the app and runs the request on a background Flutter engine, the way the FCM
background handler already does. The watch times out and shows the mail
failure it shows today when the phone does not answer.

## Libraries

- `watch_connectivity` 0.2.11 for in-app messages while both apps run.
- `play-services-wearable` directly for the data item, the Asset and the
  phone's `WearableListenerService` (the plugin only listens while an engine
  is alive).
- `credential_manager` 5.1.0 (androidx.credentials 1.6.0, Wear OS support).

## Phases and commits

**Phase 1 - clears WO-P6**
1. Snapshot codec: encode the sync cache and account into a versioned payload
   and decode it back (pure Dart, unit tested).
2. Phone publishes the snapshot after each sync, foreground and push-triggered.
3. Watch phone mode: receive the snapshot, hydrate from it, show the phone's
   student; data screens work unchanged.
4. Watch first run: "Open BSharp on your phone" when a phone node is present,
   else standalone sign-in; Demo mode in both.
5. Phone saves the password to Credential Manager after a login; standalone
   watch "Sign in with saved password"; keyboard behind a small link.

**Phase 2 - relay**
6. Relay protocol and the phone's listener service with a background engine.
7. Watch mail actions go through the relay in phone mode.

Each commit is tested; the flows are checked on the phone and round wear
emulators paired together.
