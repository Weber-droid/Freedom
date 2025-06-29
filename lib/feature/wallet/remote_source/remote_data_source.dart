import 'package:freedom/feature/wallet/remote_source/add_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_response.dart';
import 'package:freedom/feature/wallet/remote_source/add_momo_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/delete_card.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';

abstract class RemoteDataSource {
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<AddCardResponse> addNewCard(AddCardModel addCardModel);
  Future<AddCardResponse> addMomoCard(AddMomoCardModel addMomoCard);
  Future<DeleteCardResponse> removeCard(String cardId);
}
