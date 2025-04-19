import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/remote_data_source/models/add_phone_to_social_model.dart';
import 'package:freedom/feature/auth/remote_data_source/models/models.dart';
import 'package:freedom/feature/auth/remote_data_source/models/social_response_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class RegisterDataSource {
  final client = getIt<BaseApiClients>();
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  Future<User> registerUser(Map<String, dynamic> userData) async {
    try {
      log('userData: $userData');
      final response = await client.post(Endpoints.register, body: userData);
      log('response status: ${response.statusCode}');
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('Decoded map: $decoded');

      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }

      return User.fromRegistrationResponse(decoded);
    } on SocketException catch (e) {
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
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      return User.fromVerificationResponse(decoded);
    } on SocketException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Main function for Google authentication
  Future<SocialResponseModel> registerOrLoginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final val = await _firebaseAuth.signInWithCredential(credential);

        if (val.user == null) {
          throw Exception('Google sign-in failed');
        }

        // Split the display name into first name and surname
        var firstName = '';
        var surname = '';

        if (val.user!.displayName != null && val.user!.displayName!.trim().isNotEmpty) {
          final nameParts = val.user!.displayName!.trim().split(' ');

          if (nameParts.length > 1) {

            firstName = nameParts.first;
            surname = nameParts.last;
            if (nameParts.length > 2) {
            }
          } else if (nameParts.length == 1) {
            firstName = nameParts.first;
            surname = '';
          }
        }

        try {
          final jsonVal = json.encode({
            'provider': 'google',
            'providerUserId': val.user!.uid.trim(),
            'email': val.user!.email?.trim(),
            'firstName': firstName,
            'surname': surname,
            'otherName': '', // You could use middle names here if needed
            'photo': val.user!.photoURL?.trim(),
          });
          log('jsonVal: $jsonVal');
          final response = await http.post(
            Uri.parse(ApiConstants.baseUrl + Endpoints.addGoogleUser),
            headers: {'Content-Type': 'application/json'},
            body: jsonVal,
          );

          log('Status: ${response.statusCode}');
          log('Body: ${response.body}');
          if (response.statusCode == 200 || response.statusCode == 201) {
            final decoded = json.decode(response.body) as Map<String, dynamic>;
            await AppPreferences.setToken(decoded['data']['token'].toString());

            final socialResponse = SocialResponseModel.fromJson(decoded);
            return socialResponse;
          } else {
            final decoded = json.decode(response.body) as Map<String, dynamic>;
            log('decoded: $decoded');
            throw ServerException(decoded['message'].toString());
          }
        } on SocketException catch (e) {
          throw NetworkException(e.message);
        } on ServerException catch (e) {
          throw ServerException(e.message);
        } catch (e) {
          rethrow;
        }
      } else {
        throw Exception('Google sign-in cancelled by user');
      }
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  Future<AddPhoneToSocialModel> addPhoneToSocial(String phoneNumber) async {
    final token = await AppPreferences.getToken();
    try {
      final response = await client.post(
        Endpoints.addPhoneToGoogle,
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token'
        },
        body: {'phone': phoneNumber},
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('addPhoneToSocial(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      return AddPhoneToSocialModel.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<bool> checkSocialAuthPhoneStatus() async {
    try {
      final token = await AppPreferences.getToken();
      log('token: $token');
      final response = await client.get(Endpoints.checkPhoneStatus);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        final decoded = json.decode(body) as Map<String, dynamic>;
        return decoded['success'] as bool;
      }
      return false;
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<LoginResponse> loginUser(String phoneNumber) async {
    try {
      final response = await client.post(
        Endpoints.login,
        body: {'phone': phoneNumber},
      );

      final decoded = json.decode(response.body) as Map<String, dynamic>;

      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      return LoginResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<User> verifyLogin(String phone, String otp) async {
    try {
      final response = await client.post(Endpoints.loginVerify,
          body: {'phone': phone, 'verificationCode': otp});
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('verifyLogin(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      return User.fromVerificationResponse(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<bool> resendOtp(String phoneNumber, String purpose) async {
    try {
      final jsonBody = {'phone': phoneNumber, 'purpose': purpose};
      final response = await client.post(Endpoints.resendOtp,
          headers: {'Content-Type': 'application/json'}, body: jsonBody);
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('resendOTP(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }

      return true;
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResult> verifyOtp(String verificationId, String otp) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      return AuthResult(
        success: true,
        userId: userCredential.user?.uid,
        message: 'Phone authentication successful',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to verify OTP: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResult> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return AuthResult(
          success: true,
          userId: user.uid,
          message: 'User is logged in',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'No user is logged in',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error getting current user: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
