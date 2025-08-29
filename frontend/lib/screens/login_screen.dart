import 'package:flutter/material.dart';
import 'package:tino/main.dart';
import 'package:tino/screens/signup_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:tino/providers/user_provider.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {

  bool _rememberMeChecked = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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

  Future<void> _login() async {
    final url = Uri.parse('http://0.0.0.0:8000/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }),
    );

  //   if (response.statusCode == 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('로그인 성공!'));
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => MainScreen()),
  //     );
  //   } else {
  //     final errorData = jsonDecode(utf8.decode(response.bodyBytes));
  //     final errorMessage = errorData['detail'];
  //     ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('로그인 실패: $errorMessage', isSuccess: false));
  //   }
  // }

    if (response.statusCode == 200) {
      final userData = jsonDecode(utf8.decode(response.bodyBytes));
      print('Server Response: $userData');

      // userData에서 username과 email이 없으면 null을 반환하도록 합니다.
      final username = userData['username'];
      final email = userData['email'];

      // null 값인지 확인하고, 만약 null이면 오류 처리
      if (username == null || email == null) {
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('서버 응답에 사용자 정보가 누락되었습니다.', isSuccess: false));
        return;
      }

      // 1. UserProvider에 사용자 정보를 저장합니다.
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(username, email);

      // 2. 로그인 성공 스낵바를 표시합니다.
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('로그인 성공!'));

      // 3. MainScreen으로 이동합니다.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMessage = errorData['detail'];
      ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('로그인 실패: $errorMessage', isSuccess: false));
    }
  }

  Widget _buildTextField(String labelText, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
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
              const Text(
                'Log In',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField('Username', _usernameController),
              const SizedBox(height: 15),
              _buildTextField('Password', _passwordController, isPassword: true),
              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMeChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _rememberMeChecked = value ?? false;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const Text('아이디 저장'),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 5,
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have on account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      '회원가입',
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