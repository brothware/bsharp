import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'child_provider.g.dart';

@Riverpod(keepAlive: true)
class Students extends _$Students {
  @override
  List<Student> build() => [];
  List<Student> get value => state;
  set value(List<Student> v) => state = v;
}

@Riverpod(keepAlive: true)
class ActiveStudent extends _$ActiveStudent {
  @override
  Student? build() {
    final students = ref.watch(studentsProvider);
    if (students.isEmpty) return null;

    final selectedIdAsync = ref.watch(selectedStudentIdProvider);
    final selectedId = selectedIdAsync.value;
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
