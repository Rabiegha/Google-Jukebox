import 'package:jukebox/models/song_model.dart';

class CategorySongModel {
  final String category;
  final List<SongModel> songs;

  CategorySongModel({
    required this.category,
    required this.songs,
  });
}
