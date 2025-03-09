import 'package:flutter/material.dart';
import '../style.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert';  //JSON 파싱
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      scrollBehavior: MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
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



        body: Container(

          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                HomeAppBarWidget(),

                SizedBox(height: 16.0),

                Container(
                  height: 200,
                  padding: EdgeInsets.symmetric(horizontal: 16),// 배너 높이 설정
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게 설정
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
                            count: 3, // 배너 개수
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
                                        CustomDialogs.showInputDialogNewMeeting(context, (name, description) {
                                          print("회의 이름: $name");
                                          print("회의 설명: $description");
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Image.asset("assets/images/new_meeting.jpg", width: 150, height: 150,),
                                          Text('새로운 회의', style: commonTextStyle,)
                                        ],
                                      )

                                  ),
                                ],

                              )
                          ),

                          SizedBox(width: 20),
                          Container(
                              child: Column(
                                children: [
                                  InkWell(
                                      onTap: () {
                                        CustomDialogs.showInputDialogUpload(context, (name, description) {
                                          print("회의 이름: $name");
                                          print("회의 설명: $description");
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Image.asset("assets/images/mp3_upload.jpg", width: 150, height: 150,),
                                          Text('녹음 업로드', style: commonTextStyle,)
                                        ],
                                      )

                                  ),
                                ],

                              )
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

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(width: 20),
                            Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image(
                                      image: AssetImage("assets/images/question_tino.jpg"),
                                      width: 200,
                                      height: 200,
                                    ),
                                    Text("종합설계기획"),
                                    Text("새로운 회의", style: commonTextStyle,),
                                  ],
                                )
                            ),

                            Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image(
                                      image: AssetImage("assets/images/search_tino.jpg"),
                                      width: 200,
                                      height: 200,
                                    ),
                                    Text("티노 사용 방법"),
                                    Text("회의 기록하기", style: commonTextStyle,),
                                  ],
                                )
                            ),

                            Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image(
                                      image: AssetImage("assets/images/user1.jpg"),
                                      width: 200,
                                      height: 200,
                                    ),
                                    Text("Test2"),
                                    Text("Test", style: commonTextStyle,),
                                  ],
                                )
                            ),

                            SizedBox(width: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),

          ),
        ),






      ),
    );
  }
}

