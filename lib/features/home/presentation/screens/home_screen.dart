import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SafePlate')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.teal),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '환영합니다!',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_box_outlined),
              title: const Text('프로필 관리'),
              onTap: () {
                context.pop(); // Close drawer
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                context.pop(); // Close drawer
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Google Map Placeholder
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '구글 맵 (준비 중)',
                    style: TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                  Text(
                    '(지도 기능을 사용하려면 API 키가 필요합니다)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Floating Info Card (Bottom Sheet style)
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '식당 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('지도에서 위치를 선택하여 정보를 확인하세요.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement action
                      },
                      child: const Text('주변 검색'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
