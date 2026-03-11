import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/models/category_model.dart';
import 'package:jukebox/repositories/song_repository.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryInitial());

  final _songRepository = SongRepository();
  final Map<String, dynamic> songListData = {};

  /// Currently selected category (shared across the app)
  final ValueNotifier<String?> selectedCategory = ValueNotifier(null);

  /// Hardcoded genres with their cover images (same approach as instruments)
  static final List<Map<String, dynamic>> _genreData = [
    {'id': 'Ambiente', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/ambiente/1725271639244/sample_0.png'},
    {'id': 'Chill Out', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/chill-out/1725270439934/sample_0.png'},
    {'id': 'Classic', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/classic/1725269390232/sample_0.png'},
    {'id': 'Corporate', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/corporate/1725271180300/sample_0.png'},
    {'id': 'Country', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/country/1725269867234/sample_0.png'},
    {'id': 'EDM', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/dance-edm/1725270098480/sample_0.png'},
    {'id': 'Folk', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/folk/1725269597317/sample_0.png'},
    {'id': 'Funk', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/funk/1725270593601/sample_0.png'},
    {'id': 'Hip Hop', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/hip-hip/1725271363924/sample_0.png'},
    {'id': 'Jazz', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/jazz/1725269657228/sample_0.png'},
    {'id': 'Rock', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/rock/1725269730725/sample_0.png'},
    {'id': 'Videogames', 'url': 'https://storage.googleapis.com/prompts_results/genreCover/videogames/1725270824304/sample_0.png'},
  ];

  /// Get the list of genre names (for the creation form)
  static List<String> get genreNames => _genreData.map((g) => g['id'] as String).toList();

  Future<void> getCategories({
    bool loading = true,
  }) async {
    try {
      if (loading) {
        emit(CategoryGetLoading());
      }

      // Build categories from hardcoded data (instant, no API call)
      final rotation = [151.0, -160.0, 151.0, 152.0];
      final List<CategoryModel> categories = [];
      int i = 0;
      for (final genreMap in _genreData) {
        categories.add(CategoryModel.fromMap({
          ...genreMap,
          'rotation': rotation[i],
        }));
        if (i < rotation.length - 1) {
          i++;
        } else {
          i = 0;
        }
      }

      // Only fetch songs from API (this is the data that changes)
      for (final category in categories) {
        try {
          final List songData = await _songRepository.getSongsByGenre(
            category.id,
          );
          songListData[category.id] = songData;
        } catch (e) {
          songListData[category.id] = [];
        }
      }

      emit(CategoryGetSuccess(categories: categories));
    } catch (e) {
      emit(CategoryGetError());
    }
  }

  /// Refresh songs for a single genre from the API (fast, 1 call)
  Future<void> refreshGenreSongs(String genre) async {
    try {
      final List songData = await _songRepository.getSongsByGenre(genre);
      songListData[genre] = songData;
    } catch (e) {
      // Keep existing cached data on error
    }
  }
}
