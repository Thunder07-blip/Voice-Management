import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin Android bridge for leave-request alerts. Keeping this native avoids a
/// package dependency and still uses Android's real notification tray.
class DeviceNotificationService {
  static const _channel = MethodChannel('com.vedicoasis.voice_app/notifications');

  static Future<void> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('requestNotificationPermission');
    } on PlatformException {
      // The in-app notification center remains available if Android denies it.
    }
  }

  static Future<void> showLeaveRequest(String body) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('showLeaveRequest', {'body': body});
    } on PlatformException {
      // A system-notification error must never interrupt Realtime syncing.
    }
  }
}
