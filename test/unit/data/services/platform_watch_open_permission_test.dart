import 'package:bsharp/data/services/platform_watch_open_permission.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('pl.brothware.bsharp/phone');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  const permission = PlatformWatchOpenPermission();

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  test('names the watch the phone reports as connected', () async {
    answer((_) => 'Galaxy Watch6 Classic (9AFD)');

    expect(
      await permission.connectedWatchName(),
      'Galaxy Watch6 Classic (9AFD)',
    );
    expect(calls.single.method, 'connectedWatchName');
  });

  test('with no watch connected there is no name', () async {
    answer((_) => null);

    expect(await permission.connectedWatchName(), isNull);
  });

  test('a phone without the channel names no watch', () async {
    expect(await permission.connectedWatchName(), isNull);
  });

  test('asks the phone to open its app list', () async {
    answer((_) => null);

    await permission.openAppList();

    expect(calls.single.method, 'openAppList');
  });

  test('an app list that cannot be opened is reported', () async {
    answer((_) => throw PlatformException(code: 'no_settings'));

    await expectLater(
      permission.openAppList(),
      throwsA(isA<PlatformException>()),
    );
  });
}
