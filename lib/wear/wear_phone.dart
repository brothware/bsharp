import 'package:bsharp/app/router.dart';
import 'package:bsharp/wear/wear_host_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens Set up watch in BSharp on the paired phone, so the wearer does not
/// have to find it. The watch keeps saying where it is either way, so a
/// phone that cannot be reached only costs that shortcut.
Future<bool> openSetUpWatchOnPhone() async {
  try {
    return await wearHostChannel.invokeMethod<bool>('openOnPhone', {
          'url': watchSetupLink,
        }) ??
        false;
  } on MissingPluginException {
    debugPrint('openSetUpWatchOnPhone: no host implementation');
    return false;
  } on PlatformException catch (error) {
    debugPrint('openSetUpWatchOnPhone: ${error.code} ${error.message}');
    return false;
  }
}
