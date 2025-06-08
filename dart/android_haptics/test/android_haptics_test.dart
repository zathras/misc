import 'package:flutter_test/flutter_test.dart';
import 'package:android_haptics/android_haptics.dart';
import 'package:android_haptics/android_haptics_platform_interface.dart';
import 'package:android_haptics/android_haptics_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAndroidHapticsPlatform
    with MockPlatformInterfaceMixin
    implements AndroidHapticsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AndroidHapticsPlatform initialPlatform = AndroidHapticsPlatform.instance;

  test('$MethodChannelAndroidHaptics is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAndroidHaptics>());
  });

  test('getPlatformVersion', () async {
    AndroidHaptics androidHapticsPlugin = AndroidHaptics();
    MockAndroidHapticsPlatform fakePlatform = MockAndroidHapticsPlatform();
    AndroidHapticsPlatform.instance = fakePlatform;

    expect(await androidHapticsPlugin.getPlatformVersion(), '42');
  });
}
