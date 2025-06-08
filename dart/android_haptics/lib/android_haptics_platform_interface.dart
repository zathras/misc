import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'android_haptics_method_channel.dart';

abstract class AndroidHapticsPlatform extends PlatformInterface {
  /// Constructs a AndroidHapticsPlatform.
  AndroidHapticsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AndroidHapticsPlatform _instance = MethodChannelAndroidHaptics();

  /// The default instance of [AndroidHapticsPlatform] to use.
  ///
  /// Defaults to [MethodChannelAndroidHaptics].
  static AndroidHapticsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AndroidHapticsPlatform] when
  /// they register themselves.
  static set instance(AndroidHapticsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> selectionClick() {
    throw UnimplementedError();
  }

  Future<void> heavyImpact() {
    throw UnimplementedError();
  }
}
