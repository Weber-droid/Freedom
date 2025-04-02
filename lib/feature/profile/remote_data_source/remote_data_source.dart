import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileRemoteDataSource {
  final client = getIt<BaseApiClients>();

  Future<ProfileModel> fetchUserProfile() async {
    try {
      final user = await RegisterLocalDataSource().getUser();
      if (user == null) {
        throw Exception('No user found in local storage');
      }
      final response = await client.get(Endpoints.profile,
          headers: {'Authorization': 'Bearer ${user.token}'});

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        log('remote data source(): $decoded');
        return ProfileModel.fromJson(decoded);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          log('Error message: $errorMessage');
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      log('Network exception: ${e.message}');
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      log('Server exception: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      log('Unexpected error: $e');
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  Future<void> uploadImage(File file) async {
    if (file.path.isEmpty) {
      throw Exception('File path is empty');
    }
    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}upload-profile-picture');
      log('url: $url');
      final imageFormat = _getImageFormat(file.path);
      final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${getIt<User>().token}'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', imageFormat),
        ));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(responseString);
        log('Image uploaded successfully: $jsonData');
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(responseString) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException('Server error');
        }
      }
    } on NetworkException catch (e) {
      log('Network exception: ${e.message}');
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      log('Server exception: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      log('Unexpected error: $e');
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  String _getImageFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // Default to jpeg if unknown
    }
  }
}
