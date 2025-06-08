# android_haptics

A bug workaround for Android haptic feedback.

## Purpose

This is a minimal implementation of Android haptic feedback using the
`Vibrator` API.  This might help work around a bug where Flutter's
`HapticFeedback` class doesn't work on some Android platforms.

This is a quick hack with just enough of the API implemented for a
specific project.  Most people seem to use the 
[vibration](https://pub.dev/packages/vibration) package.  The only reason
I didn't do that was to avoid an external dependency to a package with an
unverified uploader, and any possibility of future compatibility issues
(e.g. around WASMJ.

