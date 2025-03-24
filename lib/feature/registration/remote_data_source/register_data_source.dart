import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/registration/remote_data_source/remote_data_source_models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterDataSource {
  final client = getIt<BaseApiClients>();
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  Future<User> registerUser(Map<String, dynamic> userData) async {
    try {
      log('userData: $userData');
      final response = await client.post(Endpoints.register, body: userData);
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

  Future<firebase_auth.UserCredential> registerOrLoginWithGoogle() async {
   try{
     final googleSignIn = GoogleSignIn();
     final googleUser = await googleSignIn.signIn();
     if (googleUser != null) {
       final googleAuth = await googleUser.authentication;
       final credential = firebase_auth.GoogleAuthProvider.credential(
         accessToken: googleAuth.accessToken,
         idToken: googleAuth.idToken,
       );
       final val =   await _firebaseAuth.signInWithCredential(credential);

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
}
