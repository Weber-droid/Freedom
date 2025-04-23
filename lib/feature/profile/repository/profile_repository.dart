import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';
import 'package:freedom/feature/profile/model/update_use_details.dart';
import 'package:freedom/feature/profile/model/verify_phone_update_model.dart';
import 'package:freedom/feature/profile/remote_data_source/remote_data_source.dart';

class ProfileRepository {
  factory ProfileRepository() => _instance;
  ProfileRepository._internal() {
    _remoteDataSource = ProfileRemoteDataSource();
  }

  static final ProfileRepository _instance = ProfileRepository._internal();

  late final ProfileRemoteDataSource _remoteDataSource;

  Future<Either<Failure, ProfileModel>> fetchUserProfile() async {
    try {
      final response = await _remoteDataSource.fetchUserProfile();
      log('response: ${response.toJson()}');
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }
  Future<Either<Failure, void>> updateProfile(File profile) async {
    try {
      final response = await _remoteDataSource.uploadImage(profile);
      return const Right(0);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }
  Future<Either<Failure, UpdateUserDetailsData>> requestNumberUpdate(String number) async {
    try {
      final response = await _remoteDataSource.updatePhoneNumber(number);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  Future<Either<Failure, UpdateUserDetails>> requestEmailUpdate(String email) async {
    try {
      final response = await _remoteDataSource.upDateEmail(email);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

Future<Either<Failure, VerifyPhoneUpdateModel>> verifyPhoneUpDate (String otp) async {
    try {
      final response = await _remoteDataSource.verifyUpdatePhone(otp);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }
}
