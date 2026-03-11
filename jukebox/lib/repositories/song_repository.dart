import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:jukebox/config/app_config.dart';

class SongRepository {
  SongRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
          ),
        );

  final Dio _dio;

  getSongsByGenre(String genre) async {
    try {
      final response = await _dio.get('music/musics/$genre');
      return response.data!['items'];
    } catch (e) {
      throw Exception(e);
    }
  }

  getSettings(String song) async {
    try {
      final response = await _dio.get(
        'default_settings',
        queryParameters: {
          'songName': song,
        },
      );
      return response.data;
    } catch (e) {}
  }

  sendSongByMail(
    String id,
    String recipient,
    String genre,
  ) async {
    try {
      log('[SongRepository.sendSongByMail] POST mail | id: $id | recipient: $recipient | genre: $genre');
      final response = await _dio.post(
        'mail',
        data: jsonEncode(
          {
            "recipients": [recipient],
            "music_id": id,
            "music_genre": genre,
          },
        ),
      );
      log('[SongRepository.sendSongByMail] Response status: ${response.statusCode}');
    } on DioException catch (e) {
      log('[SongRepository.sendSongByMail] DioException: ${e.message} | status: ${e.response?.statusCode} | data: ${e.response?.data}');
      throw Exception('sendSongByMail failed: ${e.message}');
    } catch (e) {
      log('[SongRepository.sendSongByMail] Unexpected error: $e');
      throw Exception('sendSongByMail unexpected error: $e');
    }
  }

  createSong(
    String prompt,
    String genre,
    String title,
  ) async {
    try {
      final response = await _dio.post('music/uuid',
          data: jsonEncode({
            "genre": genre,
            "prompt": prompt,
            "title": title,
            "duration": 30
          }).toString());

      inspect(response);

      await _dio.post(
        'music/cover',
        data: jsonEncode({
          'uuid': response.data['id'],
          'title': title,
          'prompt': prompt,
          'duration': 30,
          'genre': genre,
        }),
      );

      final songResponse = await _dio.get(
        'music/song',
        queryParameters: {
          'uuid': response.data['id'],
          'title': title,
          'prompt': prompt,
          'duration': 30,
          'genre': genre,
        },
      );

      inspect(songResponse);
      return songResponse;
    } catch (e) {
      print(e);
    }
  }
}
