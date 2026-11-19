import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Son de démarrage (moteur de supercar). Le fichier se trouve dans
/// assets/audio/engine_start.wav : remplace-le par ton propre son si tu veux.
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playStartup() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      // AssetSource cherche dans le dossier assets/ : on écrit donc
      // « audio/engine_start.wav » pour assets/audio/engine_start.wav.
      await _player.play(AssetSource('audio/engine_start.wav'));
    } catch (e) {
      // Un son qui échoue ne doit jamais bloquer l'appli.
      debugPrint('Son de démarrage impossible : $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
