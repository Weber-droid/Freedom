import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/History/model/history_model.dart';
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/feature/home/data_sources/ride_data_source.dart';
import 'package:freedom/feature/home/models/cancel_ride_response.dart';
import 'package:freedom/feature/home/models/multiple_stop_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_response.dart';
import 'package:freedom/feature/home/models/ride_status_response.dart';

abstract class RideRequestRepository {
  Future<Either<Failure, RequestRideResponse>> requestRide(
    RideRequestModel requestRideModel,
  );
  Future<Either<Failure, MultipleStopsResponse>> requestMultipleStopRide(
    MultipleStopRideModel requestRideModel,
  );
  Future<Either<Failure, RideCancellationResponse>> cancelRide(
    String rideId,
    String reason,
  );
  Future<void> acceptRide(String rideId);
  Future<void> completeRide(String rideId);
  Future<void> updateRideStatus(String rideId, String status);
  Future<Either<Failure, RideHistoryResponse>> getRideHistory(
    String status,
    int page,
    int limit,
  );
  Future<void> trackRide(String rideId);
  Future<void> rateDriver(String rideId, int rating);
  Future<Either<Failure, RideStatusResponse>> checkRideStatus(String rideId);
}

class RideRequestRepositoryImpl implements RideRequestRepository {
  RideRequestRepositoryImpl({required this.remoteDataSource});

  final RideRemoteDataSource remoteDataSource;

  @override
  Future<void> acceptRide(String rideId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RideCancellationResponse>> cancelRide(
    String rideId,
    String reason,
  ) async {
    try {
      final response = await remoteDataSource.cancelRide(rideId, reason);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, RideStatusResponse>> checkRideStatus(
    String rideId,
  ) async {
    try {
      final response = await remoteDataSource.checkRideStatus(rideId);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<void> completeRide(String rideId) {
    // TODO: implement completeRide
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RideHistoryResponse>> getRideHistory(
    String status,
    int page,
    int limit,
  ) async {
    try {
      final history = await remoteDataSource.getRideHistory(
        status,
        page,
        limit,
      );
      log('Request is successful, history: ${history.success}');
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<void> rateDriver(String rideId, int rating) {
    // TODO: implement rateDriver
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, RequestRideResponse>> requestRide(
    RideRequestModel requestRideModel,
  ) async {
    try {
      final model = await remoteDataSource.requestRide(requestRideModel);
      log('from Repository(model): ${model.data}');
      await AppPreferences.setRideId(model.data.rideId ?? '');
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<void> trackRide(String rideId) {
    // TODO: implement trackRide
    throw UnimplementedError();
  }

  @override
  Future<void> updateRideStatus(String rideId, String status) {
    // TODO: implement updateRideStatus
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, MultipleStopsResponse>> requestMultipleStopRide(
    MultipleStopRideModel requestRideModel,
  ) async {
    try {
      log(
        'Requesting multiple stop ride with model: ${json.encode(requestRideModel.toJson())}',
      );

      final model = await remoteDataSource.requestMultipleStopRide(
        requestRideModel,
      );
      log('from Repository(multiple stop model): ${model.toJson()}');

      return Right(model);
    } on ServerException catch (e) {
      log('Server exception in requestMultipleStopRide: ${e.message}');
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      log('Network exception in requestMultipleStopRide: ${e.message}');
      return Left(NetworkFailure(e.message));
    } catch (e) {
      log('Unexpected error in requestMultipleStopRide: $e');
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }
}
