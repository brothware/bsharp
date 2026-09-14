import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('pl.brothware.bsharp/wear');

/// Asks the watch for a line of text on its own input screen.
///
/// Flutter draws its fields itself and tells the keyboard not to go full
/// screen, which the watch keyboard can only half honour: it fills the screen
/// anyway and its copy of the text stops updating after the first letter. The
/// system screen owns the text it shows, and offers voice and handwriting
/// besides.
///
/// Returns null when the wearer backs out, or when the host has no such
/// screen, in which case the caller keeps whatever it had.
Future<String?> requestWearTextInput({required String label}) async {
  try {
    return await _channel.invokeMethod<String>('requestTextInput', {
      'label': label,
    });
  } on MissingPluginException {
    debugPrint('requestWearTextInput: no host implementation');
    return null;
  } on PlatformException catch (error) {
    debugPrint('requestWearTextInput: $error');
    return null;
  }
}
