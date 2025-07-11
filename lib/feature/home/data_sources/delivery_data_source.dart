import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/models/delivery_request_response.dart';
import 'package:freedom/feature/home/repository/models/delivery_status_response.dart';
import 'package:http/http.dart';

abstract class IDeliveryRemoteDataSource {
  Future<DeliveryRequestResponse> requestDelivery(
    DeliveryModel deliveryRequestModel,
  );
  Future<void> cancelDelivery(String deliveryId, String reason);

  Future<void> updateDeliveryStatus(String deliveryId, String status);
  Future<void> trackDelivery(String deliveryId);

  Future<DeliveryStatusResponse> checkDeliveryStatus(String deliveryId);
}

class DeliveryDataSourceImpl implements IDeliveryRemoteDataSource {
  @override
  Future<dynamic> cancelDelivery(String deliveryId, String reason) async {
    try {
      final client = getIt<BaseApiClients>();
      final response = await client.post(
        '${Endpoints.cancelDelivery}$deliveryId/cancel',
        body: {'reason': reason},
        headers: {'Authorization': 'Bearer ${await AppPreferences.getToken()}'},
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('success') && decoded['success'] == false) {
        throw ServerException(decoded['msg'].toString());
      } else if (decoded.containsKey('message') && decoded['success'] == true) {
        return DeliveryRequestResponse.fromJson(decoded);
      }
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<DeliveryRequestResponse> requestDelivery(
    DeliveryModel deliveryRequestModel,
  ) async {
    final client = getIt<BaseApiClients>();
    try {
      final response = await client.post(
        Endpoints.deliveryRequest,
        body: deliveryRequestModel.toJson(),
        headers: {'Authorization': 'Bearer ${await AppPreferences.getToken()}'},
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('requestDelivery(): $decoded');
      if (decoded.containsKey('success') && decoded['success'] == false) {
        log('requestDelivery() error: ${decoded['msg']}');
        throw ServerException(decoded['msg'].toString());
      }
      return DeliveryRequestResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
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

  @override
  Future<DeliveryStatusResponse> checkDeliveryStatus(String deliveryId) async {
    try {
      final client = getIt<BaseApiClients>();
      final response = await client.get(
        '${Endpoints.trackDelivery}$deliveryId/track',
        headers: {'Authorization': 'Bearer ${await AppPreferences.getToken()}'},
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('checkDeliveryStatus(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      return DeliveryStatusResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
