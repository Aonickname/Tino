import 'package:flutter/material.dart';
import 'package:tino/screens/login_screen.dart';
import 'package:http/http.dart' as http; // http 라이브러리를 가져옵니다.
import 'dart:convert'; // JSON 데이터를 다루기 위한 라이브러리
import 'package:flutter_dotenv/flutter_dotenv.dart';


// StatefulWidget으로 변경
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 입력 필드의 값을 제어할 컨트롤러를 선언합니다.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 회원가입 성공/실패 스낵바
  SnackBar _buildSnackBar(String message, {bool isSuccess = true}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
    );
  }

  // 회원가입 API 호출 함수
  Future<void> _signup() async {
    // 1. 비밀번호 일치 여부 확인
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('비밀번호가 일치하지 않습니다.', isSuccess: false));
      return;
    }

    final baseUrl = dotenv.env['DB_BASE_URL'];
    final url = Uri.parse('$baseUrl/api/signup');

    // 2. 서버에 보낼 JSON 데이터 준비
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    // 3. 서버 응답 처리
    if (response.statusCode == 200) {
      // 성공 시
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('회원가입 성공! 로그인 페이지로 이동합니다.'));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // 실패 시
      final errorData = jsonDecode(utf8.decode(response.bodyBytes)); // 지난번에 알려드린 한글 깨짐 방지 코드 포함
      String userFriendlyMessage = '알 수 없는 오류가 발생했습니다.'; // 기본 메시지 설정

      // 에러 메시지에서 'detail' 키를 가져옵니다.
      // 만약 에러 메시지가 리스트 형태로 온다면 첫 번째 요소를 사용
      final detail = errorData['detail'];

      if (detail is List && detail.isNotEmpty) {
        final msg = detail[0]['msg'] as String;
        // 에러 메시지 내용에 따라 사용자 친화적인 메시지로 변경
        if (msg.contains('email')) {
          userFriendlyMessage = '이메일 주소가 올바른 형식이 아닙니다.';
        } else if (msg.contains('username')) {
          userFriendlyMessage = '사용자 이름이 올바르지 않습니다.';
        } else if (msg.contains('password')) {
          userFriendlyMessage = '비밀번호 형식이 올바르지 않습니다.';
        }
      } else if (detail is String) {
        // detail이 문자열인 경우
        userFriendlyMessage = detail;
      }

      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('회원가입 실패: $userFriendlyMessage', isSuccess: false));
    }
  }

  // 입력 필드를 만드는 함수 (코드 중복을 줄여줘요)
  Widget _buildTextField(String labelText, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller, // 컨트롤러 연결
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 'Sign Up' 제목
              const Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // 'Username' 입력 필드
              _buildTextField('Username', _usernameController),
              const SizedBox(height: 15),
              // 'Email' 입력 필드
              _buildTextField('Email', _emailController),
              const SizedBox(height: 15),
              // 'Password' 입력 필드
              _buildTextField('Password', _passwordController, isPassword: true),
              const SizedBox(height: 15),
              // 'Confirm Password' 입력 필드
              _buildTextField('Confirm Password', _confirmPasswordController, isPassword: true),

              const SizedBox(height: 30),
              // 'Sign Up' 버튼
              ElevatedButton(
                onPressed: _signup, // API 호출 함수 연결
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 5,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // 'Log In' 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Allready have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}