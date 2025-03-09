import 'dart:convert';
import 'package:flutter/services.dart';

class MeetingService {
  static Future<Map<DateTime, List<String>>> loadMeetings() async {
    try {
      final String response = await rootBundle.loadString('assets/meetings.json');
      print("📢 JSON 데이터 로드 완료: $response");

      final Map<String, dynamic> data = json.decode(response);

      return data.map((key, value) => MapEntry(
        DateTime.parse(key),
        List<String>.from(value),
      ));
    } catch (e) {
      print("❌ JSON 로드 중 오류 발생: $e");
      return {};
    }
  }
}
