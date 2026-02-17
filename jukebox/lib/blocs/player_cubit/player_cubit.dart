import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/models/song_model.dart';
import 'package:just_audio/just_audio.dart';

part 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit() : super(AudioPlayerInitial());

  List<String> playlist = []; // List of audio URLs or file paths
  List<SongModel> songList = [];
  int _currentIndex = 0;

  final ValueNotifier<SongModel?> actifSong = ValueNotifier(null);
  final AudioPlayer audioPlayer = AudioPlayer();
  ConcatenatingAudioSource? audioSource;

  Future<void> play(SongModel song) async {
    try {
      // await audioPlayer.setUrl(song.audio);

      // audioPlayer.setAudioSource(audioSource!);

      _currentIndex = playlist.indexWhere((item) => item == song.audio);
      print("#####");
      print(_currentIndex);
      print("#####");
      audioPlayer.seek(Duration.zero, index: _currentIndex);

      actifSong.value = song;
      audioPlayer.play();
      emit(AudioPlayerPlaying());
    } catch (e) {
      print('audio url error');
    }
  }

  // Mettre en pause
  Future<void> pause() async {
    await audioPlayer.pause();
    emit(AudioPlayerPaused());
  }

  // Reprendre la lecture
  Future<void> resume() async {
    audioPlayer.play();
    emit(AudioPlayerPlaying());
  }

  endAudio() async {
    audioPlayer.stop();
    emit(AudioPlayerEnd());
  }

  void next() {
    if (_currentIndex < songList.length - 1) {
      _currentIndex += 1;
    }

    final song = songList.firstWhere(
      (item) => item.audio == playlist[_currentIndex],
      orElse: () => songList[0],
    );
    audioPlayer.seekToNext();
    actifSong.value = song;
    emit(AudioPlayerPlaying());
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex -= 1;
    }

    final song = songList.firstWhere(
      (item) => item.audio == playlist[_currentIndex],
      orElse: () => songList[0],
    );
    audioPlayer.seekToPrevious();
    actifSong.value = song;
    emit(AudioPlayerPlaying());
  }

  Future<void> playList() async {
    audioPlayer.play();
    emit(AudioPlayerPlaying());
  }

  // Libérer les ressources du lecteur
  @override
  Future<void> close() {
    audioPlayer.dispose();
    return super.close();
  }
}
