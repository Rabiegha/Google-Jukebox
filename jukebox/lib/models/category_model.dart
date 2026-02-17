import 'dart:convert';

class CategoryModel {
  final String id;
  final String url;
  final double rotation;

  CategoryModel({
    required this.id,
    required this.url,
    required this.rotation,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'rotation': rotation,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      url: map['url'] as String,
      rotation: map['rotation'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoryModel.fromJson(String source) =>
      CategoryModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
