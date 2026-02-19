// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/blocs/category_cubit/category_cubit.dart';
import 'package:jukebox/blocs/player_cubit/player_cubit.dart';
import 'package:jukebox/models/song_model.dart';
import 'package:jukebox/repositories/song_repository.dart';
import 'package:jukebox/views/create_son/widgets/creating_music_overlay_entry.dart';
import 'package:jukebox/views/create_son/widgets/error_music_overlay_entry.dart';
import 'package:jukebox/views/create_son/widgets/listen_music_overlay_entry.dart';
import 'package:just_audio/just_audio.dart';

part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  SongCubit() : super(SongInitial());

  final SongRepository _songRepository = SongRepository();

  getSongsByGenre(
    String genre,
    CategoryCubit categoryCubit,
    BuildContext context, {
    bool activeSong = true,
  }) async {
    emit(SongGetByGenreLoading());
    try {
      // Stop any currently playing audio when switching categories
      final playerCubit = context.read<PlayerCubit>();
      await playerCubit.stop();

      final List<SongModel> songs = [];
      final List<String> playList = [];
      final data = categoryCubit.songListData[genre];

      if (data != null) {
        for (final songData in data) {
          final song = SongModel.fromMap(songData);
          // Skip incomplete songs (failed generation)
          if (song.audio == 'default_audio' || song.audio.isEmpty) continue;
          songs.add(song);
          playList.add(song.audio);
        }
      }

      if (songs.isEmpty) {
        playerCubit.playlist = [];
        playerCubit.songList = [];
        playerCubit.actifSong.value = null;
        emit(SongGetByGenreSuccess(songs: songs, genre: genre));
        return;
      }

      final audioSource = ConcatenatingAudioSource(
        children:
            playList.map((item) => AudioSource.uri(Uri.parse(item))).toList(),
      );

      context.read<PlayerCubit>().audioPlayer.setAudioSource(audioSource);
      playerCubit.playlist = playList;
      playerCubit.songList = songs;

      if (activeSong) {
        playerCubit.actifSong.value = songs[0];
      }

      emit(SongGetByGenreSuccess(songs: songs, genre: genre));
    } catch (e) {
      inspect(e);
      emit(SongGetByGenreSuccess(songs: [], genre: genre));
    }
  }

  getSettings(String song) async {
    emit(GetSettingsloading());
    final settings = await _songRepository.getSettings(song);
    inspect(settings);
    emit(GetSettingsSuccess(settings: settings));
  }

  sendMail(String songId, String mail, String genre) async {
    try {
      emit(SendMailLoading());
      await _songRepository.sendSongByMail(songId, mail, genre);
      emit(SendMailSuccess());
    } catch (_) {
      emit(SendMailError());
    }
  }

  createSongInIsolate(
    String title,
    String description,
    String pseudo,
    String genre,
    List<String> instruments,
    Map<String, dynamic> settings,
    BuildContext context,
    BuildContext homeContext,
  ) async {
    try {
      final receivePort = ReceivePort();

      await Isolate.spawn(
        createSong,
        {
          'sendPort': receivePort.sendPort,
          'title': title,
          'genre': genre,
          'instruments': instruments,
          'settings': settings,
          'description': description,
          'pseudo': pseudo,
        },
      );

      Navigator.of(context).pop();

      var overlayEntry = creatingSongPopup();
      Overlay.of(homeContext).insert(overlayEntry);

      final res = await receivePort.first;

      if (res['erreur'] != null) {
        overlayEntry.remove();
        overlayEntry = errorSongPopup();
        Overlay.of(homeContext).insert(overlayEntry);
        await Future.delayed(const Duration(seconds: 5));
        overlayEntry.remove();
        return;
      }

      homeContext.read<CategoryCubit>().getCategories(loading: false);

      overlayEntry.remove();
      overlayEntry = listenMusicPopup(SongModel.fromMap(res));
      Overlay.of(homeContext).insert(overlayEntry);

      await Future.delayed(const Duration(seconds: 20));
      overlayEntry.remove();
    } catch (e) {
      inspect(e);
    }
  }
}

void createSong(
  Map<String, dynamic> params,
) async {
  final instruments = params['instruments'].join(', ');
  final genre = params['genre'];
  final description = params['description'];
  final pseudo = params['pseudo'];
  final settings = params['settings'];

  String prompt = """
    Generate music with this caracteristic:
    genre: $genre,
    instruments: $instruments,
    BPM: ${settings['bpm']},
    Bitrate: ${settings['bitrate']},
    Sample range: ${settings['sample_range']}.
  """;

  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://jukebox-395380200712.europe-west1.run.app/api/',
      ),
    );

    final response = await dio.post(
      'music/uuid',
      data: jsonEncode({
        "genre": genre,
        "prompt": prompt,
        "title": params['title'],
        "creator": pseudo,
        "duration": 30
      }),
    );

    // Try cover generation, but continue even if it fails
    String cover = 'default_cover';
    try {
      final coverResponse = await dio.post(
        'music/cover',
        data: jsonEncode({
          'uuid': response.data['id'],
          'title': params['title'],
          'prompt': prompt,
          'duration': 30,
          "creator": pseudo,
          'genre': params['genre'],
        }),
      );
      cover = coverResponse.data['cover'] ?? 'default_cover';
    } catch (coverError) {
      // Cover generation failed (quota, etc.) - continue with default cover
      inspect(coverError);
    }

    final songResponse = await dio.get(
      'music/song',
      queryParameters: {
        'uuid': response.data['id'],
        'title': params['title'],
        'prompt': prompt,
        'duration': 30,
        'genre': params['genre'],
        "creator": pseudo,
      },
    );

    params['sendPort'].send({
      'title': songResponse.data['title'],
      'genre': songResponse.data['genre'],
      'audio': songResponse.data['audio'],
      'creator': songResponse.data['creator'],
      'id': songResponse.data['id'],
      'cover': cover,
      'duration': 30,
    });
  } catch (e) {
    inspect(e);
    params['sendPort'].send({'erreur': 'Erreur : $e'});
  }
}
