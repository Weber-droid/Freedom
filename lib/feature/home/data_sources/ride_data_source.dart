import 'dart:convert';
import 'dart:io';

import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/feature/History/model/history_model.dart';
import 'package:freedom/feature/home/models/cancel_ride_response.dart';
import 'package:freedom/feature/home/models/multiple_stop_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_model.dart';
import 'package:freedom/feature/home/models/request_ride_response.dart';
import 'package:freedom/feature/home/models/ride_status_response.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

abstract class RideRemoteDataSource {
  Future<RequestRideResponse> requestRide(RideRequestModel requestRideModel);
  Future<MultipleStopsResponse> requestMultipleStopRide(
    MultipleStopRideModel requestRideModel,
  );
  Future<RideCancellationResponse> cancelRide(String rideId, String reason);
  Future<void> acceptRide(String rideId);
  Future<void> completeRide(String rideId);
  Future<void> updateRideStatus(String rideId, String status);
  Future<RideHistoryResponse> getRideHistory(
      String status, int page, int limit);
  Future<void> trackRide(String rideId);
  Future<void> rateDriver(String rideId, int rating);
  Future<RideStatusResponse> checkRideStatus(String rideId);
}

class RideRemoteDataSourceImpl implements RideRemoteDataSource {
  RideRemoteDataSourceImpl({required this.client});
  final BaseApiClients client;
  @override
  Future<void> acceptRide(String rideId) {
    throw UnimplementedError();
  }

  @override
  Future<RideCancellationResponse> cancelRide(
      String rideId, String reason) async {
    final response = await client.post(
      '${Endpoints.cancelRide}$rideId/cancel',
      body: {
        'reason': reason,
      },
      headers: {'Authorization': 'Bearer ${await AppPreferences.getToken()}'},
    );
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    log('cancelRide(): $decoded');
    if (decoded.containsKey('msg')) {
      throw ServerException(decoded['msg'].toString());
    }

    return RideCancellationResponse.fromJson(decoded);
  }

  @override
  Future<RideStatusResponse> checkRideStatus(String rideId) async {
    try {
      final response = await client.get('${Endpoints.status}$rideId', headers: {
        'Authorization': 'Bearer ${await AppPreferences.getToken()}',
      });
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('checkRideStatus(): $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }

      return RideStatusResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> completeRide(String rideId) {
    // TODO: implement completeRide
    throw UnimplementedError();
  }

  @override
  Future<RideHistoryResponse> getRideHistory(
      String status, int page, int limit) async {
    try {
      log('Fetching ride history with status: $status, page: $page, limit: $limit');
      final response = await client.get(
        '${Endpoints.getRides}?status=$status&page=$page&limit=$limit',
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${await AppPreferences.getToken()}',
        },
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('Response: $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      log('Response decoded: $decoded');
      return RideHistoryResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> rateDriver(String rideId, int rating) {
    // TODO: implement rateDriver
    throw UnimplementedError();
  }

  @override
  Future<MultipleStopsResponse> requestMultipleStopRide(
    MultipleStopRideModel requestRideModel,
  ) async {
    try {
      log('Requesting ride with model: ${requestRideModel.toJson()}');
      final response = await client.post(
        Endpoints.requestRide,
        body: requestRideModel.toJson(),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${await AppPreferences.getToken()}',
        },
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('Response: $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      log('Response decoded: $decoded');
      return MultipleStopsResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RequestRideResponse> requestRide(
    RideRequestModel requestRideModel,
  ) async {
    try {
      log('Requesting ride with model 🧨🧨: ${requestRideModel.toJson()}');
      final response = await client.post(
        Endpoints.requestRide,
        body: requestRideModel.toJson(),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${await AppPreferences.getToken()}',
        },
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      log('Response: $decoded');
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      log('Response decoded: $decoded');
      return RequestRideResponse.fromJson(decoded);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
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
}
