import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

final studentsProvider = StateProvider<List<Student>>((ref) => []);

final activeStudentProvider = NotifierProvider<ActiveStudentNotifier, Student?>(
  ActiveStudentNotifier.new,
);

class ActiveStudentNotifier extends Notifier<Student?> {
  @override
  Student? build() {
    final students = ref.watch(studentsProvider);
    if (students.isEmpty) return null;

    final selectedIdAsync = ref.watch(selectedStudentIdProvider);
    final selectedId = selectedIdAsync.valueOrNull;
    if (selectedId != null) {
      final match = students.where((s) => s.id == selectedId);
      if (match.isNotEmpty) return match.first;
    }
    return students.first;
  }

  Future<void> switchTo(Student student) async {
    final storage = ref.read(credentialStorageProvider);
    await storage.saveSelectedStudentId(student.id);
    ref.invalidate(selectedStudentIdProvider);
  }
}

Student placeholderStudent() =>
    const Student(id: 0, usersEduId: 0, name: '', surname: '', sex: Sex.male);
