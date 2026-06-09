import 'dart:js' as js;
import 'sound_interface.dart';

class SoundPlayerImpl implements SoundPlayer {
  @override
  Future<void> play() async {
    try {
      js.context.callMethod('eval', [
        """
        (function() {
          var AudioContext = window.AudioContext || window.webkitAudioContext;
          if (!AudioContext) return;
          var ctx = new AudioContext();
          var osc = ctx.createOscillator();
          var gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.value = 1000; // 1000Hz frequency
          gain.gain.setValueAtTime(0.6, ctx.currentTime);
          
          osc.connect(gain);
          gain.connect(ctx.destination);
          
          osc.start();
          // Beep for 1.0 second
          osc.stop(ctx.currentTime + 1.0);
        })();
        """
      ]);
    } catch (e) {
      print('Error playing web beep: $e');
    }
  }
}
