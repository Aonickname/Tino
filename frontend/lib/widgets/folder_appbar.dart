import 'package:flutter/material.dart';

class FolderAppbar extends StatefulWidget {
  final ValueChanged<int> onIndexChanged;

  FolderAppbar({required this.onIndexChanged});

  @override
  _FolderAppbarState createState() => _FolderAppbarState();
}

class _FolderAppbarState extends State<FolderAppbar> {
  int selectedIndex = 0;

  final List<String> buttonLabels = [
    "All",
    "관심 있는 회의",
    "진행 중인 회의",
    "종료된 회의"
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(buttonLabels.length, (index) {
          bool isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onIndexChanged(index); // index 전달
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  isSelected ? Colors.black : Colors.transparent,
                ),
                foregroundColor: MaterialStateProperty.all(
                  isSelected ? Colors.white : Colors.black,
                ),
                side: MaterialStateProperty.all(
                  BorderSide(color: Colors.black),
                ),
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
              child: Text(
                buttonLabels[index],
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          );
        }),
      ),
    );
  }
}
