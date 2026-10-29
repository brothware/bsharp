# Wear: phone-synced watch, and sign-in without typing (WO-P6)

Play rejects the wear build while its only way in is typing school, login and
password on the watch keyboard (WO-P6). Most watches have no LTE, so while the
phone is connected the phone syncs and the watch shows what it sends. When the
phone is away and the watch has its own Wi-Fi or LTE, the watch syncs with
mobireg itself.

## Decisions (agreed 2026-10-28/29)

- **Source chosen at run time.** Phone connected: the phone syncs with
  mobireg and sends the result over the Wear Data Layer (Bluetooth when near,
  Wi-Fi or Google's relay otherwise). Phone away and the watch online: the
  watch syncs itself. The newer data wins.
- **The watch holds the account** (password included) so it can sync alone.
  It gets it without typing, in this order:
  1. "Set up watch" on the phone, one explicit tap, sent as a single Data Layer
     message (MessageClient, direct to the connected node; never a data item,
     never stored or relayed);
  2. a password saved in the user's Google account (Credential Manager), for a
     watch that has never seen the phone app;
  3. a small "Type it on the watch" link as the last resort.
  Demo mode stays on the first screen.
- The phone offers Android's "Save password?" prompt after a login, so option 2
  has something to find.
- A standalone sync opens a second mobireg session, only while the phone is
  away; the phone keeps its own single session.
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
1. Account handoff: phone "Set up watch" sends a chosen account; the watch
   sign-in screen receives it and runs the existing account probe. Watch
   "Use phone" opens that phone screen (RemoteActivityHelper +
   `bsharp://watch-setup`).
2. Credential Manager: the phone saves the password after a login; the watch
   offers "Sign in with saved password"; the keyboard steps move behind a
   small link; re-auth tries the saved password first.
3. Snapshot codec: encode the sync cache and account into a versioned payload
   and decode it back (pure Dart, unit tested).
4. Phone publishes the snapshot after each sync, foreground and push-triggered.
5. Watch source selection: with a phone node connected, hydrate from the
   phone's snapshot and skip its own sync; with none and a network, sync
   itself; keep whichever data is newer.

**Phase 2 - relay**
6. Relay protocol and the phone's listener service with a background engine.
7. Watch mail actions go through the relay in phone mode.

Each commit is tested; the flows are checked on the phone and round wear
emulators paired together.
