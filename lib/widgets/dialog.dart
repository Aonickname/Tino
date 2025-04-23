import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class CustomDialogs {
  static void showInputDialogUpload(
      BuildContext context, Function(String, String, File?, DateTime) onSubmit) {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    File? selectedFile;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("새로운 회의"),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "새로운 회의(이름)",
                            suffixIcon: nameController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                nameController.clear();
                                setState(() {});
                              },
                            )
                                : null,
                          ),
                          onChanged: (text) => setState(() {}),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            hintText: "회의 설명",
                            suffixIcon: descriptionController.text.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                descriptionController.clear();
                                setState(() {});
                              },
                            )
                                : null,
                          ),
                          onChanged: (text) => setState(() {}),
                        ),
                        SizedBox(height: 10),

                        // 날짜 선택 추가
                        ListTile(
                          title: Text(
                            selectedDate == null
                                ? '날짜를 선택하세요'
                                : '${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
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
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),

                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: Icon(Icons.audiotrack, color: Colors.black),
                          label: Text("mp3 파일 선택", style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey),
                            ),
                          ),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['mp3'],
                            );
                            if (result != null && result.files.single.path != null) {
                              setState(() {
                                selectedFile = File(result.files.single.path!);
                              });
                            }
                          },
                        ),
                        if (selectedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              "선택된 파일: ${selectedFile!.path.split('/').last}",
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: Text("취소"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDate != null) {
                      onSubmit(nameController.text, descriptionController.text, selectedFile, selectedDate!);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("날짜를 선택해주세요")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text("확인"),
                ),
              ],
            );
          },
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black, // 글자 색
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }



}