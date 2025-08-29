// main.dart 파일
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tino/screens/login_screen.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screens/home_screen.dart';
import 'screens/folder_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tino/providers/user_provider.dart';
import 'package:provider/provider.dart';


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

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // UserProvider를 앱 전체에 제공
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // UserProvider에서 사용자 정보를 가져옵니다.
    final userProvider = Provider.of<UserProvider>(context);

    // 로그인 상태에 따라 다른 화면을 보여줍니다.
    return MaterialApp(
      title: 'Tino',
      debugShowCheckedModeBanner: false,
      home: userProvider.username != null ? MainScreen() : const LoginScreen(),
      theme: ThemeData(
        dialogTheme: const DialogThemeData(
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
    _setupNotifications(); // 알림 관련 로직을 하나의 함수로 호출
  }

  // 알림 및 웹소켓 관련 코드
  void _setupNotifications() {
    // iOS 알림 권한 요청
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final notificationUrl = dotenv.env['NOTIFICATION_WEBSOCKET_URL'];

    if (notificationUrl == null || notificationUrl.isEmpty) {
      print('오류: NOTIFICATION_WEBSOCKET_URL이 설정되지 않았습니다.');
      return;
    }

    try {
      // WebSocket 연결
      _wsChannel = IOWebSocketChannel.connect(
        Uri.parse(notificationUrl),
        customClient: HttpClient()
          ..badCertificateCallback = (X509Certificate cert, String host, int port) => true,
      );

      print('WebSocket 연결 시도: $notificationUrl');

      // 웹소켓 메시지 수신 리스너
      _wsChannel.stream.listen(
            (message) {
          print('웹소켓 알림 수신: $message');
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
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
            );
          }
        },
        onDone: () {
          print('웹소켓 연결 종료');
        },
        onError: (error) {
          print('웹소켓 오류 발생: $error');
        },
      );
    } catch (e) {
      print('웹소켓 연결 실패: $e');
    }
  }

  @override
  void dispose() {
    // 앱 종료 시 웹소켓 연결을 닫습니다.
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