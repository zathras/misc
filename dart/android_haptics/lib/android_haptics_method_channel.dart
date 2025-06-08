import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_haptics_platform_interface.dart';

/// An implementation of [AndroidHapticsPlatform] that uses method channels.
class MethodChannelAndroidHaptics extends AndroidHapticsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('android_haptics');

  @override
  Future<void> selectionClick() =>
      methodChannel.invokeMethod<void>('selectionClick');

  @override
  Future<void> heavyImpact() =>
      methodChannel.invokeMethod<void>('heavyImpact');
}
