import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/providers/demo_data_provider.dart';
import 'package:bsharp/data/providers/mobireg_data_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';

final activeDataProviderProvider = StateProvider<SchoolDataProvider>(
  (ref) => MobiregDataProvider(),
);

final demoModeProvider = StateProvider<bool>((ref) => false);

final _demoActivatorProvider = Provider<_DemoActivator>((ref) {
  return _DemoActivator(ref);
});

class _DemoActivator {
  _DemoActivator(this._ref);
  final Ref _ref;

  Future<void> activate() async {
    final provider = DemoDataProvider();
    _ref.read(activeDataProviderProvider.notifier).state = provider;
    _ref.read(demoModeProvider.notifier).state = true;
    await provider.loadSchoolData(_ref, studentId: 1);
    await provider.loadMessages(_ref);
    await _ref.read(authStateProvider.notifier).completeSetup();
  }
}

Future<void> activateDemoMode(WidgetRef ref) async {
  await ref.read(_demoActivatorProvider).activate();
}
