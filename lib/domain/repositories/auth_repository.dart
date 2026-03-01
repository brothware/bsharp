import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/student.dart';

abstract interface class AuthRepository {
  Future<Result<void>> login({
    required String school,
    required String login,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<PortalUser>> getPortalUser();

  Future<Result<List<Student>>> getStudents();

  Future<bool> isAuthenticated();

  Future<bool> hasStoredCredentials();

  Stream<bool> watchAuthState();
}
