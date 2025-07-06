import 'package:dartz/dartz.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/auth/repository/repository_exceptions.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_response.dart';
import 'package:freedom/feature/wallet/remote_source/add_momo_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/delete_card.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';
import 'package:freedom/feature/wallet/remote_source/remote_data_source.dart';
import 'package:freedom/feature/wallet/remote_source/remote_data_source_impl.dart';

class WalletRepository {
  factory WalletRepository() => _instance;

  WalletRepository._internal() {
    _remoteDataSource = RemoteDataSourceImpl();
  }

  static final WalletRepository _instance = WalletRepository._internal();
  late final RemoteDataSource _remoteDataSource;

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      return await _remoteDataSource.getPaymentMethods();
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  Future<Either<Failure, AddCardResponse>> addNewCard(
      AddCardModel addCardModel) async {
    try {
      final result = await _remoteDataSource.addNewCard(addCardModel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      throw Exception('Failed to add new card: $e');
    }
  }

  Future<Either<Failure, AddCardResponse>> addMomoCard(
      AddMomoCardModel addMomoCard) async {
    try {
      final result = await _remoteDataSource.addMomoCard(addMomoCard);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      throw Exception('Failed to add new card: $e');
    }
  }

  Future<Either<Failure, DeleteCardResponse>> removeCard(String id) async {
    try {
      final response = await _remoteDataSource.removeCard(id);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
