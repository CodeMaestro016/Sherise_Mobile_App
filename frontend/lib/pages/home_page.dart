import 'package:flutter/material.dart';
import '../models/app_colors.dart';

class HomePage extends StatelessWidget {
  final void Function(int index) onNavigate;
  final Map<String, dynamic>? currentUser;
  const HomePage(
      {super.key, required this.onNavigate, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                  colors: [Color(0xFFA600D8), Color(0xFF8B5DDC)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${currentUser?['name'] ?? 'SheRise User'}',
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get Start!',
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              HomeQuickCard(
                  title: 'SOS Alert',
                  icon: Icons.sos,
                  color: AppColors.homeCardPink,
                  onTap: () => onNavigate(1)),
              HomeQuickCard(
                  title: 'Courses',
                  icon: Icons.cast_for_education_outlined,
                  color: AppColors.homeCardPurple,
                  onTap: () => onNavigate(2)),
              HomeQuickCard(
                  title: 'Community',
                  icon: Icons.groups_outlined,
                  color: AppColors.homeCardLilac,
                  onTap: () => onNavigate(3)),
              HomeQuickCard(
                  title: 'Legal Help',
                  icon: Icons.balance_outlined,
                  color: AppColors.homeCardMint,
                  onTap: () => onNavigate(4)),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeQuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HomeQuickCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(24)),
              child: Center(child: Icon(icon, size: 72, color: Colors.black54)),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
