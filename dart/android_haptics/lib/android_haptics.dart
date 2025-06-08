
import 'android_haptics_platform_interface.dart';

class AndroidHaptics {
  /**
   * Use the Android vibrate API to do soemthing like Dart's
   * HapticFeedback.selectionClick().
   */
  static Future<void> selectionClick() {
    return AndroidHapticsPlatform.instance.selectionClick();
  }

  /**
   * Use the Android vibrate API to do soemthing like Dart's
   * HapticFeedback.heavyImpact().
   */
  static Future<void> heavyImpact() {
    return AndroidHapticsPlatform.instance.heavyImpact();
  }
}
