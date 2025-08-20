import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/folder_appbar.dart';
import 'detail_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


// 서버에서 회의 데이터를 삭제하는 함수
Future<void> deleteMeetingFromServer(String directory) async {

  final baseUrl = dotenv.env['API_BASE_URL'];

  final url = '$baseUrl/delete/$directory';

  try {
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('삭제 실패');
    }
  } catch (e) {
    print('삭제 중 오류 발생: $e');
  }
}



// 서버에서 회의 데이터를 불러오는 함수
Future<Map<String, List<Map<String, String>>>> loadMeetingsFromJson() async {
  final baseUrl = dotenv.env['API_BASE_URL'];

  final url = '$baseUrl/api/meetings';

  try {
    // HTTP GET 요청을 보냄 (브라우저 경고 제거 헤더 포함)
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'ngrok-skip-browser-warning': 'true',
      },
    );

    // 서버 응답이 성공적일 경우
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      // 사용자 이미지 리스트 (순환하며 사용)
      final List<String> images = [
        'assets/images/User1.jpg',
        'assets/images/User2.jpg',
        'assets/images/User3.jpg',
        'assets/images/User4.jpg',
      ];
      int imageIndex = 0;

      // 날짜별로 회의 데이터를 구성해서 반환
      return json.map((key, value) {
        List<Map<String, String>> meetings = (value as List).map((item) {
          final meeting = {
            "name": item["name"] as String,
            "description": item["description"] as String,
            "directory": item["directory"]?.toString() ?? "",
            "image": images[imageIndex % images.length],
            "is_interested": item["is_interested"].toString(),
            "is_ended": item["is_ended"].toString(),
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

// 날짜 문자열을 보기 좋은 형식으로 변환
String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return "${date.year}년 ${date.month}월 ${date.day}일";
  } catch (e) {
    return "날짜 형식 오류";
  }
}

// 폴더 스크린 - 회의 내역을 보여주는 메인 화면
class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  bool _isLatestFirst = true; // 최신순, 오래된순 정렬 플래그
  int _selectedIndex = 0; // 필터 인덱스 (전체, 관심, 진행중, 종료됨)

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
          // 필터 버튼들 (FolderAppbar 위젯 내부 구현)
          FolderAppbar(
            onIndexChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          // 정렬 방식 버튼 (최신순 / 오래된순)
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

          // 본격적인 회의 목록
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, String>>>>(
              future: loadMeetingsFromJson(), // 데이터를 가져오는 Future
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // 로딩 중
                }

                if (snapshot.hasError) {
                  return Center(child: Text("에러: ${snapshot.error}")); // 에러 발생
                }

                if (!snapshot.hasData) {
                  return Center(child: Text("회의 데이터를 불러올 수 없습니다.")); // 데이터 없음
                }

                final data = snapshot.data!;

                final baseUrl = dotenv.env['API_BASE_URL'];

                final sortedDates = data.keys.toList()
                  ..sort((a, b) => _isLatestFirst
                      ? DateTime.parse(b).compareTo(DateTime.parse(a))
                      : DateTime.parse(a).compareTo(DateTime.parse(b)));

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      // 날짜별로 회의 그룹을 정렬해서 출력
                      ...sortedDates.expand((date) {
                        List<Map<String, String>> meetings = data[date]!;

                        // 필터 조건에 따라 걸러냄
                        final filteredMeetings = meetings.where((meeting) {
                          if (_selectedIndex == 1) {
                            return meeting["is_interested"] == "true";
                          }
                          if (_selectedIndex == 2) {
                            return meeting["is_ended"] == "false"; // 진행 중
                          }
                          if (_selectedIndex == 3) {
                            return meeting["is_ended"] == "true"; // 종료됨
                          }
                          return true; // 전체 보기
                        }).toList();

                        // 필터링된 회의 리스트를 위젯으로 변환
                        return filteredMeetings.map((meeting) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      name: meeting["name"] ?? "",
                                      description: meeting["description"] ?? "",
                                      date: formatDate(date),
                                      directory: meeting["directory"] ?? "",
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    meeting["image"] ?? 'assets/images/default.jpg',
                                    width: 200,
                                    height: 200,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
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
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      meeting["is_interested"] == "true" ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () async {

                                      final newStatus = meeting["is_interested"] != "true";
                                      final response = await http.patch(
                                        Uri.parse('$baseUrl/meetings/interested'),
                                        headers: {"Content-Type": "application/json"},
                                        body: jsonEncode({
                                          "directory": meeting["directory"],
                                          "is_interested": newStatus,
                                        }),
                                      );
                                      if (response.statusCode == 200) {
                                        setState(() {}); // UI 새로고침
                                      } else {
                                        print("관심 상태 업데이트 실패");
                                      }
                                    },
                                  ),
                                  // 삭제 버튼
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: Text('새로운 회의'),
                                          content: Text('이 회의 데이터를 삭제하면 복구할 수 없습니다.'),
                                          actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          actionsAlignment: MainAxisAlignment.spaceEvenly,
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                backgroundColor: Colors.grey[200],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                minimumSize: Size(100, 40),
                                              ),
                                              child: Text('취소'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                minimumSize: Size(100, 40),
                                              ),
                                              child: Text('삭제'),
                                            ),
                                          ],),
                                      );
                                      if (confirm == true) {
                                        await deleteMeetingFromServer(meeting["directory"] ?? "");
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),

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
