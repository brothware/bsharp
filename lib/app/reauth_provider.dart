import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reauth_provider.g.dart';

@Riverpod(keepAlive: true)
class ReauthRequired extends _$ReauthRequired {
  @override
  bool build() => false;
  bool get value => state;
  set value(bool v) => state = v;
}

@Riverpod(keepAlive: true)
class MissingPupil extends _$MissingPupil {
  @override
  bool build() {
    ref.listen(activeSelectionProvider, (previous, next) {
      if (!_isSameSelection(previous?.value, next.value)) {
        state = false;
      }
    });
    return false;
  }

  bool get value => state;
  set value(bool v) => state = v;
}

bool _isSameSelection(ActiveSelection? first, ActiveSelection? second) =>
    first?.accountId == second?.accountId &&
    first?.studentId == second?.studentId;
