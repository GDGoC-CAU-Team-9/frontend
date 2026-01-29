import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_design.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        if (mounted) {
          // Navigate to analysis result
          context.push('/analysis-loading', extra: image);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영하기'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택하기'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      appBar: AppBar(
        title: const Text(
          'SafePlate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 24), // Explicit Menu Icon
                color: Colors.black87,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 0, // Remove default shadow for a cleaner look
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.backgroundGradient,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent, // Transparent to show gradient
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authProvider);
                    final user = authState.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.teal.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: Text(
                              user?.email.substring(0, 1).toUpperCase() ?? 'G',
                              style: const TextStyle(
                                fontSize: 30,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? '사용자',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'guest@example.com',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDesign.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Colors.teal,
                        ),
                        title: const Text(
                          '프로필 관리',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/profile');
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDesign.glassDecoration.copyWith(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.4),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        onTap: () {
                          // TODO: Implement Logout Logic
                          Navigator.pop(context);
                          context.go('/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        // Gradient Background
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or Illustration
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.teal.shade300,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '메뉴판을 촬영하여\n안전한 음식을 찾아보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI가 기피 재료를 분석해 드립니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Main Action Button
              ElevatedButton.icon(
                onPressed: () => _showImageSourceActionSheet(context),
                icon: const Icon(Icons.search, size: 28),
                label: const Text(
                  '메뉴판 검사하기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
