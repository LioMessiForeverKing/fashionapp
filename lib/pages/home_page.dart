import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'inspiration_feed_page.dart';
import 'closet_page.dart';
import 'upload_page.dart';
import 'ai_fairy_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const InspirationFeedPage(),
    const ClosetPage(),
    const UploadPage(),
    const AIFairyPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppConstants.neutralWhite,
          boxShadow: AppConstants.softShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.auto_awesome, 'Inspo'),
                _buildNavItem(1, Icons.checkroom, 'Closet'),
                _buildNavItem(2, Icons.camera_alt, 'Upload'),
                _buildNavItem(3, Icons.auto_awesome, 'Fairy'),
                _buildNavItem(4, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppConstants.textDark
                  : AppConstants.textDark.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppConstants.textDark
                    : AppConstants.textDark.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
