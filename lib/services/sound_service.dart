import 'sound_factory.dart';

class SoundService {
  static final _player = createSoundPlayer();

  static Future<void> playBuzzer() async {
    await _player.play();
  }
}
