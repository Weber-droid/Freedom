import 'dart:convert';
import 'dart:developer';

import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/registration/remote_data_source/remote_data_source_models.dart';

class RegisterDataSource {
  final client = getIt<BaseApiClients>();

  Future<User> registerUser(Map<String, dynamic> userData) async {
    try {
      log('userData: $userData');
      final response =
          await client.post(Endpoints.register, body: userData);
      log('userData: $userData');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return User(
          success: decoded['success'] as bool,
          message: decoded['message'] as String,
          userId: decoded['userId'] as String,
        );
      } else {
        log('Error body: ${response.body}');
        throw BadRequestException(response.body);
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    }
  }
}

// 67d47824c034ec9462cae39f

