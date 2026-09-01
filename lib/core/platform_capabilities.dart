import 'package:flutter/foundation.dart';

bool get isPushSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
