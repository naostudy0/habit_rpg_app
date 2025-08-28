import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = EnvironmentConfig.baseUrl;

  // ヘッダーの設定
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ログインAPI
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/test'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('ログインに失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('ネットワークエラー: $e');
    }
  }
}
