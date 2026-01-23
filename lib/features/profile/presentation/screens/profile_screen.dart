import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 관리')),
      body: ListView(
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.shade200,
                child: Icon(
                  icon,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
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
                        color: isActive ? Colors.black54 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
