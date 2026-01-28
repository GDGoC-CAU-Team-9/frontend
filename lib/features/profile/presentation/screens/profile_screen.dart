import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_design.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '프로필 관리',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: Colors.black87,
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildMenuCard(
                context,
                title: '알레르기',
                description: '자신의 알레르기 정보를 설정합니다.',
                icon: Icons.check_box_outlined,
                onTap: () => context.push('/profile/allergy'),
                isActive: true,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: '종교',
                description: '종교적 식이 제한을 설정합니다. (준비 중)',
                icon: Icons.temple_buddhist_outlined,
                onTap: () {},
                isActive: false,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: '비건',
                description: '채식 단계를 설정합니다. (준비 중)',
                icon: Icons.grass,
                onTap: () {},
                isActive: false,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: '질병',
                description: '질병에 따른 식이 제한을 설정합니다. (준비 중)',
                icon: Icons.local_hospital_outlined,
                onTap: () {},
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Container(
      decoration: AppDesign.glassDecoration, // Use glass decoration
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isActive
                      ? Colors.teal.withOpacity(0.1)
                      : Colors.grey.shade200,
                  child: Icon(
                    icon,
                    color: isActive ? Colors.teal : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive
                              ? Colors.black54
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.teal,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
