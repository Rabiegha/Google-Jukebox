import 'package:dio/dio.dart';

class CategoryRepository {
  CategoryRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://jukebox-1048249386206.europe-west1.run.app/api/',
            // baseUrl: 'https://integral-barely-ladybug.ngrok-free.app/api/',
          ),
        );

  final Dio _dio;

  Future getCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('music/genre/all');
      return response.data!['items'];
    } catch (e) {
      throw Exception(e);
    }
  }
}
