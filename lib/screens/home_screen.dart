import 'package:flutter/material.dart';
import '../style.dart';
import 'dart:ui';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert'; // JSON 파싱
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import '../widgets/home_appbar.dart';
import '../widgets/dialog.dart';

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

  Future<Map<String, dynamic>> loadMeetingsFromJson() async {
    String jsonString = await rootBundle.loadString('assets/meetings.json');
    return json.decode(jsonString);
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
                            children: [
                              InkWell(
                                onTap: () {
                                  CustomDialogs.showInputDialogNewMeeting(
                                      context, (name, description, date) {
                                    print("회의 이름: $name");
                                    print("회의 설명: $description");
                                    print("날짜: $date");
                                  });
                                },
                                child: Column(
                                  children: [
                                    Image.asset("assets/images/new_meeting.jpg", width: 150, height: 150),
                                    Text('새로운 회의', style: commonTextStyle),
                                  ],
                                ),
                              ),
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

                    FutureBuilder<Map<String, dynamic>>(
                      future: loadMeetingsFromJson(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData) {
                          return Center(child: Text("회의 데이터를 불러올 수 없습니다."));
                        }

                        final data = snapshot.data!;
                        final sortedDates = data.keys.toList()
                          ..sort((a, b) => _isLatestFirst
                              ? b.compareTo(a)  // 최신순
                              : a.compareTo(b)); // 오래된순

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(width: 20),
                              ...sortedDates.expand((date) {
                                List<dynamic> meetings = data[date];
                                return meetings.map((meetingTitle) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.asset(
                                          getImageForMeeting(meetingTitle),
                                          width: 200,
                                          height: 200,
                                        ),
                                        Text(meetingTitle),
                                        Text(date, style: commonTextStyle),
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
