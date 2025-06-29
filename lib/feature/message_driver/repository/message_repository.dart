import 'package:dartz/dartz.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/feature/message_driver/remote_data_source/message_remote_data_source.dart';

class MessageRepository {
  const MessageRepository({required this.remoteDataSource});

  final IMessageDriverRemoteDataSource remoteDataSource;
  Future<Either<Failure, bool>> sendMessage(
      String message, String rideId) async {
    try {
      final response = await remoteDataSource.sendMessage(message, rideId);

      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
