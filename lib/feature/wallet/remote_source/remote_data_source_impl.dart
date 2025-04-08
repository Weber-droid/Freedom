import 'dart:convert';
import 'dart:developer';

import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_response.dart';
import 'package:freedom/feature/wallet/remote_source/add_momo_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/delete_card.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';
import 'package:freedom/feature/wallet/remote_source/remote_data_source.dart';


class RemoteDataSourceImpl extends RemoteDataSource {
  final client = getIt<BaseApiClients>();

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await client.get(
        Endpoints.getPaymentMethods,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZWEwYjI2YWJmZGFmY2I3MTRiMTQzNSIsIm5hbWUiOiJKYW1iaXQgS2Fzb25nbyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQzNzYyNDExLCJleHAiOjE3NTI0MDI0MTF9.vRyh4sWbbPt2Nskvx8o3RERUDEQoqGhIiFtgzzlDVtE'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        log('remote data source(): $jsonData');
        final userPaymentMethodsResponse = UserPaymentMethodsResponse.fromJson(jsonData);
        return userPaymentMethodsResponse.data;
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  @override
  Future<AddCardResponse> addNewCard(AddCardModel addCardModel) async {
    try {
      final response = await client.post(
        Endpoints.addNewCard,
        body: {
          'type': 'card',
          'cardType': 'mastercard',
          'last4': addCardModel.last4,
          'expiryMonth': addCardModel.expiryMonth,
          'expiryYear': addCardModel.expiryYear,
          'isDefault': true,
          'cardDetails': {
            'number': addCardModel.cardDetails?.cardNumber ?? '',
            'cvv': addCardModel.cardDetails?.cvv,
            'expiryMonth': addCardModel.cardDetails?.expiryMonth,
            'expiryYear': addCardModel.cardDetails?.expiryYear,
          }
        },
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZWEwYjI2YWJmZGFmY2I3MTRiMTQzNSIsIm5hbWUiOiJKYW1iaXQgS2Fzb25nbyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQzNzYyNDExLCJleHAiOjE3NTI0MDI0MTF9.vRyh4sWbbPt2Nskvx8o3RERUDEQoqGhIiFtgzzlDVtE'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return AddCardResponse.fromJson(body);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw Exception('Failed to add new card: $e');
    }
  }

  @override
  Future<AddCardResponse> addMomoCard(AddMomoCardModel addMomoCard) async {
    try {
      final response = await client.post(
        Endpoints.addNewCard,
        body:{
          'type': addMomoCard.type,
          'momoProvider': addMomoCard.momoProvider,
          'momoNumber': addMomoCard.momoNumber,
          'isDefault': addMomoCard.isDefault
        },
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZWEwYjI2YWJmZGFmY2I3MTRiMTQzNSIsIm5hbWUiOiJKYW1iaXQgS2Fzb25nbyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQzNzYyNDExLCJleHAiOjE3NTI0MDI0MTF9.vRyh4sWbbPt2Nskvx8o3RERUDEQoqGhIiFtgzzlDVtE'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return AddCardResponse.fromJson(body);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw Exception('Failed to add new card: $e');
    }
  }

  @override
  Future<DeleteCardResponse> removeCard(String cardId) async {
    try{
      final response = await client.delete(
        '${Endpoints.removeCard}/$cardId',
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3ZWEwYjI2YWJmZGFmY2I3MTRiMTQzNSIsIm5hbWUiOiJKYW1iaXQgS2Fzb25nbyIsInJvbGUiOiJ1c2VyIiwiaWF0IjoxNzQzNzYyNDExLCJleHAiOjE3NTI0MDI0MTF9.vRyh4sWbbPt2Nskvx8o3RERUDEQoqGhIiFtgzzlDVtE'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DeleteCardResponse.fromJson(json);
      } else {
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorResponse['message'] as String? ??
              'Server error: ${response.statusCode}';
          throw ServerException(errorMessage);
        } catch (e) {
          throw ServerException(
              'Server error: ${response.statusCode} - ${response.body}');
        }
      }
    } on NetworkException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw Exception('Failed to remove card: $e');
    }
  }

}