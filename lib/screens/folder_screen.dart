import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/folder_appbar.dart';

Future<Map<String, List<Map<String, String>>>> loadMeetingsFromJson() async {
  // final url = 'http://34.22.86.69:8000/meetings';
  final url = 'https://7ccf-182-219-240-41.ngrok-free.app/meetings'; //ngrok 사용

  try {
    final response = await http.get(Uri.parse(url),
      headers: {
        'ngrok-skip-browser-warning': 'true', // ngrok 에서 경고 html 생략
      },);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      final List<String> images = [
        'assets/images/User1.jpg',
        'assets/images/User2.jpg',
        'assets/images/User3.jpg',
        'assets/images/User4.jpg',
      ];
      int imageIndex = 0;

      return json.map((key, value) {
        List<Map<String, String>> meetings = (value as List).map((item) {
          final meeting = {
            "name": item["name"] as String,
            "description": item["description"] as String,
            "image": images[imageIndex % images.length],
            "is_interested": item["is_interested"].toString(),
            "is_ended": item["is_ended"].toString(), // is_ended 추가
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
    print('Error loading data: $e');
    throw Exception('회의 데이터를 불러올 수 없습니다.');
  }
}

String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return "${date.year}년 ${date.month}월 ${date.day}일";
  } catch (e) {
    return "날짜 형식 오류";
  }
}

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  bool _isLatestFirst = true;
  int _selectedIndex = 0; // ← 필터 인덱스 상태 추가

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('최근 회의 내역', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          FolderAppbar(
            onIndexChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isLatestFirst = !_isLatestFirst;
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
              future: loadMeetingsFromJson(),
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
                      : DateTime.parse(a).compareTo(DateTime.parse(b)));

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      ...sortedDates.expand((date) {
                        List<Map<String, String>> meetings = data[date]!;

                        // 필터링 조건 적용
                        final filteredMeetings = meetings.where((meeting) {
                          if (_selectedIndex == 1) {
                            return meeting["is_interested"] == "true";
                          }
                          if (_selectedIndex == 2) {
                            return meeting["is_ended"] == "false"; // 진행 중인 회의
                          }
                          if (_selectedIndex == 3) {
                            return meeting["is_ended"] == "true"; // 종료된 회의
                          }
                          return true;
                        }).toList();

                        return filteredMeetings.map((meeting) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  meeting["image"] ?? 'assets/images/default.jpg',
                                  width: 200,
                                  height: 200,
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meeting["name"] ?? "회의 이름 없음",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      meeting["description"] ?? "설명 없음",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      formatDate(date),
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
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
    );
  }
}
