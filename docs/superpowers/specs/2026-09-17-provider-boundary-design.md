# Provider boundary: normalisation and content language

Date: 2026-09-17
Status: approved direction, pending implementation plan

## Context

Subject names reach the app in two stages. `normalizeMobiregSubjectName` turns
mobireg's Polish wording into a canonical English name (`'przyroda'` ->
`'nature'`), and `translateSubjectName` renders that canonical name in the
reader's language (`'nature'` -> `t.subjectNames.przyroda`). The schedule
resolver runs both. The portal views - tests, homework, changelog - only ever
ran the second, which cannot match Polish input, so the dashboard listed
`przyroda` and `kształcenie słuchu` beside a lesson card reading `nature`.

The missing call was the symptom. The cause is that normalisation is not owned
by anything: `lib/data/services/sync_data_applier.dart` is mobireg code by
content - it imports `mobireg_schedule_resolver`, `mobireg_grade_resolver`,
`mobireg_message_handler` and `mobireg_translations`, and parses njson shapes -
but sits in shared services, and core's `lib/app/sync_provider.dart:121` calls
it directly to rehydrate the cache. Six `normalizeMobireg*` calls live there,
five more live in the resolvers, and nothing states where the line is, so a new
payload path can reach core state unnormalised without anyone noticing.

The same absent boundary hardcodes the provider's language into core in three
places: `translation_provider.dart:49` hides translate buttons when the app
locale is `'pl'`, `translation_service.dart:31` defaults `sourceLang` to
`'pl'`, and `compose_message_view.dart:262` translates outgoing messages to
`'pl'`. All three are really asking "what language does the provider speak?",
a question `SchoolDataProvider` cannot answer.

The demo provider already writes canonical English (`'Mathematics'`,
`'Polish'`, `'Physics'`) straight into core state. It is the model; mobireg is
the outlier.

## Goals

- Core state holds canonical, provider-agnostic data, always, by construction.
- Each provider owns its wire format, its wording and its cache format.
- Core can ask a provider what language its free text is in.
- The boundary cannot rot back without a test failing.

## Non-goals

- Changing the cache format. Providers keep caching their own raw payloads;
  making the cache store canonical entities needs serialisers for every entity
  and a migration for existing caches, and overlaps the Drift layer that
  already owns durable storage.
- The lesson-topic translate button and the test detail sheet. Both are queued
  and both land after this, on the clean base.
- Any change to how `translateSubjectName` works. Rendering a canonical name in
  the reader's language is core presentation and stays where it is.

## The contract

The boundary is the core Riverpod state providers - `subjectsProvider`,
`resolvedEventsProvider`, `testsProvider`, `homeworksProvider`,
`attendanceTypesProvider`, `termsProvider` and the rest that
`loadSchoolData` fills.

Everything written into them is canonical: English vocabulary, provider-agnostic
shapes. A provider normalises on its own side of the line. Core never sees
provider wording and never imports provider code.

Two distinct concerns that this spec deliberately separates, because conflating
them is what produced the bug:

| concern | applies to | handled by | lives in |
|---|---|---|---|
| normalisation | provider vocabulary: subject names, attendance types, grade categories, term names | `normalizeMobireg*` | the provider |
| translation | teacher-authored free text: lesson topics, message bodies, notes, homework descriptions | `TranslationService` | core, steered by `contentLanguage` |

Vocabulary is never translated at runtime; it is normalised once and then
localised from the canonical form. Free text is never normalised; it is
translated on demand.

## `SchoolDataProvider` gains two members

In `lib/domain/school_data_provider.dart`:

```dart
/// The language the provider's free text is written in.
///
/// Teachers write lesson topics, messages and notes in this language. It is
/// not the language of subject names or attendance types - those are
/// normalised to canonical English before they reach core state.
String get contentLanguage;

/// Restores this provider's state from [cache]. Returns whether anything was
/// restored.
bool hydrateFromCache(Ref ref, SyncCache cache);
```

Both members are abstract. There are exactly two implementations,
`MobiregDataProvider` and `DemoDataProvider`, and both use `implements` rather
than `extends`, so a body on the interface would not be inherited anyway -
`DemoDataProvider` already re-declares `supports()` and `parseFcmMessage()` for
that reason. Declaring these abstract keeps the compiler asking each provider
the question rather than silently answering for it.

`contentLanguage`: mobireg `'pl'`, demo `'en'`.

`hydrateFromCache`: mobireg restores from the cache, demo returns `false`
because it regenerates its data on every load. The return value is what
`sync_provider` uses to decide `SyncStatus.hydrated`.

`SyncCache` (`lib/data/services/sync_cache.dart`) stays in core. It is a generic
keyed store, not a mobireg type; the provider is handed one.

## The move

`lib/data/services/sync_data_applier.dart` ->
`lib/data/providers/mobireg/mobireg_sync_applier.dart`.

The file moves whole: `applySyncData`, the four `applyPortal*` functions,
`applyPortalChangelog`, `applyMessages`, and the five `parse*` functions. The
six `normalizeMobireg*` calls inside it travel with it, including the three
added in 9be682d, which is how that commit's fix ends up on the provider side
without being rewritten.

`MobiregDataProvider.hydrateFromCache` absorbs the body of
`sync_provider._hydrateFromCache`: sync data, the four portal views, both
changelogs, and the three message folders. It returns whether sync data was
present, matching the existing `if (syncData != null)` condition.

`sync_provider` then keeps only:

```dart
final restored = ref.read(activeDataProviderProvider).hydrateFromCache(ref, cache);
if (restored) state = SyncStatus.hydrated;
```

and drops `import 'package:bsharp/data/services/sync_data_applier.dart';`.

After the move, every `normalizeMobireg*` call in the repository is under
`lib/data/providers/mobireg/`.

## `contentLanguage` replaces the hardcoded `'pl'`

| site | now | becomes |
|---|---|---|
| `lib/app/translation_provider.dart:49` | `if (locale.languageCode == 'pl') return false;` | compare against the active provider's `contentLanguage` |
| `lib/data/services/translation_service.dart:31` | `String sourceLang = 'pl'` | required parameter, caller supplies it |
| `lib/presentation/messages/widgets/compose_message_view.dart:262` | `targetLang: 'pl'` | `targetLang: <active provider>.contentLanguage` |

The two directions are symmetric and both follow from the same value: reading
translates provider language -> app locale, composing translates app locale ->
provider language so the teacher can read the reply. `_translateToPolish` is
renamed to something provider-neutral.

Making `sourceLang` required rather than defaulted is deliberate: a default is
how the wrong language got baked in, and the compiler should force each call
site to say which language it means.

## The boundary guard

A test that reads every `.dart` file under `lib/app`, `lib/core`, `lib/domain`,
`lib/presentation` and `lib/wear`, and fails on any import of
`package:bsharp/data/providers/`.

One allowlisted file: `lib/app/data_provider_registry.dart`, the composition
root, which must construct the concrete providers. The allowlist is a literal
set in the test, so adding to it is a visible decision in a diff.

This is the check that would have caught the original coupling, and it is what
stops the boundary rotting once the move is done.

## Testing

Moved, paths updated:

- `test/unit/data/sync_data_applier_test.dart` -> the new applier location. Its
  five cases already assert that portal parsing normalises subject names.

New:

- `hydrateFromCache` restores core state for mobireg from a populated cache and
  reports `true`; reports `false` for an empty cache; is a no-op returning
  `false` for demo.
- `isTranslationAvailable` is false when the app locale equals the active
  provider's `contentLanguage` and true otherwise, driven by a fake provider
  rather than by the literal `'pl'`, so the test does not re-assert the bug.
- The boundary guard test.

## Documentation

`docs/providers.md` documents the `SchoolDataProvider` interface as a table of
properties and methods. Both new members go in it, along with a short statement
of the contract: what a provider must normalise before writing to core state,
and what `contentLanguage` does and does not cover.

## Risks

- **`hydrateFromCache` signature.** Passing `Ref` and `SyncCache` to a provider
  keeps the current call shape and avoids inventing a transfer object, but it
  does mean the interface mentions two core types. Both are already shared
  infrastructure rather than provider-specific, so this is judged acceptable.
- **A third provider.** Only mobireg and demo exist today, so `contentLanguage`
  has two answers and both are known. A provider serving mixed-language content
  would not fit a single code, and would need the field reconsidered rather
  than stretched.
- **Nothing forces normalisation itself.** The guard test stops core importing
  provider code, but it cannot prove a provider normalised what it wrote. That
  would need canonical-form assertions per entity, which is deferred.
