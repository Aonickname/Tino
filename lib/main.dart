import 'package:flutter/material.dart';
import 'style.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
        IconButton(onPressed: () {}, icon: Icon(Icons.search)),
        IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none)),
      ],
      ),



    body: Container(

      child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Container(
              child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                SizedBox(width: 8.0),
                  OutlinedButton(onPressed: () {},
                  style: commonButtonStyle,
                    child: Row(
                      children: [
                      Icon(Icons.favorite, color: Colors.black),
                      SizedBox(width: 4.0),
                      Text("관심 있는 회의", style: commonTextStyle),
                      ],
                    ),
                ),
                    SizedBox(width: 8.0),
                    OutlinedButton(
                      onPressed: () {},
                      style: commonButtonStyle,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.black),
                          SizedBox(width: 4.0),
                          Text("최근 회의 내역", style: commonTextStyle),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.0),
                    OutlinedButton(
                      onPressed: () {},
                      style: commonButtonStyle,
                      child: Row(
                        children: [
                          Icon(Icons.download, color: Colors.black),
                          SizedBox(width: 4.0),
                          Text("회의록 다운로드", style: commonTextStyle),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.0),
                    OutlinedButton(
                      onPressed: () {},
                      style: commonButtonStyle,
                      child: Row(
                        children: [
                          Icon(Icons.download, color: Colors.black),
                          SizedBox(width: 4.0),
                          Text("Test", style: commonTextStyle),
                        ],
                      ),
                    ),
                  ],

                ),

              ),
            ),

            SizedBox(height: 16.0),

            Container(
              child: Column(
                children: [
                  Image(
                      image: AssetImage("assets/images/banner.jpg"),
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
                                    print("새로운 회의 버튼 클릭");
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
                                    print("녹음 업로드 버튼 클릭");
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
                              Text("깃허브 테스트", style: commonTextStyle,),
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



    bottomNavigationBar: BottomNavigationBar(
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,

      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈',),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: '폴더',),
        BottomNavigationBarItem(icon: Icon(Icons.date_range), label: '검색',),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필',
        ),
      ],
    ),


      ),
    );
  }
}

