import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';
import 'package:freedom/feature/profile/model/update_use_details.dart';
import 'package:freedom/feature/profile/model/verify_phone_update_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileRemoteDataSource {
  final client = getIt<BaseApiClients>();

  Future<ProfileModel> fetchUserProfile() async {
    try {
      final token = await AppPreferences.getToken();
      if (token == null) {
        throw Exception('No user found in local storage');
      }
      final response = await client
          .get(Endpoints.profile, headers: {'Authorization': 'Bearer $token'});

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
    final token = await AppPreferences.getToken();
    log('$token');
    if (file.path.isEmpty) {
      throw Exception('File path is empty');
    }

    try {
      // Check if file exists and has content
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }
      log('File size: $fileSize bytes');

      final url = Uri.parse('${ApiConstants.baseUrl}upload-profile-picture');
      final imageFormat = _getImageFormat(file.path);
      log('Image format: $imageFormat');

      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      // Sometimes servers also require Content-Type header
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage', // This must match exactly what the server expects
        file.path,
        contentType: MediaType('image', imageFormat),
      ));

      log('Request prepared with file: ${request.files[0].filename}');

      // Send request
      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      log('Response status: ${streamedResponse.statusCode}');
      log('Response body: $responseString');

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final jsonData = jsonDecode(responseString);
        log('Upload successful: $jsonData');
        return; // Successfully uploaded
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(responseString) as Map<String, dynamic>;
          final errorMessage =
              errorResponse['msg'] as String? ?? 'Unknown server error';
          throw ServerException(errorMessage);
        } catch (e) {
          log('Error parsing response: $e');
          throw ServerException(
              'Error uploading image: ${streamedResponse.statusCode}');
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

  Future<UpdateUserDetailsData> updatePhoneNumber(String number) async{
    try {
    final token = await AppPreferences.getToken();
      final response = await client.post(Endpoints.requestPhoneNumberUpdate,
          headers: {
            'Content-Type': 'application/json',
            'authorization': 'Bearer $token'
          },
          body: {'newPhone': number});
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('updatePhoneNumber(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      final val = UpdateUserDetailsData.fromJson(decoded);
      return val;
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  Future<VerifyPhoneUpdateModel> verifyUpdatePhone(String otp) async{
    try {
      final token = await AppPreferences.getToken();
      final response = await client.post(Endpoints.verifyPhoneUpdate,
          headers: {
            'Content-Type': 'application/json',
            'authorization': 'Bearer $token'
          },
          body: {'verificationCode': otp});
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('updatePhoneNumber(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      final val = VerifyPhoneUpdateModel.fromJson(decoded);
      return val;
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UpdateUserDetails> upDateEmail(String email) async{
    try {
      final token = await AppPreferences.getToken();
      final response = await client.post(Endpoints.requestEmailUpdate,
          headers: {
            'Content-Type': 'application/json',
            'authorization': 'Bearer $token'
          },
          body: {'newEmail': email});
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('updateEmail(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      final val = UpdateUserDetails.fromJson(decoded);
      return val;
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<VerifyPhoneUpdateModel> verifyUpdateEmail(String otp) async{
    try {
      final token = await AppPreferences.getToken();
      final response = await client.post(Endpoints.verifyPhoneUpdate,
          headers: {
            'Content-Type': 'application/json',
            'authorization': 'Bearer $token'
          },
          body: {'verificationCode': otp});
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('updatePhoneNumber(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      final val = VerifyPhoneUpdateModel.fromJson(decoded);
      return val;
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
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
