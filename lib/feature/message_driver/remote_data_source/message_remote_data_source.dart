import 'dart:convert';
import 'dart:io';

import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';

abstract class IMessageDriverRemoteDataSource {
  // Define the methods that will be implemented by the concrete class
  Future<bool> sendMessage(String message, String rideId);
  Future<String> receiveMessage();
}

class MessageRemoteDataSource implements IMessageDriverRemoteDataSource {
  MessageRemoteDataSource({required this.client});
  final BaseApiClients client;

  @override
  Future<String> receiveMessage() {
    // TODO: implement receiveMessage
    throw UnimplementedError();
  }

  @override
  Future<bool> sendMessage(String message, String rideId) async {
    try {
      final response = await client.post(
        '${Endpoints.messages}$rideId/message',
        body: {
          'message': message,
        },
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${await AppPreferences.getToken()}',
        },
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('msg')) {
        throw ServerException(decoded['msg'].toString());
      }
      if (decoded.containsKey('success')) {
        return decoded['success'] as bool;
      } else {
        throw ServerException('Unknown error occurred');
      }
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
