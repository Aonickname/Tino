import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/folder_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'dart:io';

// ngrok 무료 플랜 SSL 인증서 무시 설정
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
      theme: ThemeData(
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭

  final List<Widget> _screens = [
    HomeScreen(),
    FolderScreen(),
    ScheduleScreen(),
    SettingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // 선택된 화면 표시
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped, // 클릭 이벤트 전달
      ),
    );
  }
}
