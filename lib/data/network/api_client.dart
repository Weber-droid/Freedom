import 'package:dio/dio.dart';
import 'package:freedom/data/models/article_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_client.g.dart'; // Generated file

@RestApi(baseUrl: "https://api.example.com/")
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @GET("/items")
  Future<List<ArticleModel>> getItems();

  @POST("/items")
  Future<ArticleModel> createItem(@Body() ArticleModel item);
}
