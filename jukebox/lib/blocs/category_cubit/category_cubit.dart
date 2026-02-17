import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jukebox/models/category_model.dart';
import 'package:jukebox/repositories/category_repository.dart';
import 'package:jukebox/repositories/song_repository.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryInitial());

  final _categoryRepository = CategoryRepository();
  final _songRepository = SongRepository();
  final Map<String, dynamic> songListData = {};

  Future<void> getCategories({
    bool loading = true,
  }) async {
    try {
      if (loading) {
        emit(CategoryGetLoading());
      }
      final List<CategoryModel> categories = [];
      final rotation = [151.0, -160.0, 151.0, 152.0];
      final data = await _categoryRepository.getCategories();

      int i = 0;
      for (final categoriesData in data) {
        categories.add(CategoryModel.fromMap({
          ...categoriesData,
          'rotation': rotation[i],
        }));
        if (i < rotation.length - 1) {
          i++;
        } else {
          i = 0;
        }
      }

      for (final category in categories) {
        final List songData = await _songRepository.getSongsByGenre(
          category.id,
        );
        songListData[category.id] = songData;
      }

      emit(CategoryGetSuccess(categories: categories));
    } catch (e) {
      emit(CategoryGetError());
    }
  }
}
