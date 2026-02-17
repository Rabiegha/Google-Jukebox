part of 'song_cubit.dart';

@immutable
sealed class SongState {}

final class SongInitial extends SongState {}

final class SongGetByGenreLoading extends SongState {}

final class SongGetByGenreSuccess extends SongState {
  final List<SongModel> songs;
  final String genre;

  SongGetByGenreSuccess({required this.songs, required this.genre});
}

final class GetSettingsloading extends SongState {}

final class GetSettingsSuccess extends SongState {
  final Map<String, dynamic> settings;

  GetSettingsSuccess({required this.settings});
}

final class SendMailLoading extends SongState {}

final class SendMailSuccess extends SongState {}

final class SendMailError extends SongState {}
