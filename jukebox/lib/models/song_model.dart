import 'dart:convert';

class SongModel {
  final String id;
  final String title;
  final Duration duration;
  final String cover;
  final String audio;
  final String genre;
  final String creator;

  SongModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.cover,
    required this.audio,
    required this.genre,
    required this.creator,
  });

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      title: map['title'] as String,
      duration: Duration(seconds: map['duration'] as int),
      cover: map['cover'] as String,
      audio: map['audio'] as String,
      genre: map['genre'] as String,
      creator: map['creator'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'duration': duration.inSeconds,
      'cover': cover,
      'audio': audio,
      'genre': genre,
      'creator': creator,
    };
  }

  factory SongModel.fromJson(String source) =>
      SongModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
