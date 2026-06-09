import 'sound_interface.dart';
import 'sound_stub.dart' if (dart.library.js) 'sound_web.dart';

SoundPlayer createSoundPlayer() => SoundPlayerImpl();
