package com.jovial.android_haptics;

import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.media.AudioAttributes;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** AndroidHapticsPlugin */
public class AndroidHapticsPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private Vibrator vibrator;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            vibrator = oldGetVibrator(flutterPluginBinding);
        } else {
            final VibratorManager vibratorManager = 
                (VibratorManager) flutterPluginBinding.getApplicationContext().getSystemService(
                        Context.VIBRATOR_MANAGER_SERVICE);
            vibrator = vibratorManager.getDefaultVibrator();
        }


        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "android_haptics");
        channel.setMethodCallHandler(this);
    }

    @SuppressWarnings("deprecation")
    private Vibrator oldGetVibrator(@NonNull FlutterPluginBinding flutterPluginBinding) {
        return (Vibrator) flutterPluginBinding.getApplicationContext().getSystemService(Context.VIBRATOR_SERVICE);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("selectionClick")) {
            vibrate(127);
            result.success(null);
        } else if (call.method.equals("heavyImpact")) {
            vibrate(255);
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @SuppressWarnings("deprecation")
    private void vibrate(int amplitude) {
        int duration = 15;      
        // "Between 10 and 20 milliseconds" https://developer.android.com/develop/ui/views/haptics/haptics-principles
        if (vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (vibrator.hasAmplitudeControl()) {
                    vibrator.vibrate(VibrationEffect.createOneShot(duration, amplitude), new AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build());
                } else {
                    vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE), 
                            new AudioAttributes.Builder()
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .build());
                }
            } else {
                vibrator.vibrate(duration);
            }
        }
    }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
