import 'package:dio/dio.dart';
import 'package:jukebox/config/app_config.dart';

class CategoryRepository {
  CategoryRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
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
