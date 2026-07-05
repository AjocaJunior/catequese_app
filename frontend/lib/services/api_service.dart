import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> checkHealth() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/health');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Falha ao contactar a API (status ${response.statusCode})');
  }
}
