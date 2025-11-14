import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/token_storage.dart';
import '../../features/auth/domain/auth_state.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStorage tokenStorage,
    http.Client? client,
  })  : _tokenStorage = tokenStorage,
        _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    final headers = await _buildHeaders();
    final response = await _client.get(uri, headers: headers);
    _ensureSuccess(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool formUrlEncoded = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(formUrlEncoded: formUrlEncoded);
    final response = await _client.post(
      uri,
      headers: headers,
      body: formUrlEncoded ? body : jsonEncode(body),
    );
    _ensureSuccess(response);
    return response;
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders();
    final response = await _client.patch(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return response;
  }

  Future<Map<String, String>> _buildHeaders({bool formUrlEncoded = false}) async {
    final authState = _tokenStorage.read();
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (formUrlEncoded) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    } else {
      headers['Content-Type'] = 'application/json';
    }

    if (authState != null && authState.accessToken != null) {
      headers['Authorization'] = 'Bearer ${authState.accessToken}';
    }

    return headers;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

