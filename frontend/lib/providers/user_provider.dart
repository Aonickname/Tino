import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _username;
  String? _email;

  String? get username => _username;
  String? get email => _email;

  // 로그인 성공 시 호출되어 사용자 정보를 저장합니다.
  void setUser(String username, String email) {
    _username = username;
    _email = email;
    notifyListeners(); // 정보가 바뀌었으니 화면을 업데이트하라고 알려줍니다.
  }

  // 로그아웃 시 호출되어 사용자 정보를 지웁니다.
  void clearUser() {
    _username = null;
    _email = null;
    notifyListeners(); // 정보가 바뀌었으니 화면을 업데이트하라고 알려줍니다.
  }
}