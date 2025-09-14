import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

// CustomDialogs: 앱 내에서 재사용 가능한 입력 다이얼로그를 정의하는 클래스
class CustomDialogs {
  /// 오디오 파일 업로드 및 요약 옵션 입력용 다이얼로그
  static void showInputDialogUpload(
      BuildContext context,
      Function(String name, String description, File? file, DateTime date, String summaryMode, String customPrompt) onSubmit
      ) {
    // 텍스트 입력 컨트롤러
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController customSummaryController = TextEditingController();

    // 드롭다운 초기값 및 선택 파일, 날짜
    String selectedOption = '기본 회의록 방식으로 요약';
    File? selectedFile;
    DateTime? selectedDate;

    // 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) {
        // 내부 상태 갱신을 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("새로운 회의"),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // 다이얼로그 높이 제한 (화면의 60%)
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 회의 이름 입력 필드
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "새로운 회의(이름)",
                          suffixIcon: nameController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              nameController.clear();
                              setState(() {});  // 텍스트 삭제 후 UI 갱신
                            },
                          )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 10),

                      // 회의 설명 입력 필드
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
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: 10),

                    ListTile(
                      title: Text(
                        selectedDate == null
                            ? '날짜를 선택하세요'
                            : DateFormat('yyyy-MM-dd').format(selectedDate!),
                        style: TextStyle(color: Colors.black87),
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        // 날짜 선택기 표시 (배경 흰색 커스터마이징)
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          builder: (BuildContext ctx, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                dialogBackgroundColor: Colors.white,
                                colorScheme: ColorScheme.light(
                                  primary: Colors.blue,    // 헤더 배경
                                  onPrimary: Colors.white, // 헤더 텍스트
                                  surface: Colors.white,   // 달력 표면
                                  onSurface: Colors.black, // 날짜 글자
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 10),

                      // MP3 파일 선택 버튼
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
                          // FilePicker로 mp3 파일 선택
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

                      // 선택된 파일 이름 표시
                      if (selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            "선택된 파일: ${selectedFile!.path.split('/').last}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),

                      // 요약 방식 드롭다운
                      DropdownButton<String>(
                        value: selectedOption,
                        dropdownColor: Colors.white,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedOption = newValue!;
                          });
                        },
                        items: [
                          '기본 회의록 방식으로 요약',
                          '사용자 지정 요약'
                        ].map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),

                      // 사용자 지정 요약 입력 필드 (조건부 표시)
                      if (selectedOption == '사용자 지정 요약')
                        TextField(
                          controller: customSummaryController,
                          decoration: InputDecoration(hintText: "요약 프롬프트 입력"),
                        ),
                    ],
                  ),
                ),
              ),

              // 다이얼로그 하단 액션 버튼
              actions: [
                // 취소 버튼
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: Text("취소"),
                ),
                // 확인 버튼: 필수 입력 체크 후 onSubmit 호출
                ElevatedButton(
                  onPressed: () {
                    if (selectedDate != null) {
                      onSubmit(
                        nameController.text,
                        descriptionController.text,
                        selectedFile,
                        selectedDate!,
                        selectedOption,
                        customSummaryController.text,
                      );
                      Navigator.pop(context);
                    } else {
                      // 날짜 미선택 시 알림
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

  /// 새 회의 기본 입력용 다이얼로그 (이름, 설명, 날짜)
  static void showInputDialogNewMeeting(
      BuildContext context,
      Function(String name, String description, DateTime date) onSubmit
      ) {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black87),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text("새로운 회의"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 회의 이름 입력
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "새로운 회의(이름)",
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  suffixIcon: nameController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => nameController.clear(),
                  )
                      : null,
                ),
              ),
              SizedBox(height: 10),

              // 회의 설명 입력
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "회의 설명",
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  suffixIcon: descriptionController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => descriptionController.clear(),
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
                      : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  style: TextStyle(color: Colors.black87),
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    builder: (BuildContext ctx, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          dialogBackgroundColor: Colors.white,
                          colorScheme: ColorScheme.light(
                            primary: Colors.blue,    // 헤더 배경
                            onPrimary: Colors.white, // 헤더 텍스트
                            surface: Colors.white,   // 달력 표면
                            onSurface: Colors.black, // 날짜 글자
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null && pickedDate != selectedDate) {
                    selectedDate = pickedDate;
                    (context as Element).markNeedsBuild();  // UI 업데이트 호출
                  }
                },
              ),
            ],
          ),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: Text("취소"),
            ),
            // 확인 버튼: 날짜 선택 확인 후 onSubmit 호출
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
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  static void showInputDialogEdit(
      BuildContext context,
      String originalName, // 기존 회의 이름
      String originalDescription, // 기존 회의 설명
      String directory, // 고유한 폴더 이름
      Function(String name, String description, DateTime date, String directory) onSubmit
      ) {
    TextEditingController nameController = TextEditingController(text: originalName);
    TextEditingController descriptionController = TextEditingController(text: originalDescription);
    DateTime? selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: Colors.black87),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text("회의 내용 수정"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 회의 이름 입력
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "회의 제목(이름)",
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  suffixIcon: nameController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => nameController.clear(),
                  )
                      : null,
                ),
              ),
              SizedBox(height: 10),

              // 회의 설명 입력
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "회의 설명",
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  suffixIcon: descriptionController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => descriptionController.clear(),
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
                      : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  style: TextStyle(color: Colors.black87),
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    builder: (BuildContext ctx, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          dialogBackgroundColor: Colors.white,
                          colorScheme: ColorScheme.light(
                            primary: Colors.blue,    // 헤더 배경
                            onPrimary: Colors.white, // 헤더 텍스트
                            surface: Colors.white,   // 달력 표면
                            onSurface: Colors.black, // 날짜 글자
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null && pickedDate != selectedDate) {
                    selectedDate = pickedDate;
                    (context as Element).markNeedsBuild();  // UI 업데이트 호출
                  }
                },
              ),
            ],
          ),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: Text("취소"),
            ),
            // 확인 버튼: 날짜 선택 확인 후 onSubmit 호출
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null) {
                  onSubmit(
                    nameController.text,
                    descriptionController.text,
                    selectedDate!,
                    directory,
                  );
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  // static void showInputDialogSummary(
  //     BuildContext context,
  //     Function(String summaryMode, String customPrompt) onSubmit
  //     ) {
  //   TextEditingController customSummaryController = TextEditingController();
  //   String selectedOption = '기본 회의록 방식으로 요약';
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: Text("회의 요약 방식 선택"),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   // 요약 방식 드롭다운
  //                   DropdownButton<String>(
  //                     value: selectedOption,
  //                     dropdownColor: Colors.white,
  //                     onChanged: (String? newValue) {
  //                       setState(() {
  //                         selectedOption = newValue!;
  //                       });
  //                     },
  //                     items: [
  //                       '기본 회의록 방식으로 요약',
  //                       '사용자 지정 요약'
  //                     ].map((value) {
  //                       return DropdownMenuItem(
  //                         value: value,
  //                         child: Text(value),
  //                       );
  //                     }).toList(),
  //                   ),
  //
  //                   // 사용자 지정 요약 입력 필드 (조건부 표시)
  //                   if (selectedOption == '사용자 지정 요약')
  //                     TextField(
  //                       controller: customSummaryController,
  //                       decoration: InputDecoration(hintText: "요약 프롬프트 입력"),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 style: TextButton.styleFrom(foregroundColor: Colors.black),
  //                 child: Text("취소"),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   String mode = selectedOption == '기본 회의록 방식으로 요약' ? "기본" : "사용자 지정";
  //                   onSubmit(mode, customSummaryController.text);
  //                   Navigator.pop(context);
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.white,
  //                   foregroundColor: Colors.black,
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  //                 ),
  //                 child: Text("확인"),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

// dialog.dart 파일 내
  static Future<bool?> showInputDialogSummary(
      BuildContext context,
      Function(String summaryMode, String customPrompt) onSubmit
      ) {
    TextEditingController customSummaryController = TextEditingController();
    String selectedOption = '기본 회의록 방식으로 요약';

    return showDialog( // ⭐️ return을 추가해 showDialog의 결과를 반환합니다.
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("회의 요약 방식 선택"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 요약 방식 드롭다운
                    DropdownButton<String>(
                      value: selectedOption,
                      dropdownColor: Colors.white,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedOption = newValue!;
                        });
                      },
                      items: [
                        '기본 회의록 방식으로 요약',
                        '사용자 지정 요약'
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),

                    // 사용자 지정 요약 입력 필드 (조건부 표시)
                    if (selectedOption == '사용자 지정 요약')
                      TextField(
                        controller: customSummaryController,
                        decoration: InputDecoration(hintText: "요약 프롬프트 입력"),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false), // ⭐️ 취소 버튼도 false를 반환하도록 수정
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: Text("취소"),
                ),
                ElevatedButton(
                  onPressed: () {
                    String mode = selectedOption == '기본 회의록 방식으로 요약' ? "기본" : "사용자 지정";
                    onSubmit(mode, customSummaryController.text);
                    // '확인' 버튼을 누르면 true를 반환
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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



}
