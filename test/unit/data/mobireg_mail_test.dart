import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session_registry.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/mobireg/fake_app_server.dart';

void main() {
  late ProviderContainer container;
  late FakeAppServer server;
  late MobiregDataProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    server = FakeAppServer.fromFixtures();
    provider = MobiregDataProvider(
      clientFactory: server.factoryFor,
      sessions: AppApiSessionRegistry(),
    );
  });

  Ref ref() => container.read(Provider((ref) => ref));

  Future<void> signedIn() async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadMessages(ref());
  }

  final failsWithMessaging = throwsA(isA<MessagingException>());

  test('loadMessages without a session reports mail as not loaded', () async {
    expect(await provider.loadMessages(ref()), isFalse);
  });

  test('loadMessages with a mailbox reports mail as loaded', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');

    expect(await provider.loadMessages(ref()), isTrue);
  });

  test('loadMessages fills the folders through one SSO', () async {
    await signedIn();

    expect(server.mailSignIns, 1);
    expect(container.read(inboxProvider).single.id, 20001);
  });

  test('two syncs sign in to the mailbox once', () async {
    await signedIn();
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadMessages(ref());

    expect(server.mailSignIns, 1);
    expect(
      server.mailPaths.where((path) => path == '/api/messages/inbox'),
      hasLength(2),
    );
  });

  test('a failed SSO fails loadMessages', () async {
    server.mailSignInFails = true;
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');

    await expectLater(provider.loadMessages(ref()), failsWithMessaging);
  });

  test('a failed folder fails loadMessages and keeps the cache', () async {
    await signedIn();
    server.mailFoldersFail = true;

    await expectLater(provider.loadMessages(ref()), failsWithMessaging);
    expect(
      container.read(syncCacheProvider).loadMessages('inbox'),
      hasLength(1),
    );
  });

  test('an account with no mailbox turns the mail features off', () async {
    server.users.remove('messagingUrl');
    server.users.remove('messagesToken');
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');

    await provider.loadMessages(ref());

    expect(server.mailSignIns, 0);
    expect(provider.supports(DataProviderCapability.messages), isFalse);
    expect(provider.supports(DataProviderCapability.sendMessages), isFalse);
  });

  test('switching to an account with no mailbox clears the mail', () async {
    await signedIn();
    expect(provider.supports(DataProviderCapability.messages), isTrue);
    server.users.remove('messagingUrl');
    server.users.remove('messagesToken');

    await provider.authenticate(school: 'sp2', login: 'p', password: 's');
    await provider.loadMessages(ref());

    expect(container.read(inboxProvider), isEmpty);
    expect(container.read(sentProvider), isEmpty);
    expect(container.read(trashProvider), isEmpty);
    expect(container.read(syncCacheProvider).loadMessages('inbox'), isEmpty);
    expect(provider.supports(DataProviderCapability.messages), isFalse);
    await expectLater(
      provider.sendMessage(recipientIds: ['user_1'], title: 'T', content: 'C'),
      failsWithMessaging,
    );
  });

  test('switching back to an account with a mailbox restores it', () async {
    await signedIn();
    server.users.remove('messagingUrl');
    server.users.remove('messagesToken');
    await provider.authenticate(school: 'sp2', login: 'p', password: 's');
    await provider.loadMessages(ref());

    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadMessages(ref());

    expect(provider.supports(DataProviderCapability.messages), isTrue);
    expect(container.read(inboxProvider).single.id, 20001);
  });

  for (final missing in ['messagingUrl', 'messagesToken']) {
    test('only $missing missing is a malformed users view', () async {
      server.users.remove(missing);
      await provider.authenticate(school: 'sp1', login: 'p', password: 's');

      await expectLater(
        provider.loadMessages(ref()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('users'),
          ),
        ),
      );
      expect(server.mailSignIns, 0);
    });
  }

  test('sending without a mail session fails', () async {
    await expectLater(
      provider.sendMessage(recipientIds: ['user_1'], title: 'T', content: 'C'),
      failsWithMessaging,
    );
  });

  test('every mail action without a session fails', () async {
    await expectLater(provider.readMessage(1), failsWithMessaging);
    await expectLater(provider.searchReceivers('Nowak'), failsWithMessaging);
    await expectLater(provider.toggleStar(1), failsWithMessaging);
    await expectLater(provider.deleteMessage(1), failsWithMessaging);
    await expectLater(provider.restoreMessage(1), failsWithMessaging);
    await expectLater(provider.loadMoreInbox(20), failsWithMessaging);
    await expectLater(
      provider.downloadAttachment('/files/1', 'a.pdf'),
      failsWithMessaging,
    );
  });

  test('a rejected mail action surfaces its failure', () async {
    await signedIn();
    server.mailFoldersFail = true;

    await expectLater(provider.loadMoreInbox(20), failsWithMessaging);
    await expectLater(provider.refreshMessages(ref()), failsWithMessaging);
  });

  test('a receiver that is not an object is a FormatException', () async {
    server.receivers = <Object>['Nowak'];
    await signedIn();

    await expectLater(provider.searchReceivers('Nowak'), throwsFormatException);
  });
}
