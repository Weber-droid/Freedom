import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:freedom/feature/History/model/history_model.dart';

class HistoryRemoteDataSource {
  HistoryRemoteDataSource({required this.client});
  final BaseApiClients client;

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
}
