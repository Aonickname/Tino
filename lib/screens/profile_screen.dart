import 'package:flutter/material.dart';
import '../style.dart';


class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,


      appBar: AppBar(
        backgroundColor: Colors.white,
        // title: Text(
        //   '이름',
        //   style: TextStyle(
        //     fontWeight: FontWeight.bold,
        //     fontSize: 20,
        //   ),
        // ),
        
        title: Column(
          children: [
            Text('이름'),
            Text('email@tukorea.ac.kr')
          ],
        ),
      ),


      body: Center(
        child: Text(
          '프로필',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
