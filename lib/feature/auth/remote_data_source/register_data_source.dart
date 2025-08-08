import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/core/config/api_constants.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/remote_data_source/helpers.dart';
import 'package:freedom/feature/auth/remote_data_source/models/add_phone_to_social_model.dart';
import 'package:freedom/feature/auth/remote_data_source/models/models.dart';
import 'package:freedom/feature/auth/remote_data_source/models/social_response_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      final response = await client.post(
        Endpoints.verify,
        body: {'phone': phone, 'verificationCode': otp},
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      await RegisterLocalDataSource().saveUser(
        User.fromVerificationResponse(decoded),
      );
      return User.fromVerificationResponse(decoded);
    } on SocketException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<SocialResponseModel> registerOrLoginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final val = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = val.user;
      if (firebaseUser == null) {
        throw Exception('Google sign-in failed');
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      final nameParts = splitName(firebaseUser.displayName);
      final body = {
        'provider': 'google',
        'providerUserId': firebaseUser.uid.trim(),
        'email': firebaseUser.email?.trim(),
        'firstName': nameParts['firstName'],
        'surname': nameParts['surname'],
        'otherName': nameParts['otherName'],
        'photo': firebaseUser.photoURL?.trim(),
        'fcmToken': fcmToken,
      };

      final response = await postUserToBackend(body, client);
      final decoded = decodeResponse(response);

      await AppPreferences.setToken(decoded['data']['token'].toString());

      final socialResponse = SocialResponseModel.fromJson(decoded);
      await RegisterLocalDataSource().saveUser(
        User.fromRegistrationResponse(decoded),
      );

      return socialResponse;
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  Future<SocialResponseModel> registerOrLoginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = fb.OAuthProvider('apple.com');
      final authCredential = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final val = await _firebaseAuth.signInWithCredential(authCredential);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (val.user == null) {
        throw Exception('Apple sign-in failed');
      }

      final nameResult = _extractUserNames(
        credential: credential,
        firebaseUser: val.user!,
        isNewUser: val.additionalUserInfo!.isNewUser,
      );

      if (val.additionalUserInfo!.isNewUser &&
          nameResult.shouldUpdateDisplayName) {
        await _updateFirebaseDisplayName(val.user!, nameResult);
      }

      final jsonVal = json.encode({
        'provider': 'apple',
        'providerUserId': val.user!.uid.trim(),
        'email': val.user!.email?.trim(),
        'firstName': nameResult.firstName,
        'surname':
            nameResult.surname.isEmpty
                ? nameResult.firstName
                : nameResult.surname,
        'otherName': '',
        'photo': val.user!.photoURL?.trim(),
        'fcmToken': fcmToken,
      });

      log('jsonVal: $jsonVal');

      return await _sendUserDataToServer(jsonVal);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Apple sign-in cancelled by user');
      } else {
        throw Exception('Apple sign-in authorization error: ${e.message}');
      }
    } on fb.FirebaseAuthException catch (e) {
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      throw ServerException('Firebase Auth Error: ${e.message}');
    } catch (e) {
      log('Unexpected error in Apple sign-in: $e');
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  UserNameResult _extractUserNames({
    required AuthorizationCredentialAppleID credential,
    required fb.User firebaseUser,
    required bool isNewUser,
  }) {
    String firstName = '';
    String surname = '';
    bool shouldUpdateDisplayName = false;

    if (credential.givenName != null &&
        credential.givenName!.trim().isNotEmpty) {
      firstName = credential.givenName!.trim();
      shouldUpdateDisplayName = true;
    }

    if (credential.familyName != null &&
        credential.familyName!.trim().isNotEmpty) {
      surname = credential.familyName!.trim();
      shouldUpdateDisplayName = true;
    }

    if (firstName.isEmpty &&
        firebaseUser.displayName != null &&
        firebaseUser.displayName!.trim().isNotEmpty) {
      final nameParts = firebaseUser.displayName!.trim().split(' ');

      if (nameParts.length > 1) {
        firstName = nameParts.first;
        surname = nameParts.sublist(1).join(' ');
      } else if (nameParts.length == 1) {
        firstName = nameParts.first;
      }

      log('Extracted names from Firebase displayName: $firstName $surname');
    }

    if (firstName.isEmpty && firebaseUser.email != null) {
      final emailPrefix = _extractEmailPrefix(firebaseUser.email!);
      firstName = emailPrefix;
      log('Using email prefix as firstName: $firstName');

      if (isNewUser && !shouldUpdateDisplayName) {
        shouldUpdateDisplayName = true;
      }
    }

    log('Final extracted names - firstName: "$firstName", surname: "$surname"');

    return UserNameResult(
      firstName: firstName,
      surname: surname.isEmpty ? firstName : surname,
      shouldUpdateDisplayName: shouldUpdateDisplayName,
    );
  }

  String _extractEmailPrefix(String email) {
    final prefix = email.split('@').first;

    String cleanPrefix =
        prefix
            .replaceAll(RegExp(r'[._-]'), ' ')
            .replaceAll(RegExp(r'\d+'), '')
            .trim();

    if (cleanPrefix.isNotEmpty) {
      cleanPrefix = cleanPrefix
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map(
            (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
          )
          .join(' ');
    }

    if (cleanPrefix.isEmpty) {
      cleanPrefix = prefix;
    }

    log('Email prefix transformation: "$prefix" -> "$cleanPrefix"');
    return cleanPrefix;
  }

  Future<void> _updateFirebaseDisplayName(
    fb.User user,
    UserNameResult nameResult,
  ) async {
    try {
      String displayName = nameResult.firstName;
      if (nameResult.surname.isNotEmpty) {
        displayName += ' ${nameResult.surname}';
      }

      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
        log('Updated Firebase display name to: "$displayName"');
      }
    } catch (e) {
      log('Failed to update Firebase display name: $e');
    }
  }

  Future<SocialResponseModel> _sendUserDataToServer(Object jsonVal) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + Endpoints.addGoogleUser),
        headers: {'Content-Type': 'application/json'},
        body: jsonVal,
      );
      log('API Response - Status: ${response.statusCode}');
      log('API Response - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        await AppPreferences.setToken(decoded['data']['token'].toString());

        final socialResponse = SocialResponseModel.fromJson(decoded);
        await RegisterLocalDataSource().saveUser(
          User.fromRegistrationResponse(decoded),
        );
        return socialResponse;
      } else {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        log('API Error Response: $decoded');
        throw ServerException(
          decoded['message']?.toString() ?? 'Server error occurred',
        );
      }
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      log('Unexpected error in API call: $e');
      throw ServerException('Failed to communicate with server: $e');
    }
  }

  Future<AddPhoneToSocialModel> addPhoneToSocial(String phoneNumber) async {
    final token = await AppPreferences.getToken();
    try {
      final response = await client.post(
        Endpoints.addPhoneToGoogle,
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
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

  Future<User> verifyLogin(
    String phone,
    String otp,
    String fcmToken,
    String platform,
  ) async {
    try {
      final response = await client.post(
        Endpoints.loginVerify,
        body: {
          'phone': phone,
          'verificationCode': otp,
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      await RegisterLocalDataSource().saveUser(
        User.fromVerificationResponse(decoded),
      );
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
      final response = await client.post(
        Endpoints.resendOtp,
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );
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

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

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
        return AuthResult(success: false, message: 'No user is logged in');
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

class UserNameResult {
  final String firstName;
  final String surname;
  final bool shouldUpdateDisplayName;

  UserNameResult({
    required this.firstName,
    required this.surname,
    required this.shouldUpdateDisplayName,
  });
}
