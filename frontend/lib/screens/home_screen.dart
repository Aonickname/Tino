import 'package:flutter/material.dart';
import '../style.dart';
import 'dart:ui';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import '../widgets/home_appbar.dart';
import '../widgets/dialog.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'detail_screen.dart';
import 'record_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// HomeScreen은 앱의 메인 화면을 구성하는 StatefulWidget.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // PageView 컨트롤러: 배너 이미지를 자동으로 넘기기 위해 사용
  final PageController _pageController = PageController(initialPage: 0);
  int currentPage = 0;                    // 현재 보여지는 배너 페이지 인덱스
  Timer? _timer;                          // 자동 스크롤을 위한 타이머

  bool _isLatestFirst = true;            // 회의 목록을 최신순/오래된순 토글

  @override
  void initState() {
    super.initState();
    _startAutoScroll();                  // 화면 로드 시 배너 자동 스크롤 시작
  }

  // 배너를 3초마다 넘기는 타이머 설정
  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (currentPage < 2) {
        currentPage++;
      } else {
        currentPage = 0;
      }

      _pageController.animateToPage(
        currentPage,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();                    // 타이머 해제
    _pageController.dispose();           // 컨트롤러 해제
    super.dispose();
  }

  /// 서버에서 회의 데이터를 JSON 형태로 불러와서
  /// 날짜별로 그룹화된 Map<String, List<회의 정보>> 형태로 반환
  Future<Map<String, List<Map<String, String>>>> loadMeetingsFromJson() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'];
      final url = '$baseUrl/api/meetings';

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // 더미 이미지 리스트: 서버 데이터에 이미지 필드가 없는 경우 사용
        final List<String> images = [
          'assets/images/User1.jpg',
          'assets/images/User2.jpg',
          'assets/images/User3.jpg',
          'assets/images/User4.jpg',
        ];
        int imageIndex = 0;

        // 서버에서 받은 JSON을 Dart Map으로 변환
        return json.map((key, value) {
          List<Map<String, String>> meetings = (value as List).map((item) {
            final meeting = {
              "name": item["name"] as String,
              "description": item["description"] as String,
              "directory": item["directory"]?.toString() ?? "",
              // 순서대로 더미 이미지 할당
              "image": images[imageIndex % images.length],
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
      print('Error loading data: \$e');
      throw Exception('회의 데이터를 불러올 수 없습니다.');
    }
  }

  /// 새로운 회의를 JSON으로 서버에 저장
  Future<void> saveMeetingToServer(String name, String description, String date, {
    bool is_interested = false, bool is_ended = false
  }
      ) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final url = Uri.parse('$baseUrl/meetings');

    final body = {
      "name": name,
      "description": description,
      "date": date,
      "is_interested": is_interested,
      "is_ended": is_ended,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("회의 저장 완료!");
      } else {
        print("서버 오류: \${response.statusCode}");
      }
    } catch (e) {
      print("에러 발생: \$e");
    }
  }

  /// ISO 형식의 날짜 문자열을 'yyyy-MM-dd' 형태로 변환
  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// 회의 제목에 따라 보여줄 이미지 선택 (예시 로직)
  String getImageForMeeting(String title) {
    if (title.contains("티노")) return "assets/images/search_tino.jpg";
    if (title.contains("설계")) return "assets/images/question_tino.jpg";
    return "assets/images/user1.jpg";
  }

  /// 오디오 파일을 포함하여 multipart/form-data로 업로드
  Future<void> uploadMeetingWithFile(
      String name,
      String description,
      File file,
      DateTime date,
      String summaryMode,
      String customPrompt
      ) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final url = Uri.parse('$baseUrl/upload');

    var request = http.MultipartRequest('POST', url)
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['date'] = date.toIso8601String()
      ..fields['summary_mode'] = summaryMode
      ..fields['custom_prompt'] = customPrompt  // 사용자 지정 텍스트
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print("업로드 성공!");
      } else {
        print("업로드 실패: \${response.statusCode}");
      }
    } catch (e) {
      print("에러 발생: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown
        },
      ),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        bottomNavigationBarTheme: bottomNavBarTheme,  // 스타일 테마 적용
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('티노', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
          leading: Image.asset('assets/images/small_tino.png'),
          actions: [
            IconButton(onPressed: () => print("search click"), icon: Icon(Icons.search)),
            IconButton(onPressed: () => print("notification click"), icon: Icon(Icons.notifications_none)),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 커스텀 앱바 위젯
              HomeAppBarWidget(),
              SizedBox(height: 16.0),

              // 배너 이미지 자동 슬라이드
              Container(
                height: 200,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: PageView(
                        controller: _pageController,
                        children: [
                          Image.asset("assets/images/banner1.jpg", fit: BoxFit.cover),
                          Image.asset("assets/images/banner2.jpg", fit: BoxFit.cover),
                          Image.asset("assets/images/banner3.jpg", fit: BoxFit.cover),
                        ],
                      ),
                    ),
                    // 배너 인디케이터
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: 3,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.blue,
                            dotHeight: 5,
                            dotWidth: 5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.0),

              // 새 회의 생성 버튼 및 녹음 파일 업로드 버튼 영역
              Row(
                children: [
                  SizedBox(width: 20),

                  // 새 회의 생성
                  InkWell(
                    onTap: () async {
                      CustomDialogs.showInputDialogNewMeeting(
                        context,
                            (name, description, date) async {
                          // 회의명, 설명, 날짜 입력 후 서버 저장
                          await saveMeetingToServer(name, description, date.toIso8601String());

                          // 저장 완료 후 녹음 화면으로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordScreen(
                                meetingName: name,
                                meetingDescription: description,
                                meetingDate: date,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Column(
                      children: [
                        Image.asset("assets/images/new_meeting.jpg", width: 150, height: 150),
                        Text('새로운 회의', style: commonTextStyle),
                      ],
                    ),
                  ),

                  SizedBox(width: 20),

                  // 녹음 업로드
                  InkWell(
                    onTap: () {
                      CustomDialogs.showInputDialogUpload(
                        context,
                            (name, description, file, date, summaryMode, customPrompt) async {
                          if (file != null) {
                            await uploadMeetingWithFile(name, description, file, date, summaryMode, customPrompt);
                            setState(() {}); // 업로드 후 화면 갱신
                          } else {
                            print("파일이 선택되지 않았습니다.");
                          }
                        },
                      );
                    },
                    child: Column(
                      children: [
                        Image.asset("assets/images/mp3_upload.jpg", width: 150, height: 150),
                        Text('녹음 업로드', style: commonTextStyle),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // 최근 회의 내역 리스트
              Container(
                child: Column(
                  children: [
                    // 헤더: 제목 및 정렬 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 8.0),
                            Text('최근 회의 내역', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLatestFirst = !_isLatestFirst; // 정렬 순서 토글
                            });
                          },
                          icon: Icon(
                            _isLatestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 18,
                          ),
                          label: Text(_isLatestFirst ? "최신순" : "오래된순"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    // 서버에서 로드된 회의 데이터 표시
                    FutureBuilder<Map<String, List<Map<String, String>>>>(
                      future: loadMeetingsFromJson(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator()); // 로딩 중
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("에러: \${snapshot.error}")); // 에러 표시
                        }
                        if (!snapshot.hasData) {
                          return Center(child: Text("회의 데이터를 불러올 수 없습니다."));
                        }

                        // 날짜 키를 정렬하여 순서 지정
                        final data = snapshot.data!;
                        final sortedDates = data.keys.toList()
                          ..sort((a, b) => _isLatestFirst ? b.compareTo(a) : a.compareTo(b));

                        // 가로 스크롤 가능한 회의 카드 리스트
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(width: 20),
                              ...sortedDates.expand((date) {
                                return data[date]! .map((meeting) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () {
                                        // 카드 클릭 시 상세화면으로 이동
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 회의 대표 이미지
                                          Image.asset(meeting["image"]!, width: 200, height: 200),

                                          // 회의 제목, 설명, 날짜
                                          Text(meeting["name"] ?? "회의 이름 없음",
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(meeting["description"] ?? "설명 없음", style: commonTextStyle),
                                          Text(formatDate(date), style: commonTextStyle),
                                        ],
                                      ),

                                    ),
                                  );
                                }).toList();
                              }).toList(),
                              SizedBox(width: 20),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
