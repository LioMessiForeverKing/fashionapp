import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'inspiration_feed_page.dart';

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
                _buildNavItem(3, Icons.person, 'Profile'),
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
              ? AppConstants.primaryBlue.withOpacity(0.1)
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
                  : AppConstants.textDark.withOpacity(0.6),
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
                    : AppConstants.textDark.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder pages for now

class ClosetPage extends StatelessWidget {
  const ClosetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '👗 My Closet',
          style: TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.neutralWhite,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: const Center(
        child: Text(
          'Your Digital Closet\nComing Soon! 👗',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 18,
            color: AppConstants.textDark,
          ),
        ),
      ),
    );
  }
}

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📷 Add Item',
          style: TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.neutralWhite,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Camera & Upload\nComing Soon! 📷',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 18,
            color: AppConstants.textDark,
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '👤 Profile',
          style: TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.neutralWhite,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Profile & Settings\nComing Soon! 👤',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 18,
            color: AppConstants.textDark,
          ),
        ),
      ),
    );
  }
}
