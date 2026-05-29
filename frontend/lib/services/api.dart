import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000',
);

class Api {
  static String? token;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  static Future<void> saveAuth(
      String authToken, Map<String, dynamic> user) async {
    token = authToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', authToken);
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<void> logout() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final msg = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : 'Request failed';
    throw Exception(msg);
  }

  static Future<dynamic> get(String path) async => _decode(
        await http.get(Uri.parse('$apiBase$path'), headers: headers),
      );

  static Future<dynamic> post(String path, Map<String, dynamic> data) async =>
      _decode(
        await http.post(Uri.parse('$apiBase$path'),
            headers: headers, body: jsonEncode(data)),
      );

  static Future<dynamic> put(String path, Map<String, dynamic> data) async =>
      _decode(
        await http.put(Uri.parse('$apiBase$path'),
            headers: headers, body: jsonEncode(data)),
      );

  static Future<dynamic> delete(String path) async => _decode(
        await http.delete(Uri.parse('$apiBase$path'), headers: headers),
      );

  static Future<dynamic> uploadProfilePhoto(XFile image) async {
    final bytes = await image.readAsBytes();
    final req =
        http.MultipartRequest('POST', Uri.parse('$apiBase/profile/photo'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files
        .add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
    final res = await req.send();
    return _decode(await http.Response.fromStream(res));
  }
}
