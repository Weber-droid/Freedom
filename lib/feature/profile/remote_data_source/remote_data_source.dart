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
  final token = RegisterLocalDataSource.getJwtToken();
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
          final errorMessage = errorResponse['message'] as String;
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(response.body);
        }
      }
    } on NetworkException catch (e) {

      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  Future<void> uploadImage(File file) async {
    if (file.path.isEmpty) {
      throw Exception('File path is empty');
    }
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}upload-profile-picture');
      final imageFormat = _getImageFormat(file.path);
      log('Image format $imageFormat');
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] =
            'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'profileImage',
          file.path,
          contentType: MediaType('profileImage', imageFormat),
        ));

      log('my request ${request.files[0].filename}');
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(responseString);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(responseString) as Map<String, dynamic>;
          final errorMessage = errorResponse['msg'] as String;
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException('Error uploading image');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
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
        return 'jpeg';
    }
  }
}
