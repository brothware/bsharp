> **Disclaimer**: BSharp is an unofficial, independently developed client for the Mobireg e-Dziennik system. It is not affiliated with, endorsed by, or supported by Mobireg. The underlying API is undocumented and may change without notice, which could break functionality at any time. Use at your own risk.

# BSharp

[![CI](https://github.com/brothware/bsharp/actions/workflows/ci.yml/badge.svg)](https://github.com/brothware/bsharp/actions/workflows/ci.yml)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B.svg?logo=flutter)](https://flutter.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Wear%20OS-green.svg)](#platforms)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-dawidsliwas-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/dawidsliwas)

Unofficial Flutter client for the [Mobireg](https://mobireg.pl) e-Dziennik (electronic grade book) system used by Polish schools.

## Features

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
| **Domain** | `lib/domain/` | Entities, repository interfaces, business rules |
| **Data** | `lib/data/` | API clients, local database (Drift), repository implementations |
| **Presentation** | `lib/presentation/` | UI components, state management (Riverpod), routing (GoRouter) |

Key technical choices:
- **State management**: Riverpod
- **Navigation**: GoRouter
- **Networking**: Dio (5 independent API endpoints)
- **Local database**: Drift (37 tables, schema v2)
- **Code generation**: Freezed, json_serializable, slang
- **i18n**: Slang (English base locale, 37 languages via ML Kit)

## Documentation

| Document | Description |
|----------|-------------|
| [API Reference](docs/README.md) | Reverse-engineered Mobireg API documentation |
| [OpenAPI Spec](docs/openapi.yaml) | OpenAPI 3.0 specification for all endpoints |
| [Data Model](docs/data-model.md) | Entity relationships and all 36 synced tables |
| [Error Codes](docs/error-codes.md) | API error codes and their meanings |

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

## License

GPL-3.0 — see [LICENSE](LICENSE) for details.
