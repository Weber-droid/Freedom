import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/remote_data_source/models/models.dart';
import 'package:freedom/feature/auth/remote_data_source/models/social_response_model.dart';
import 'package:freedom/feature/auth/remote_data_source/register_data_source.dart';
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/shared/network_helpers.dart';

class RegisterRepository {
  // Factory constructor returns singleton
  factory RegisterRepository() => _instance;
  RegisterRepository._internal() {
    _remoteDataSource = RegisterDataSource();
  }

  // Singleton instance
  static final RegisterRepository _instance = RegisterRepository._internal();

  late final RegisterDataSource _remoteDataSource;
  Future<Either<Failure, User>> registerUser(UserModel user) async {
    try {
      final response = await _remoteDataSource.registerUser(user.toJson());
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  Future<Either<Failure, User>> verifyPhoneNumber(
      String phone, String otp) async {
    try {
      final response = await _remoteDataSource.verifyPhoneNumber(phone, otp);
      if (response.token != null) {
        await RegisterLocalDataSource.setJwtToken(response.token!);
      }
      return Right(response);
    } on ServerFailure catch (e) {
      final failure = handleException(e);
      return Left(failure);
    }
  }

  Future<Either<Failure, SocialResponseModel?>>
      registerOrLoginWithGoogle() async {
    try {
      final response = await _remoteDataSource.registerOrLoginWithGoogle();
      return Right(response);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool?>> checkSocialAuthPhoneStatus() async {
    try {
      final response = await _remoteDataSource.checkSocialAuthPhoneStatus();
      return Right(response);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, LoginResponse>> loginUser(String number) async {
    try {
      final response = await _remoteDataSource.loginUser(number);
      return Right(response);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, User?>> verifyLogin(
      String phoneNumber, String otp) async {
    try {
      final response = await _remoteDataSource.verifyLogin(phoneNumber, otp);
      return Right(response);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> resendOtp(
      String phoneNumber, String purpose) async {
    try {
      final val = await _remoteDataSource.resendOtp(phoneNumber, purpose);
      return Right(val);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      rethrow;
    }
  }

  Future<Either<Failure, AuthResult>> verifyOtp(
      String verificationId, String otp) async {
    try {
      final val = await _remoteDataSource.verifyOtp(verificationId, otp);
      return Right(val);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      rethrow;
    }
  }

  Future<Either<Failure, AuthResult>> getCurrentUser() async {
    try {
      final val = await _remoteDataSource.getCurrentUser();
      return Right(val);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }
}
