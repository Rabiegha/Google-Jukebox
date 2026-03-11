import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/models/song_model.dart';
import 'package:just_audio/just_audio.dart';

part 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit() : super(AudioPlayerInitial());

  List<String> playlist = []; // Currently loaded audio source URLs
  List<SongModel> songList = []; // Currently loaded audio source songs
  List<String> currentGenrePlaylist = []; // Songs of the displayed genre
  List<SongModel> currentGenreSongList = []; // Song models of displayed genre
  int _currentIndex = 0;

  final ValueNotifier<SongModel?> actifSong = ValueNotifier(null);
  final AudioPlayer audioPlayer = AudioPlayer();
  ConcatenatingAudioSource? audioSource;

  Future<void> play(SongModel song) async {
    try {
      // Check if the song is in the current genre playlist
      // If so, load that genre's playlist as the audio source
      final genreIndex = currentGenrePlaylist.indexWhere((item) => item == song.audio);
      
      if (genreIndex >= 0) {
        // Song is in the currently displayed genre — load its playlist
        if (playlist != currentGenrePlaylist || playlist.isEmpty) {
          // Need to switch audio source to the displayed genre
          final newSource = ConcatenatingAudioSource(
            children: currentGenrePlaylist
                .map((item) => AudioSource.uri(Uri.parse(item)))
                .toList(),
          );
          await audioPlayer.setAudioSource(newSource, initialIndex: genreIndex);
          playlist = List.from(currentGenrePlaylist);
          songList = List.from(currentGenreSongList);
        } else {
          // Same playlist, just seek to the right index
          await audioPlayer.seek(Duration.zero, index: genreIndex);
        }
        _currentIndex = genreIndex;
      } else {
        // Song not in current genre playlist — play directly by URL
        await audioPlayer.setUrl(song.audio);
        _currentIndex = 0;
      }

      actifSong.value = song;
      audioPlayer.play();
      emit(AudioPlayerPlaying());
    } catch (e) {
      print('audio url error: $e');
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

  /// Stop playback and reset state (e.g. when switching categories)
  Future<void> stop() async {
    await audioPlayer.stop();
    _currentIndex = 0;
    emit(AudioPlayerInitial());
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
