import 'package:audioplayers/audioplayers.dart';

// NEW: A completely new, more descriptive enum for our sounds
enum Sound {
  blip,
  voiceWakeup,
  voiceSleep,
  voiceGiggle,
  voiceThirsty,
  voiceHungry,
  voiceHot,
  voiceRootsDry,
  voiceTooBright,
  voiceSunshine,
  sfxError,
}

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  late AudioPlayer _sfxPlayer;
  late AudioPlayer _loopingPlayer;

  // NEW: Updated map with new filenames
  final Map<Sound, String> _soundPaths = {
    Sound.blip: 'sounds/tap.mp3',
    Sound.voiceWakeup: 'sounds/voice_wakeup.mp3',
    Sound.voiceSleep: 'sounds/sleep.mp3',
    Sound.voiceGiggle: 'sounds/happy.mp3',
    Sound.voiceThirsty: 'sounds/happy.mp3',
    Sound.voiceHungry: 'sounds/happy.mp3',
    Sound.voiceHot: 'sounds/happy.mp3',
    Sound.voiceRootsDry: 'sounds/voice_rootsdry.mp3',
    Sound.voiceTooBright: 'sounds/voice_toobright.mp3',
    Sound.voiceSunshine: 'sounds/happy.mp3',
    Sound.sfxError: 'sounds/error.mp3',
  };
  final String _dreamingLoopPath = 'sounds/dreaming_loop.mp3';

  Future<void> init() async {
    _sfxPlayer = AudioPlayer();
    _loopingPlayer = AudioPlayer();
    _loopingPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void play(Sound sound) {
    if (_soundPaths.containsKey(sound)) {
      _sfxPlayer.play(AssetSource(_soundPaths[sound]!));
    }
  }

  void startDreamingLoop() {
    _loopingPlayer.play(AssetSource(_dreamingLoopPath));
    _loopingPlayer.setVolume(0.4); // Ambient should be subtle
  }

  void stopDreamingLoop() {
    _loopingPlayer.stop();
  }

  void dispose() {
    _sfxPlayer.dispose();
    _loopingPlayer.dispose();
  }
}