import 'package:freezed_annotation/freezed_annotation.dart';

part 'article_model.freezed.dart';
part 'article_model.g.dart'; // JSON serialization part

@freezed
class ArticleModel with _$ArticleModel {
  const factory ArticleModel({
    required String title,
    required String description,
    required String url,
    required String urlToImage,
    required DateTime publishedAt,
    required String content,
    required String author,
  }) = _ArticleModel;

  // JSON deserialization
  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);
}
