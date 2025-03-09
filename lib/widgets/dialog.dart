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
      Function(String, String, DateTime) onSubmit) {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle:
          TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black87),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text("새로운 회의"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 회의 이름 입력 필드
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "새로운 회의(이름)",
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  suffixIcon: nameController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      nameController.clear();
                    },
                  )
                      : null,
                ),
              ),
              SizedBox(height: 10),

              // 회의 설명 입력 필드
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "회의 설명",
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  suffixIcon: descriptionController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      descriptionController.clear();
                    },
                  )
                      : null,
                ),
              ),
              SizedBox(height: 10),

              // 날짜 선택 필드
              ListTile(
                title: Text(
                  selectedDate == null
                      ? '날짜를 선택하세요'
                      : '${DateFormat('yyyy-MM-dd').format(selectedDate!)}', // 날짜 포맷 변경
                  style: TextStyle(color: Colors.black87),
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != selectedDate) {
                    selectedDate = pickedDate;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null) {
                  onSubmit(nameController.text, descriptionController.text, selectedDate!);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("날짜를 선택해주세요")),
                  );
                }
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }



}