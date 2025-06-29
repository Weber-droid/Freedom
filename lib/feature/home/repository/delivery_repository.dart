import 'package:dartz/dartz.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/feature/home/data_sources/delivery_data_source.dart';
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/models/delivery_request_response.dart';

abstract class IDeliveryRepository {
  Future<Either<Failure, DeliveryRequestResponse>> requestDelivery(
      DeliveryModel deliveryRequestModel);
  Future<void> cancelDelivery(String deliveryId, String reason);
  Future<void> updateDeliveryStatus(String deliveryId, String status);
  Future<void> trackDelivery(String deliveryId);
}

class DeliveryRepositoryImpl implements IDeliveryRepository {
  DeliveryRepositoryImpl({
    required this.remoteDataSource,
  });
  final IDeliveryRemoteDataSource remoteDataSource;
  @override
  Future<Either<Failure, void>> cancelDelivery(
      String deliveryId, String reason) async {
    try {
      final response =
          await remoteDataSource.cancelDelivery(deliveryId, reason);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeliveryRequestResponse>> requestDelivery(
      DeliveryModel deliveryRequestModel) async {
    try {
      final response =
          await remoteDataSource.requestDelivery(deliveryRequestModel);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> trackDelivery(String deliveryId) {
    // TODO: implement trackDelivery
    throw UnimplementedError();
  }

  @override
  Future<void> updateDeliveryStatus(String deliveryId, String status) {
    // TODO: implement updateDeliveryStatus
    throw UnimplementedError();
  }
}
