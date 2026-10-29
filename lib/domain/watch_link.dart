import 'package:bsharp/domain/entities/account_handoff.dart';

abstract interface class WatchLink {
  /// Whether this phone has a watch companion app (Wear OS or Galaxy
  /// Wearable) installed, which is as close as Android lets an app get to
  /// knowing a watch is paired.
  Future<bool> hasPairedWatch();

  Future<bool> hasConnectedCounterpart();

  Future<void> sendAccount(AccountHandoff account);

  Stream<AccountHandoff> get receivedAccounts;
}
