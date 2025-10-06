import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../services/user_service.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // User preferences
  final List<String> _selectedStyles = [];
  String? _selectedAgeRange;
  String? _selectedBodyType;
  String? _selectedLifestyle;
  final List<String> _selectedColors = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _styleOptions = [
    {
      'name': 'boho',
      'displayName': 'Boho',
      'emoji': '🌸',
      'description': 'Free-spirited, flowing, earthy',
    },
    {
      'name': 'minimalist',
      'displayName': 'Minimalist',
      'emoji': '🖤',
      'description': 'Clean, simple, timeless',
    },
    {
      'name': 'preppy',
      'displayName': 'Preppy',
      'emoji': '👔',
      'description': 'Classic, polished, traditional',
    },
    {
      'name': 'edgy',
      'displayName': 'Edgy',
      'emoji': '⚡',
      'description': 'Bold, unconventional, daring',
    },
    {
      'name': 'romantic',
      'displayName': 'Romantic',
      'emoji': '🌹',
      'description': 'Feminine, soft, dreamy',
    },
    {
      'name': 'casual',
      'displayName': 'Casual',
      'emoji': '👕',
      'description': 'Comfortable, relaxed, everyday',
    },
  ];

  final List<String> _ageRanges = ['18-24', '25-34', '35-44', '45-54', '55+'];

  final List<String> _bodyTypes = [
    'Pear',
    'Apple',
    'Hourglass',
    'Rectangle',
    'Inverted Triangle',
  ];

  final List<String> _lifestyles = [
    'Student',
    'Professional',
    'Creative',
    'Parent',
    'Entrepreneur',
    'Retired',
  ];

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Navy', 'color': Colors.blue[900]!},
    {'name': 'Gray', 'color': Colors.grey[600]!},
    {'name': 'Red', 'color': Colors.red[600]!},
    {'name': 'Pink', 'color': Colors.pink[400]!},
    {'name': 'Blue', 'color': Colors.blue[500]!},
    {'name': 'Green', 'color': Colors.green[600]!},
    {'name': 'Yellow', 'color': Colors.yellow[600]!},
    {'name': 'Purple', 'color': Colors.purple[500]!},
    {'name': 'Orange', 'color': Colors.orange[500]!},
    {'name': 'Brown', 'color': Colors.brown[600]!},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: AppConstants.animationMedium,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.animationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // Save user preferences to Supabase
      await UserService.createOrUpdateUserProfile(
        stylePreferences: _selectedStyles,
        ageRange: _selectedAgeRange!,
        bodyType: _selectedBodyType!,
        favoriteColors: _selectedColors,
        lifestyle: _selectedLifestyle!,
      );

      // Log the onboarding completion activity
      await UserService.logActivity(
        activityType: 'complete_onboarding',
        activityData: {
          'style_preferences': _selectedStyles,
          'age_range': _selectedAgeRange,
          'body_type': _selectedBodyType,
          'favorite_colors': _selectedColors,
          'lifestyle': _selectedLifestyle,
        },
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile setup complete! Welcome to Closet Fairy! 🧚‍♀️',
          ),
          backgroundColor: AppConstants.accentGreen,
          duration: Duration(seconds: 1),
        ),
      );

      // Wait a moment for the success message to show, then navigate to main app
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Navigate to the main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppConstants.accentCoral,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.primaryBlue, AppConstants.accentPink],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppConstants.textDark,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _getPageTitle(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppConstants.primaryFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ),
                      if (_currentPage > 0)
                        const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Progress Indicator
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                  ),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 4,
                    backgroundColor: AppConstants.neutralWhite.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppConstants.textDark,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                ),

                const SizedBox(height: AppConstants.spacingM),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildStylePage(),
                      _buildDemographicsPage(),
                      _buildColorPreferencesPage(),
                      _buildLifestylePage(),
                    ],
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canContinue() ? _nextPage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.neutralWhite,
                        foregroundColor: AppConstants.textDark,
                        elevation: 8,
                        shadowColor: AppConstants.textDark.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusL,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppConstants.textDark,
                                ),
                              ),
                            )
                          : Text(
                              _currentPage == 3 ? 'Complete Setup' : 'Continue',
                              style: const TextStyle(
                                fontFamily: AppConstants.secondaryFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return "What's your style vibe? ✨";
      case 1:
        return "Tell us about yourself";
      case 2:
        return "Color preferences";
      case 3:
        return "Your lifestyle";
      default:
        return "Setup";
    }
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0:
        return _selectedStyles.isNotEmpty;
      case 1:
        return _selectedAgeRange != null && _selectedBodyType != null;
      case 2:
        return _selectedColors.isNotEmpty;
      case 3:
        return _selectedLifestyle != null;
      default:
        return false;
    }
  }

  Widget _buildStylePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        children: [
          Text(
            'Select all that resonate with you',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: AppConstants.spacingS,
                mainAxisSpacing: AppConstants.spacingS,
              ),
              itemCount: _styleOptions.length,
              itemBuilder: (context, index) {
                final style = _styleOptions[index];
                final isSelected = _selectedStyles.contains(style['name']);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedStyles.remove(style['name']);
                      } else {
                        _selectedStyles.add(style['name']);
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: AppConstants.animationFast,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.neutralWhite
                          : AppConstants.neutralWhite.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: isSelected
                            ? AppConstants.textDark
                            : AppConstants.neutralWhite.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? AppConstants.softShadow : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          style['emoji'],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          style['displayName'],
                          style: TextStyle(
                            fontFamily: AppConstants.secondaryFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          style['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppConstants.secondaryFont,
                            fontSize: 10,
                            color: AppConstants.textDark.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingM),

            // Age Range
            _buildSelectionCard(
              title: 'Age Range',
              options: _ageRanges,
              selectedValue: _selectedAgeRange,
              onChanged: (value) => setState(() => _selectedAgeRange = value),
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Body Type
            _buildSelectionCard(
              title: 'Body Type',
              options: _bodyTypes,
              selectedValue: _selectedBodyType,
              onChanged: (value) => setState(() => _selectedBodyType = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        children: [
          Text(
            'Select your favorite colors',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: AppConstants.spacingS,
                mainAxisSpacing: AppConstants.spacingS,
              ),
              itemCount: _colorOptions.length,
              itemBuilder: (context, index) {
                final colorOption = _colorOptions[index];
                final isSelected = _selectedColors.contains(
                  colorOption['name'],
                );

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedColors.remove(colorOption['name']);
                      } else {
                        _selectedColors.add(colorOption['name']);
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: AppConstants.animationFast,
                    decoration: BoxDecoration(
                      color: colorOption['color'],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppConstants.textDark
                            : AppConstants.neutralWhite.withOpacity(0.5),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: isSelected ? AppConstants.softShadow : null,
                    ),
                    child: Center(
                      child: Text(
                        colorOption['name'],
                        style: TextStyle(
                          fontFamily: AppConstants.secondaryFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getContrastColor(colorOption['color']),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestylePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingM),

            _buildSelectionCard(
              title: 'Lifestyle',
              options: _lifestyles,
              selectedValue: _selectedLifestyle,
              onChanged: (value) => setState(() => _selectedLifestyle = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.neutralWhite.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          ...options.map(
            (option) => _buildOptionTile(
              option: option,
              isSelected: selectedValue == option,
              onTap: () => onChanged(option),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingXS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryBlue.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryBlue
                : AppConstants.neutralGray,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppConstants.textDark,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppConstants.primaryBlue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
