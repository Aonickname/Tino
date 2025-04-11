import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // jsonDecode 사용을 위한 import
import '../widgets/folder_appbar.dart'; // FolderAppbar 위젯 임포트

// 데이터를 JSON 형식으로 로드하는 함수
Future<Map<String, List<Map<String, String>>>> loadMeetingsFromJson() async {
  final url = 'http://3.35.184.31:8000/meetings';

  try {
    final response = await http.get(Uri.parse(url)); // GET 요청을 보냄

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body); // JSON 디코딩

      // 이미지 리스트
      final List<String> images = [
        'assets/images/User1.jpg',
        'assets/images/User2.jpg',
        'assets/images/User3.jpg',
        'assets/images/User4.jpg',
      ];
      int imageIndex = 0;

      print('JSON 데이터: $json'); // 로드된 JSON 데이터 출력

      return json.map((key, value) {
        List<Map<String, String>> meetings = (value as List).map((item) {
          final meeting = {
            "name": item["name"] as String,
            "description": item["description"] as String,
            "image": images[imageIndex % images.length], // 이미지 순환
          };
          imageIndex++;
          return meeting;
        }).toList();

        return MapEntry(key, meetings);
      });
    } else {
      throw Exception('서버에서 데이터를 가져오지 못했습니다.');
    }
  } catch (e) {
    print('Error loading data: $e'); // 에러 로그 출력
    throw Exception('회의 데이터를 불러올 수 없습니다.');
  }
}

// 날짜 포맷 함수 (ISO 8601 날짜를 한글로 변환)
String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);  // 날짜 파싱
    return "${date.year}년 ${date.month}월 ${date.day}일";  // 원하는 포맷으로 리턴
  } catch (e) {
    print("날짜 파싱 실패: $dateStr");  // 디버깅용
    return "날짜 형식 오류";  // 예외 처리
  }
}

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  bool _isLatestFirst = true; // 최신순과 오래된순을 전환하는 변수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '최근 회의 내역',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: Column(
          children: [
            FolderAppbar(), // FolderAppbar 위젯 추가
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight, // 오른쪽 상단 정렬
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLatestFirst = !_isLatestFirst; // 버튼 클릭 시 정렬 순서 변경
                    });
                  },
                  icon: Icon(
                    _isLatestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.black,
                    size: 18,
                  ),
                  label: Text(
                    _isLatestFirst ? "최신순" : "오래된순",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, List<Map<String, String>>>>(
                future: loadMeetingsFromJson(),  // loadMeetingsFromJson() 호출
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("에러: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData) {
                    return Center(child: Text("회의 데이터를 불러올 수 없습니다."));
                  }

                  final data = snapshot.data!;
                  final sortedDates = data.keys.toList()
                    ..sort((a, b) => _isLatestFirst
                        ? DateTime.parse(b).compareTo(DateTime.parse(a))
                        : DateTime.parse(a).compareTo(DateTime.parse(b)));  // 날짜로 정렬

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        ...sortedDates.expand((date) {
                          List<Map<String, String>> meetings = data[date]!;
                          return meetings.map((meeting) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(  // Row로 변경하여 수평 정렬
                                crossAxisAlignment: CrossAxisAlignment.start,  // 왼쪽 정렬
                                children: [
                                  Image.asset(
                                    meeting["image"] ?? 'assets/images/default.jpg',
                                    width: 200,
                                    height: 200,
                                  ),
                                  SizedBox(width: 10),  // 이미지와 텍스트 사이에 간격을 줌
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,  // 텍스트 왼쪽 정렬
                                    children: [
                                      Text(
                                        meeting["name"] ?? "회의 이름 없음",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(meeting["description"] ?? "설명 없음", style: TextStyle(fontSize: 14)),
                                      Text(formatDate(date), style: TextStyle(fontSize: 14, color: Colors.grey)),  // 날짜 포맷팅
                                    ],
                                  ),
                                ],
                              ),
                            );
                          });
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
