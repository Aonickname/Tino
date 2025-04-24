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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int currentPage = 0;
  Timer? _timer;

  bool _isLatestFirst = true;

  @override
  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }


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
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }


  Future<Map<String, List<Map<String, String>>>> loadMeetingsFromJson() async {
    try {
      final url = 'https://amoeba-national-mayfly.ngrok-free.app/meetings';

      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

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
              "directory": item["directory"]?.toString() ?? "",
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
      print('Error loading data: $e');
      throw Exception('회의 데이터를 불러올 수 없습니다.');
    }
  }

  Future<void> saveMeetingToServer(String name, String description, String date,
      {bool is_interested = false, bool is_ended = false}) async {
    final url = Uri.parse('https://amoeba-national-mayfly.ngrok-free.app/meetings');

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
        print("서버 오류: ${response.statusCode}");
      }
    } catch (e) {
      print("에러 발생: $e");
    }
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  String getImageForMeeting(String title) {
    if (title.contains("티노")) return "assets/images/search_tino.jpg";
    if (title.contains("설계")) return "assets/images/question_tino.jpg";
    return "assets/images/user1.jpg";
  }

  Future<void> uploadMeetingWithFile(String name, String description, File file, DateTime date) async {
    final url = Uri.parse('https://amoeba-national-mayfly.ngrok-free.app/upload');

    var request = http.MultipartRequest('POST', url)
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['date'] = date.toIso8601String()
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print("업로드 성공!");
      } else {
        print("업로드 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("에러 발생: $e");
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
        bottomNavigationBarTheme: bottomNavBarTheme,
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
              HomeAppBarWidget(),
              SizedBox(height: 16.0),
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
              Row(
                children: [
                  SizedBox(width: 20),
                  InkWell(
                    onTap: () async {
                      CustomDialogs.showInputDialogNewMeeting(
                        context,
                            (name, description, date) async {
                          await saveMeetingToServer(name, description, date.toIso8601String());
                          setState(() {});
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
                  InkWell(
                    onTap: () {
                      CustomDialogs.showInputDialogUpload(
                        context,
                            (name, description, file, date) async {
                          if (file != null) {
                            await uploadMeetingWithFile(name, description, file, date);
                            setState(() {});
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
              Container(
                child: Column(
                  children: [
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
                              _isLatestFirst = !_isLatestFirst;
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
                    FutureBuilder<Map<String, List<Map<String, String>>>>(
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
                          ..sort((a, b) => _isLatestFirst ? b.compareTo(a) : a.compareTo(b));

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(width: 20),
                              ...sortedDates.expand((date) {
                                return data[date]!.map((meeting) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Image.asset(meeting["image"]!, width: 200, height: 200),

                                          // 회의 제목/설명/날짜
                                          Text(meeting["name"] ?? "회의 이름 없음",
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(meeting["description"] ?? "설명 없음", style: commonTextStyle),
                                          Text(formatDate(date), style: commonTextStyle),
                                        ],
                                      ),

                                    ),
                                  );
                                });
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
