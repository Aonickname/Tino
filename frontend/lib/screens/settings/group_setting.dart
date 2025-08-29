import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tino/service/api_services.dart';
import 'package:provider/provider.dart';
import 'package:tino/providers/user_provider.dart';

class SettingGroupScreen extends StatefulWidget {
  @override
  _SettingGroupScreenState createState() => _SettingGroupScreenState();
}

class _SettingGroupScreenState extends State<SettingGroupScreen> {
  late Future<List<dynamic>> _groupsFuture;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadAndFetchGroups();
  }

  Future<void> _loadAndFetchGroups() async {
    _currentUsername = Provider.of<UserProvider>(context, listen: false).username;

    if (_currentUsername != null) {
      setState(() {
        _groupsFuture = ApiService().fetchUserGroups(_currentUsername!);
      });
    } else {
      setState(() {
        _groupsFuture = Future.error('로그인이 필요합니다.');
      });
    }
  }

  void _deleteGroup(int groupId) async {
    try {
      await ApiService().deleteGroup(groupId);
      _loadAndFetchGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 삭제 실패: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '그룹 관리',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '내 그룹 목록',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _groupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('오류 발생: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final groups = snapshot.data!;
                    return ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            title: Text(
                              group['name'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              group['description'] ?? '설명 없음',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('그룹 삭제'),
                                      content: Text('${group['name']} 그룹을 정말로 삭제하시겠습니까?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('취소'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          child: Text('삭제', style: TextStyle(color: Colors.white)),
                                          onPressed: () {
                                            _deleteGroup(group['id']);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('소속된 그룹이 없습니다.'));
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateGroupScreen()),
                );
                _loadAndFetchGroups();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '새 그룹 만들기',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class CreateGroupScreen extends StatefulWidget {
//   @override
//   _CreateGroupScreenState createState() => _CreateGroupScreenState();
// }
//
// class _CreateGroupScreenState extends State<CreateGroupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('새 그룹 만들기'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(labelText: '그룹 이름'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return '그룹 이름을 입력해주세요.';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: InputDecoration(labelText: '그룹 설명 (선택)'),
//                 maxLines: 3,
//               ),
//               SizedBox(height: 32),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     _createGroup(_nameController.text, _descriptionController.text);
//                   }
//                 },
//                 child: Text('생성하기'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _createGroup(String name, String description) async {
//     final username = Provider.of<UserProvider>(context, listen: false).username;
//     if (username == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.')),
//       );
//       return;
//     }
//     try {
//       await ApiService().createGroup(name, description, username);
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('그룹이 성공적으로 생성되었습니다!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('그룹 생성 실패: ${e.toString()}')),
//       );
//     }
//   }
// }

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 흰색으로 변경
      appBar: AppBar(
        title: Text('새 그룹 만들기'),
        backgroundColor: Colors.white,
        elevation: 0, // AppBar 아래 그림자 제거
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '그룹 이름',
                  filled: true,
                  fillColor: Colors.grey[200], // 연한 회색 배경
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                    borderSide: BorderSide.none, // 테두리 선 없애기
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0), // 포커스 시 파란색 테두리
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '그룹 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '그룹 설명 (선택)',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _createGroup(_nameController.text, _descriptionController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // 배경색을 파란색으로 변경
                  foregroundColor: Colors.white, // 텍스트 색상을 흰색으로 변경
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16), // 위아래 여백으로 버튼 높이 조절
                ),
                child: Text('생성하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createGroup(String name, String description) async {
    final username = Provider.of<UserProvider>(context, listen: false).username;
    if (username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }
    try {
      await ApiService().createGroup(name, description, username);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹이 성공적으로 생성되었습니다!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 생성 실패: ${e.toString()}')),
      );
    }
  }
}

class invite_group extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Flutter Text Example')),
        body: Center(
          child: Text(
            'invite_group_test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}