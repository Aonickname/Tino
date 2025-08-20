import 'package:flutter/material.dart';
import '../style.dart';
import '../screens/folder_screen.dart';

class HomeAppBarWidget extends StatelessWidget {
  final List<Map<String, dynamic>> buttons = [
    {
      "icon": Icons.star_outline,
      "text": "관심 있는 회의",
    },
    {
      "icon": Icons.schedule,
      "text": "최근 회의 내역",
    },
    {
      "icon": Icons.download,
      "text": "회의록 다운로드",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(buttons.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderScreen()),
                );
              },
              style: commonButtonStyle,
              child: Row(
                children: [
                  Icon(buttons[index]["icon"], color: Colors.black),
                  SizedBox(width: 4.0),
                  Text(buttons[index]["text"], style: commonTextStyle),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
