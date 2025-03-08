import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class CustomDialogs {
  // 기본 다이얼로그
  static void showBasicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("알림"),
          content: Text("이것은 기본적인 다이얼로그입니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("닫기"),
            ),
          ],
        );
      },
    );
  }

  // 확인 / 취소 다이얼로그
  static void showInputDialogUpload(BuildContext context,
      Function(String, String) onSubmit) {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black87),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 테두리 둥글게
          ),
          title: Text("새로운 회의"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 다이얼로그 크기 자동 조절
            children: [
              // 회의 이름 입력 필드 (X 버튼 추가)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "새로운 회의(이름)",

                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)
                  ),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),

                  suffixIcon: nameController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      nameController.clear();
                    },
                  )
                      : null,
                ),
                onChanged: (text) {
                  // X 버튼 업데이트를 위해 다이얼로그 다시 빌드
                  (context as Element).markNeedsBuild();
                },
              ),
              SizedBox(height: 10),

              // 회의 설명 입력 필드 (X 버튼 추가)
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "회의 설명",

                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)
                  ),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),

                  suffixIcon: descriptionController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      descriptionController.clear();
                    },
                  )
                      : null,
                ),
                onChanged: (text) {
                  // X 버튼 업데이트를 위해 다이얼로그 다시 빌드
                  (context as Element).markNeedsBuild();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                onSubmit(nameController.text, descriptionController.text);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  static void showInputDialogNewMeeting(BuildContext context,
      Function(String, String) onSubmit) {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black87),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 테두리 둥글게
          ),
          title: Text("새로운 회의"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 다이얼로그 크기 자동 조절
            children: [
              // 회의 이름 입력 필드 (X 버튼 추가)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "새로운 회의(이름)",

                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black)
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)
                  ),

                  suffixIcon: nameController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      nameController.clear();
                    },
                  )
                      : null,
                ),
                onChanged: (text) {
                  // X 버튼 업데이트를 위해 다이얼로그 다시 빌드
                  (context as Element).markNeedsBuild();
                },
              ),
              SizedBox(height: 10),

              // 회의 설명 입력 필드 (X 버튼 추가)
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "회의 설명",

                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)
                  ),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)
                  ),

                  suffixIcon: descriptionController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      descriptionController.clear();
                    },
                  )
                      : null,
                ),
                onChanged: (text) {
                  // X 버튼 업데이트를 위해 다이얼로그 다시 빌드
                  (context as Element).markNeedsBuild();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                onSubmit(nameController.text, descriptionController.text);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

}