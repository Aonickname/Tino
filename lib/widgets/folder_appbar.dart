import 'package:flutter/material.dart';
import '../style.dart';
import '../screens/folder_screen.dart';

class FolderAppbar extends StatelessWidget {
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
                print("all");
              },
              style: commonButtonStyle,
              child: Row(
                children: [
                  SizedBox(width: 4.0),
                  Text("All", style: commonTextStyle),
                ],
              ),
            ),

            SizedBox(width: 8.0),
            OutlinedButton(
              onPressed: () {
                print("interest");
              },
              style: commonButtonStyle,
              child: Row(
                children: [
                  SizedBox(width: 4.0),
                  Text("관심 있는 회의", style: commonTextStyle),
                ],
              ),
            ),
            SizedBox(width: 8.0),

            OutlinedButton(
              onPressed: () {
                print("ing");
              },
              style: commonButtonStyle,
              child: Row(
                children: [
                  SizedBox(width: 4.0),
                  Text("진행 중인 회의", style: commonTextStyle),
                ],
              ),
            ),
            SizedBox(width: 8.0),

            OutlinedButton(
              onPressed: () {
                print("done");
              },
              style: commonButtonStyle,
              child: Row(
                children: [
                  SizedBox(width: 4.0),
                  Text("종료된 회의", style: commonTextStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
