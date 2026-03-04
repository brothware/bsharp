# Adding Data Providers

BSharp uses a `SchoolDataProvider` abstraction to decouple the UI from any specific e-Grade backend. Each provider implements a common interface, declares its capabilities, and the UI automatically adapts — tabs and screens for unsupported features are hidden.

## SchoolDataProvider Interface

Defined in [`lib/domain/school_data_provider.dart`](../lib/domain/school_data_provider.dart):

| Property / Method | Description |
|-------------------|-------------|
| `id` | Unique string identifier (e.g., `'mobireg'`, `'demo'`) |
| `displayName` | Human-readable name shown in the UI |
| `capabilities` | `Set<DataProviderCapability>` declaring supported features |
| `requiresCredentials` | Whether the provider needs login credentials |
| `supports(cap)` | Convenience check: `capabilities.contains(cap)` |
| `authenticate(...)` | Establish a session with `school`, `login`, `passwordHash` |
| `loadSchoolData(ref, studentId:)` | Populate Riverpod state with grades, schedule, attendance, etc. |
| `loadMessages(ref)` | Load inbox, sent, and trash messages |
| `refreshMessages(ref)` | Refresh messages from the server |
| `readMessage(messageId)` | Fetch full message content |
| `searchReceivers(query)` | Search for message recipients |
| `toggleStar(messageId)` | Star/unstar a message |
| `deleteMessage(messageId)` | Move a message to trash |
| `restoreMessage(messageId)` | Restore a message from trash |
| `sendMessage(...)` | Send a message with `recipientIds`, `title`, `content`, optional `previousMessageId` |
| `loadMoreInbox(skip)` | Paginated inbox loading |
| `hashPassword(password)` | Hash a plaintext password for this system |
| `validateCredentials(...)` | Check credentials without full login, returns `Result<void>` |
| `fetchStudents(...)` | List available students for the authenticated account |

## DataProviderCapability

Each capability gates a UI feature. If a provider doesn't declare a capability, the corresponding tab or screen is hidden.

| Capability | UI Feature |
|------------|------------|
| `grades` | Grades tab, mark details |
| `schedule` | Timetable / schedule view |
| `attendance` | Attendance tab and statistics |
| `messages` | Messages inbox and detail |
| `sendMessages` | Compose / reply buttons (requires `messages` too) |
| `homework` | Homework list |
| `tests` | Tests / exams calendar |
| `notes` | Notes and reprimands |
| `bulletins` | School announcements |
| `changelog` | Changelog / activity feed |

## How to Implement a New Provider

### 1. Create the provider class

Create `lib/data/providers/my_system_data_provider.dart`:

```dart
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MySystemDataProvider implements SchoolDataProvider {
  @override
  String get id => 'my_system';

  @override
  String get displayName => 'My System';

  @override
  Set<DataProviderCapability> get capabilities => {
    DataProviderCapability.grades,
    DataProviderCapability.schedule,
    DataProviderCapability.attendance,
    // only declare what your system supports
  };

  @override
  bool get requiresCredentials => true;

  // ... implement all methods
}
```

### 2. Set `id`, `displayName`, and `capabilities`

- `id` must be unique across all providers
- `displayName` is shown to the user during school selection
- Only include capabilities your system actually supports — the UI adapts automatically

### 3. Implement authentication

```dart
@override
Future<void> authenticate({
  required String school,
  required String login,
  required String passwordHash,
}) async {
  // establish session, store tokens, etc.
}

@override
String hashPassword(String password) {
  // return hashed password for your system's auth scheme
}

@override
Future<Result<void>> validateCredentials({
  required String school,
  required String login,
  required String passwordHash,
}) async {
  // verify credentials without full login
  // return Result.success(null) or Result.failure(AppFailure.wrongCredentials())
}

@override
Future<List<Student>> fetchStudents({
  required String school,
  required String login,
  required String passwordHash,
}) async {
  // return list of students linked to this account
}
```

### 4. Implement `loadSchoolData`

This is the main data sync method. Populate Riverpod notifiers with your system's data:

```dart
@override
Future<void> loadSchoolData(Ref ref, {required int studentId}) async {
  // fetch data from your API
  // populate providers, e.g.:
  // ref.read(studentsProvider.notifier).value = students;
  // ref.read(teachersProvider.notifier).value = teachers;
  // ref.read(subjectsProvider.notifier).value = subjects;
  // etc.
}
```

### 5. Implement messages (or skip)

If your provider doesn't support messages, exclude `DataProviderCapability.messages` from capabilities. The message methods must still exist (interface requirement) but can throw `UnimplementedError`:

```dart
@override
Future<void> loadMessages(Ref ref) => throw UnimplementedError();
```

### 6. Register the provider

Add your provider to `lib/app/data_provider_registry.dart` so it can be selected at runtime.

## Existing Implementations

| Provider | File | Capabilities | Credentials |
|----------|------|-------------|-------------|
| **Mobireg** | `lib/data/providers/mobireg_data_provider.dart` | All (grades, schedule, attendance, messages, sendMessages, homework, tests, notes, bulletins, changelog) | Yes (MD5 password hash) |
| **Demo** | `lib/data/providers/demo_data_provider.dart` | All except `sendMessages` | No (synthetic data, no network) |

Mobireg provider documentation (API details, data model, error codes) is in [`docs/providers/mobireg/`](providers/mobireg/README.md).

## Domain Entities

Providers must produce instances of these shared domain entities. All are Freezed data classes in `lib/domain/entities/`:

| Entity | File |
|--------|------|
| `Student` | `student.dart` |
| `Teacher` | `teacher.dart` |
| `Subject` | `subject.dart` |
| `Term` | `term.dart` |
| `Event` (lesson) | `event.dart` |
| `Mark` (grade) | `mark.dart` |
| `Attendance` | `attendance.dart` |
| `AttendanceType` | `attendance_type.dart` |
| `MarkGroup` | `mark_group.dart` |
| `MarkScale` | `mark_scale.dart` |
| `MarkKind` | `mark_kind.dart` |
| `Homework` | `homework.dart` |
| `Test` | `test_entity.dart` |
| `UserReprimand` (note) | `user_reprimand.dart` |
| `Bulletin` | `bulletin.dart` |
| `PocztaMessage` | `poczta.dart` |
