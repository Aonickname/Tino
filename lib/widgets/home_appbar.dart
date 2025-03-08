import 'package:flutter/material.dart';
import '../style.dart';
import '../screens/folder_screen.dart';

class HomeAppBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 8.0),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderScreen()),
                );
              },
              style: commonButtonStyle,
              child: Row(
                children: [
                  Icon(Icons.favorite_outline, color: Colors.black),
                  SizedBox(width: 4.0),
                  Text("관심 있는 회의", style: commonTextStyle),
                ],
              ),
            ),

            SizedBox(width: 8.0),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderScreen()),
                );
              },
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderScreen()),
                );
              },
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
          ],
        ),
      ),
    );
  }
}
