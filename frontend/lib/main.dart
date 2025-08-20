import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screens/home_screen.dart';
import 'screens/folder_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


// ngrok 무료 플랜 SSL 인증서 무시 설정
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// 로컬 푸시 알림 플러그인 전역 선언
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load(fileName: ".env");

  // Android 초기화
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS 초기화
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // 통합 초기화 설정
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  // 플러그인 초기화
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // TODO: 알림 클릭 시 네비게이션 처리
    },
  );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tino',
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
      theme: ThemeData(
        dialogTheme: DialogThemeData( // 여기 수정
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
  late final WebSocketChannel _wsChannel;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    FolderScreen(),
    ScheduleScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {


    super.initState();

    final notificationUrl = dotenv.env['NOTIFICATION_WEBSOCKET_URL'];

    // WebSocket 연결
    _wsChannel = IOWebSocketChannel.connect(
      notificationUrl!,
    );
    _wsChannel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'pdf_complete') {
        flutterLocalNotificationsPlugin.show(
          1,
          '회의 분석 완료 🎉',
          '결과를 확인하세요.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'pdf_channel', 'PDF 알림',
              channelDescription: '요약 PDF 생성 완료 알림',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _wsChannel.sink.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
