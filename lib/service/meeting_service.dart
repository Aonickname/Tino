import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MeetingService {
  static Future<Map<DateTime, List<String>>> loadMeetings() async {
    try {
      // 서버에서 JSON 데이터 가져오기
      final response = await http.get(
          Uri.parse('http://127.0.0.1:8000/meetings'));

      // HTTP 응답 상태 코드 확인
      if (response.statusCode == 200) {
        print("📢 JSON 데이터 로드 완료");

        // JSON 디코딩
        final Map<String, dynamic> data = json.decode(response.body);

        // DateTime으로 변환 후 반환
        return data.map((key, value) =>
            MapEntry(
              DateTime.parse(key),
              List<String>.from(value),
            ));
      } else {
        print("❌ 서버에서 데이터를 가져오는 데 실패: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("❌ JSON 로드 중 오류 발생: $e");
      return {};
    }
  }
}
