import 'dart:async';

/// Runs tasks one at a time, in the order they were added.
///
/// A failing task does not stop the ones behind it; its error surfaces only to
/// whoever awaited that task.
class SerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> add<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then((_) {}, onError: (_, _) {});
    return result;
  }
}
