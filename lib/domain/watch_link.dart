import 'package:bsharp/domain/entities/account_handoff.dart';

abstract interface class WatchLink {
  Future<bool> hasConnectedCounterpart();

  Future<void> sendAccount(AccountHandoff account);

  Stream<AccountHandoff> get receivedAccounts;
}
