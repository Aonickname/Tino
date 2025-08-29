// api_services.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


// 그룹과 사용자 정보를 관리하는 API 서비스 클래스
class ApiService {
  final baseUrl = dotenv.env['API_BASE_URL'];

  // 사용자가 속한 그룹 목록을 가져오는 함수
  Future<List<dynamic>> fetchUserGroups(String username) async {
    final url = Uri.parse('$baseUrl/api/user-groups/$username');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load user groups');
    }
  }

  Future<void> createGroup(String name, String description,
      String username) async {
    final url = Uri.parse('$baseUrl/api/groups');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'username': username,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create group: ${response.body}');
    }
  }

  Future<void> deleteGroup(int groupId) async {
    final url = Uri.parse('$baseUrl/api/groups/$groupId');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete group: ${response.body}');
    }
  }

}