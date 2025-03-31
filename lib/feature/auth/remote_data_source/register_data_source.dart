import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/remote_data_source/models/models.dart';
import 'package:google_sign_in/google_sign_in.dart';


class RegisterDataSource {
  final client = getIt<BaseApiClients>();
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  Future<User> registerUser(Map<String, dynamic> userData) async {
    try {
      log('userData: $userData');
      final response = await client.post(Endpoints.register, body: userData);
      log('response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return User.fromRegistrationResponse(decoded);
      } else {
        log('Error body: ${response.body}');
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['msg'] as String? ??
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

  Future<User> verifyPhoneNumber(String phone, String otp) async {
    try {
      final response = await client.post(Endpoints.verify,
          body: {'phone': phone, 'verificationCode': otp});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return User.fromVerificationResponse(decoded);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      throw Exception('Failed to verify phone number: $e');
    }
  }

  Future<firebase_auth.UserCredential> registerOrLoginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final val = await _firebaseAuth.signInWithCredential(credential);

        return val;
      } else {
        throw Exception('Google sign-in failed');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('Account exists with different credential');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid credential');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on Exception catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<LoginResponse> loginUser(String phoneNumber) async {
    try {
      final response = await client.post(
        Endpoints.login, body: {'phone': phoneNumber},);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(decoded);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    }
  }

  Future<User> verifyLogin(String phone, String otp) async {
    try {
      final response = await client.post(Endpoints.loginVerify,
          body: {'phone': phone, 'verificationCode': otp});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return User.fromVerificationResponse(decoded);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          log('Error body: ${response.body}');
          final errorMessage = errorResponse['msg'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      throw Exception('Failed to verify phone number: $e');
    }
  }
}
