import 'dart:convert';
import 'dart:developer';

import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';


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
}
