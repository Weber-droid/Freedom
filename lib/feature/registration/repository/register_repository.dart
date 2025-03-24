import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:freedom/feature/registration/remote_data_source/register_data_source.dart';
import 'package:freedom/feature/registration/remote_data_source/remote_data_source_models.dart';

import 'package:freedom/feature/registration/repository/repository_exceptions.dart';

class RegisterRepository {
  factory RegisterRepository() {
    _registerRepository._remoteDataSource = RegisterDataSource();
    return _registerRepository;
  }
  RegisterRepository._internal();

  static final RegisterRepository _registerRepository =
      RegisterRepository._internal();

  late final RegisterDataSource _remoteDataSource;
  Future<Either<Failure, User>> registerUser(UserModel user) async {
    try {
      log('user: ${user.toJson()}');
      final response = await _remoteDataSource.registerUser(user.toJson());
      return Right(response);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  Future<Either<Failure, fa.User?>> registerOrLoginWithGoogle() async {
    try {
      final response = await _remoteDataSource.registerOrLoginWithGoogle();
      return Right(response.user);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
