import 'package:flutter/services.dart';
import 'sound_interface.dart';

class SoundPlayerImpl implements SoundPlayer {
  static const MethodChannel _channel = MethodChannel('com.schoolevm/buzzer');

  @override
  Future<void> play() async {
    try {
      await _channel.invokeMethod('playBeep');
    } on PlatformException catch (e) {
      print("Failed to play native beep: '${e.message}'.");
    }
  }
}
