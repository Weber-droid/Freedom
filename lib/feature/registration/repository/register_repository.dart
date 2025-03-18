import 'dart:developer';

import 'package:dartz/dartz.dart';
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
}
