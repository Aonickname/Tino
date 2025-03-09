import 'package:flutter/material.dart';
import '../widgets/folder_appbar.dart';

class FolderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('최근 회의 내역',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold)
          ),
        backgroundColor: Colors.white,
      ),


      body: Container(

      child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
          children: [
          FolderAppbar(),
          ]
      )
      )
      )
    );
  }
}
