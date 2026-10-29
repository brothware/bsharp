import 'package:bsharp/domain/entities/account_handoff.dart';

abstract interface class WatchLink {
  /// Whether this phone has a watch companion app (Wear OS or Galaxy
  /// Wearable) installed, which is as close as Android lets an app get to
  /// knowing a watch is paired.
  Future<bool> hasPairedWatch();

  Future<bool> hasConnectedCounterpart();

  /// Sends [account] to the watch and answers whether the watch said it
  /// got it. A watch that is not on its Use phone screen does not answer.
  Future<bool> sendAccount(AccountHandoff account);

  Stream<AccountHandoff> get receivedAccounts;

  /// Tells the phone the account it sent was taken. Only for an account the
  /// watch actually goes on to use, so the phone does not report an ignored
  /// or refused one as received.
  Future<void> acknowledgeAccount();
}
