part of 'player_cubit.dart';

@immutable
sealed class PlayerState {}

class AudioPlayerInitial extends PlayerState {}

class AudioPlayerLoading extends PlayerState {}

class AudioPlayerEnd extends PlayerState {}

class AudioPlayerPlaying extends PlayerState {}

class AudioPlayerPaused extends PlayerState {}

class AudioPlayerEndOfPlaylist extends PlayerState {}

class AudioPlayerStop extends PlayerState {}

class AudioPlayerStartOfPlaylist extends PlayerState {}

class AudioPlayerError extends PlayerState {
  final String message;
  AudioPlayerError(this.message);
}
