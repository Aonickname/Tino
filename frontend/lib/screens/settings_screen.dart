import 'package:flutter/material.dart';
import 'package:tino/screens/home_screen.dart';
import 'settings/profile_info.dart';
import 'settings/device_setting.dart';
import 'settings/group_setting.dart';
import 'settings/test_view.dart';
import 'package:tino/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:tino/providers/user_provider.dart';


class SettingScreen extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final username = userProvider.username ?? '이름 없음'; // 사용자 이름이 없으면 '이름 없음'
    final email = userProvider.email ?? '이메일 없음'; // 이메일이 없으면 '이메일 없음'

    return Scaffold(
      backgroundColor: Colors.white,

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 프로필 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    Text(
                      username + " 님",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    print("로그아웃 완료");
                    userProvider.clearUser();

                    // 2. 로그인 화면으로 이동
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 테두리 둥글기 설정
                    ),
                  ),
                  child: Text('로그아웃'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 내 정보
            _buildSectionTitle('내 정보'),
            _buildListItem('프로필 정보', context, profile_info()),
            _buildListItem('계정 정보', context, account_info()),
            SizedBox(height: 30),

            // 그룹 설정
            _buildSectionTitle('그룹 설정'),
            _buildListItem('속한 그룹 보기', context, view_group()),
            _buildListItem('그룹 생성', context, create_group()),
            _buildListItem('그룹 초대', context, invite_group()),
            SizedBox(height: 30),

            // 기기 설정
            _buildSectionTitle('기기 설정'),
            _buildListItem('연결 기기', context, connecting_device()),
            _buildListItem('화면 설정', context, screen_setting()),
            _buildListItem('음성 데이터 저장 관리', context, voicedata()),

            SizedBox(height: 30),

            //테스트화면
            _buildSectionTitle('테스트 화면'),
            ElevatedButton(
              child: Text("azure api 실시간 전사"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AzureSTTPage(
                    ),
                  ),
                );
              },
            ),



          ],
        ),
      ),
    );
  }



  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildListItem(String title, BuildContext context, Widget? nextScreen) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: TextStyle(fontSize: 16)),
          onTap: nextScreen != null
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => nextScreen),
            );
          }
              : null,
        ),
        Divider(height: 1),
      ],
    );
  }
}
