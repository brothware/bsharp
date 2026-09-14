import 'dart:async';

import 'package:bsharp/core/network/serial_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SerialQueue', () {
    test('never runs two tasks at the same time', () async {
      final queue = SerialQueue();
      final gates = List.generate(3, (_) => Completer<void>());
      var running = 0;
      var peak = 0;

      final tasks = [
        for (var i = 0; i < gates.length; i++)
          queue.add(() async {
            running++;
            peak = running > peak ? running : peak;
            await gates[i].future;
            running--;
            return i;
          }),
      ];

      for (final gate in gates) {
        await Future<void>.delayed(Duration.zero);
        gate.complete();
      }

      expect(await Future.wait(tasks), [0, 1, 2]);
      expect(
        peak,
        1,
        reason:
            'a portal token dies on first use and a second login kills the '
            'one before it, so two overlapping requests strand each other',
      );
    });

    test('a failing task does not block the ones behind it', () async {
      final queue = SerialQueue();

      final failing = queue.add<int>(() async => throw StateError('boom'));
      final following = queue.add<int>(() async => 7);

      await expectLater(failing, throwsStateError);
      expect(await following, 7);
    });

    test('a task added later still waits for the one in flight', () async {
      final queue = SerialQueue();
      final gate = Completer<void>();
      final order = <String>[];

      final first = queue.add(() async {
        await gate.future;
        order.add('first');
        return 1;
      });
      final second = queue.add(() async {
        order.add('second');
        return 2;
      });

      gate.complete();
      await Future.wait([first, second]);

      expect(order, ['first', 'second']);
    });
  });
}
