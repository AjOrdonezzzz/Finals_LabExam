import 'dart:convert';

import 'package:http/http.dart' as http;

class RecommendationApi {
  RecommendationApi({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://6accb11bb406cb8ec0c6531f.mockapi.io';
  static const String resource = 'post';
  final http.Client _client;

  Uri _uri([String? id]) => Uri.parse('$baseUrl/$resource${id == null ? '' : '/${Uri.encodeComponent(id)}'}');

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await _client.get(_uri()).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException('Could not load recommendations (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('The API did not return a list of posts.');
    return decoded.map((value) => Map<String, dynamic>.from(value as Map)).toList();
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> post) async {
    final response = await _client
        .post(_uri(), headers: _headers, body: jsonEncode(post))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw HttpException('Could not create recommendation (${response.statusCode}).');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> changes) async {
    final response = await _client
        .patch(_uri(id), headers: _headers, body: jsonEncode(changes))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Could not update recommendation (${response.statusCode}).');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Map<String, String> get _headers => const {'Content-Type': 'application/json; charset=UTF-8'};
}

class HttpException implements Exception {
  const HttpException(this.message);
  final String message;
  @override
  String toString() => message;
}


