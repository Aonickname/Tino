import 'package:flutter/material.dart';
import '../style.dart';
import 'dart:ui';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert'; // JSON 파싱
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import '../widgets/home_appbar.dart';
import '../widgets/dialog.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int currentPage = 0;
  Timer? _timer;

  bool _isLatestFirst = true; // 최신순 기본

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
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

  //LTS에서 meeting.json 읽어오기
  // Future<Map<String, dynamic>> loadMeetingsFromJson() async {
  //   final response = await http.get(Uri.parse("http://127.0.0.1:8000/meetings"));
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body) as Map<String, dynamic>;
  //   } else {
  //     throw Exception("회의 데이터를 불러오는 데 실패했습니다.");
  //   }
  // }

  //LTS GET: json
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


  //LTS POST: json
  Future<void> saveMeetingToServer(String name, String description, String date, {bool is_interested = false, bool is_ended = false}) async {
    final url = Uri.parse('http://3.35.184.31:8000/meetings');

    final body = {
      "name": name,
      "description": description,
      "date": date,
      "is_interested": is_interested,
      "is_ended": is_ended,
    };

    print('Request Body: $body');

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

  //날짜 포매팅
  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);  // 날짜 문자열을 DateTime 객체로 변환
    return DateFormat('yyyy-MM-dd').format(dateTime);  // 원하는 형식으로 포맷
  }

  String getImageForMeeting(String title) {
    if (title.contains("티노")) return "assets/images/search_tino.jpg";
    if (title.contains("설계")) return "assets/images/question_tino.jpg";
    return "assets/images/user1.jpg";
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
          title: Text(
            '티노',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
          leading: Image.asset(
            'assets/images/small_tino.png',
            fit: BoxFit.contain,
          ),
          actions: [
            IconButton(onPressed: () {
              print("search click");
            }, icon: Icon(Icons.search)),
            IconButton(onPressed: () {
              print("notification click");
            }, icon: Icon(Icons.notifications_none)),
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
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
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
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

              SizedBox(height: 16.0),

              Container(
                child: Column(
                  children: [
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        SizedBox(width: 8.0),
                        Text(
                          'Title',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.black),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          child: Column(
                            
                            //새로운 회의 버튼
                            children: [
                              InkWell(
                                onTap: () async {
                                  // 다이얼로그 호출
                                  CustomDialogs.showInputDialogNewMeeting(
                                    context,
                                        (name, description, date) async {
                                      print("회의 이름: $name");
                                      print("회의 설명: $description");
                                      print("날짜: $date");

                                      // 서버에 새로운 회의 추가
                                      await saveMeetingToServer(name, description, date.toIso8601String(), is_interested: false, is_ended: false);

                                      // 화면 갱신
                                      setState(() {
                                        // 이 부분에서 회의 데이터를 새로 가져와서 리스트를 업데이트 할 수 있음
                                        // 예시: meetings = getUpdatedMeetings();
                                      });
                                    },
                                  );
                                },
                                child: Column(
                                  children: [
                                    Image.asset("assets/images/new_meeting.jpg", width: 150, height: 150),
                                    Text('새로운 회의', style: commonTextStyle),
                                  ],
                                ),
                              )
                              ,
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  CustomDialogs.showInputDialogUpload(
                                      context, (name, description) {
                                    print("회의 이름: $name");
                                    print("회의 설명: $description");
                                  });
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
                        ),
                      ],
                    )
                  ],
                ),
              ),

              SizedBox(height: 10),

              Container(

                child: Column(
                  children: [
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 8.0),
                            Text(
                              '최근 회의 내역',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.black),
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
                            color: Colors.black,
                            size: 18,
                          ),
                          label: Text(
                            _isLatestFirst ? "최신순" : "오래된순",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),


                    
                    //회의 데이터 출력
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
                                List<Map<String, String>> meetings = data[date]!;
                                return meetings.map((meeting) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.asset(
                                          meeting["image"] ?? 'assets/images/default.jpg', // ← 고정된 이미지 사용!
                                          width: 200,
                                          height: 200,
                                        ),
                                        Text(
                                          meeting["name"] ?? "회의 이름 없음",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                                        Text(meeting["description"] ?? "설명 없음",
                                          style: commonTextStyle,),
                                        Text(
                                          formatDate(date),
                                          style: commonTextStyle,),
                                      ],
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
