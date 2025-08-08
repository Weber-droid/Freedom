import 'dart:convert';

import 'package:freedom/core/client/base_api_client.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/core/client/endpoints.dart';
import 'package:http/http.dart';

Map<String, String> splitName(String? displayName) {
  if (displayName == null || displayName.trim().isEmpty) {
    return {'firstName': '', 'surname': '', 'otherName': ''};
  }

  final parts = displayName.trim().split(' ');
  final firstName = parts.isNotEmpty ? parts.first : '';
  final surname = parts.length > 1 ? parts.last : '';
  final otherName =
      parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : '';

  return {'firstName': firstName, 'surname': surname, 'otherName': otherName};
}

Future<Response> postUserToBackend(
  Map<String, dynamic> body,
  BaseApiClients client,
) async {
  final response = await client.post(
    Endpoints.addGoogleUser,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  return response;
}

Map<String, dynamic> decodeResponse(Response response) {
  final decoded = json.decode(response.body) as Map<String, dynamic>;

  if (response.statusCode == 200 || response.statusCode == 201) {
    return decoded;
  } else {
    throw ServerException(decoded['message'].toString());
  }
}
