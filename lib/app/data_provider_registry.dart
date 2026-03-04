import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/providers/demo_data_provider.dart';
import 'package:bsharp/data/providers/mobireg_data_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_provider_registry.g.dart';

@Riverpod(keepAlive: true)
class ActiveDataProvider extends _$ActiveDataProvider {
  @override
  SchoolDataProvider build() => MobiregDataProvider();
  SchoolDataProvider get value => state;
  set value(SchoolDataProvider v) => state = v;
}

@Riverpod(keepAlive: true)
class DemoMode extends _$DemoMode {
  @override
  bool build() => false;
  bool get value => state;
  set value(bool v) => state = v;
}

final _demoActivatorProvider = Provider<_DemoActivator>((ref) {
  return _DemoActivator(ref);
});

class _DemoActivator {
  _DemoActivator(this._ref);
  final Ref _ref;

  Future<void> activate() async {
    final provider = DemoDataProvider();
    _ref.read(activeDataProviderProvider.notifier).value = provider;
    _ref.read(demoModeProvider.notifier).value = true;
    await provider.loadSchoolData(_ref, studentId: 1);
    await provider.loadMessages(_ref);
    await _ref.read(authStateProvider.notifier).completeSetup();
  }
}

Future<void> activateDemoMode(WidgetRef ref) async {
  await ref.read(_demoActivatorProvider).activate();
}
