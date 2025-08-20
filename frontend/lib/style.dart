import 'package:flutter/material.dart';

final TextStyle commonTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 16.0,
);

final IconThemeData commonIconStyle = IconThemeData(
  color: Colors.black,
  size: 30.0,
);

final ButtonStyle commonButtonStyle = OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(5.0),
  ),
);

final BottomNavigationBarThemeData bottomNavBarTheme = BottomNavigationBarThemeData(
  backgroundColor: Colors.white, // 배경색
);