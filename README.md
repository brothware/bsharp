# BSharp

[![CI](https://github.com/brothware/bsharp/actions/workflows/ci.yml/badge.svg)](https://github.com/brothware/bsharp/actions/workflows/ci.yml)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B.svg?logo=flutter)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Wear%20OS-green.svg)](#platforms)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-dawidsliwas-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/dawidsliwas)

A universal e-Grade system aggregator for Polish schools. BSharp connects to multiple electronic grade book systems through pluggable data providers, giving parents and students a single app for grades, attendance, schedules, and messages.

> **Note**: BSharp is an independently developed, open-source project. It is not affiliated with or endorsed by any e-Grade system vendor.

## Features

- **Pluggable data providers** — connect to multiple e-Grade systems through a single app
- **Grades** — view marks, averages, and grade history per subject
- **Attendance** — daily attendance records with absence/late tracking
- **Timetable** — weekly schedule with substitutions and cancellations
- **Homework & tests** — upcoming assignments and exam calendar
- **Notes & reprimands** — teacher remarks and behavioral notes
- **Bulletins** — school announcements and newsletters
- **Messages** — full inbox/outbox with send, reply, and attachments
- **Wear OS companion** — quick glance at today's schedule and grades
- **37 languages** — on-device ML Kit translation with optional DeepL
- **Offline-first** — local database sync with background refresh
- **Dark / light / system themes**
- **Child mode** — PIN-locked mode for installing on a child's phone/watch, hiding sensitive features like teacher messages
- **Background sync with notifications**

### Supported Systems

| System | Status | Notes |
|--------|--------|-------|
| [Mobireg](https://mobireg.pl) | Available | Full-featured: all capabilities supported |
| More providers | Planned | See [Adding Data Providers](docs/providers.md) |

> **Mobireg disclaimer**: The Mobireg integration is based on an unofficial, undocumented API that is not affiliated with or endorsed by Mobireg. This API may change without notice, which could break functionality at any time. Use at your own risk.

## Platforms

| Platform | Status |
|----------|--------|
| Android | Supported |
| iOS | Supported |
| Web | Supported |
| Wear OS | Supported |

## Quick Start

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.38+
- Android Studio / Xcode (for mobile builds)
- Chrome (for web builds)

### Setup

```bash
git clone https://github.com/brothware/bsharp.git
cd bsharp
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Architecture

BSharp follows **clean architecture** with three layers:

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| **Domain** | `lib/domain/` | Entities, repository interfaces, `SchoolDataProvider` contract |
| **Data** | `lib/data/` | Provider implementations, API clients, local database (Drift) |
| **Presentation** | `lib/presentation/` | UI components, state management (Riverpod), routing (GoRouter) |

The `SchoolDataProvider` abstraction (`lib/domain/school_data_provider.dart`) decouples the UI from any specific e-Grade backend. Each provider declares its capabilities via `DataProviderCapability`, and the UI automatically shows or hides features based on what the active provider supports. A provider registry (`lib/app/data_provider_registry.dart`) manages the active provider at runtime.

Key technical choices:
- **State management**: Riverpod with `@riverpod` codegen
- **Navigation**: GoRouter
- **Networking**: Dio (provider-specific API endpoints)
- **Local database**: Drift (39 tables, schema v3)
- **Code generation**: Freezed, json_serializable, slang
- **i18n**: Slang 4 (English base locale, 37 languages via ML Kit)

## Documentation

| Document | Description |
|----------|-------------|
| [Mobireg Provider](docs/providers/mobireg/README.md) | Mobireg provider implementation guide |
| [Data Model](docs/providers/mobireg/data-model.md) | Entity relationships and synced tables |
| [Error Codes](docs/providers/mobireg/error-codes.md) | API error codes and app failure mapping |
| [Adding Data Providers](docs/providers.md) | Guide to implementing new e-Grade system providers |

## Building

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Wear OS

```bash
flutter build apk --release --flavor wear
```

## Contributing

```bash
dart format .
dart analyze
flutter test
```

All pull requests must pass CI (format, analyze, test) before merging.

To add support for a new e-Grade system, implement the `SchoolDataProvider` interface and register it in the provider registry. See [docs/providers.md](docs/providers.md) for a step-by-step guide.

## License

GPL-3.0 — see [LICENSE](LICENSE) for details.
