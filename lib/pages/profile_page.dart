import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/closet_service.dart';
import '../services/inspiration_service.dart';
import '../utils/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  String? _selectedGender;
  String? _selectedStylePreference;
  String? _selectedBodyType;
  String? _selectedBudget;
  String? _selectedLifestyle;

  // Stats data
  int _totalClothingItems = 0;
  int _savedInspirations = 0;

  @override
  void initState() {
    super.initState();
    _validateProfileValues();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _validateProfileValues() {
    // Valid gender options
    const validGenders = ['woman', 'man', 'non-binary', 'prefer-not-to-say'];
    if (_selectedGender != null && !validGenders.contains(_selectedGender)) {
      _selectedGender = null;
    }

    // Valid style preferences
    const validStyles = [
      'minimalist',
      'bohemian',
      'classic',
      'edgy',
      'romantic',
      'sporty',
      'vintage',
      'trendy',
    ];
    if (_selectedStylePreference != null &&
        !validStyles.contains(_selectedStylePreference)) {
      _selectedStylePreference = null;
    }

    // Valid body types
    const validBodyTypes = ['petite', 'athletic', 'curvy', 'tall', 'plus-size'];
    if (_selectedBodyType != null &&
        !validBodyTypes.contains(_selectedBodyType)) {
      _selectedBodyType = null;
    }

    // Valid budget ranges
    const validBudgets = ['budget-friendly', 'mid-range', 'high-end', 'luxury'];
    if (_selectedBudget != null && !validBudgets.contains(_selectedBudget)) {
      _selectedBudget = null;
    }

    // Valid lifestyles
    const validLifestyles = [
      'student',
      'professional',
      'creative',
      'athlete',
      'stay-at-home',
      'entrepreneur',
    ];
    if (_selectedLifestyle != null &&
        !validLifestyles.contains(_selectedLifestyle)) {
      _selectedLifestyle = null;
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final profile = await UserService.getUserProfile();

        if (profile != null) {
          _nameController.text = profile['name'] ?? '';

          // Extract from demographics object
          final demographics = profile['demographics'] as Map<String, dynamic>?;
          if (demographics != null) {
            _ageController.text = demographics['age_range']?.toString() ?? '';
            _selectedGender = demographics['gender'];
            _selectedBodyType = demographics['body_type'];
            _selectedLifestyle = demographics['lifestyle'];
          }

          // Extract style preferences (it's an array, take first one)
          final stylePreferences =
              profile['style_preferences'] as List<dynamic>?;
          if (stylePreferences != null && stylePreferences.isNotEmpty) {
            _selectedStylePreference = stylePreferences.first.toString();
          }

          // Extract budget from budget_preferences
          final budgetPreferences =
              profile['budget_preferences'] as Map<String, dynamic>?;
          if (budgetPreferences != null) {
            // Determine budget range based on average values
            final values = budgetPreferences.values.whereType<int>().toList();
            if (values.isNotEmpty) {
              final avg = values.reduce((a, b) => a + b) / values.length;
              if (avg < 50) {
                _selectedBudget = 'budget-friendly';
              } else if (avg < 100) {
                _selectedBudget = 'mid-range';
              } else if (avg < 200) {
                _selectedBudget = 'high-end';
              } else {
                _selectedBudget = 'luxury';
              }
            }
          }

          setState(() {});
        }
      }

      // Load stats
      await _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      // Load clothing stats
      final clothingStats = await ClosetService.getClothingStats();
      _totalClothingItems = clothingStats['total_items'] ?? 0;

      // Load saved inspirations count
      final savedInspirations = await InspirationService.getSavedInspirations();
      _savedInspirations = savedInspirations.length;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Error loading stats, keep defaults
      if (mounted) {
        setState(() {
          _totalClothingItems = 0;
          _savedInspirations = 0;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final user = AuthService.currentUser;
      if (user != null) {
        // Update basic user info
        final supabase = Supabase.instance.client;
        await supabase
            .from('users')
            .update({
              'name': _nameController.text.trim(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        // Update preferences using the existing method
        await UserService.updateUserPreferences(
          stylePreferences: _selectedStylePreference != null
              ? [_selectedStylePreference!]
              : null,
          demographics: {
            'age_range': _ageController.text.trim().isNotEmpty
                ? _ageController.text.trim()
                : null,
            'gender': _selectedGender,
            'body_type': _selectedBodyType,
            'lifestyle': _selectedLifestyle,
          },
          budgetPreferences: _selectedBudget != null
              ? _getBudgetPreferences(_selectedBudget!)
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! ✨'),
              backgroundColor: AppConstants.accentGreen,
            ),
          );

          setState(() => _isEditing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Map<String, int> _getBudgetPreferences(String budgetRange) {
    switch (budgetRange) {
      case 'budget-friendly':
        return {
          'tops': 30,
          'bottoms': 40,
          'dresses': 50,
          'shoes': 60,
          'accessories': 20,
        };
      case 'mid-range':
        return {
          'tops': 75,
          'bottoms': 85,
          'dresses': 100,
          'shoes': 120,
          'accessories': 40,
        };
      case 'high-end':
        return {
          'tops': 150,
          'bottoms': 175,
          'dresses': 200,
          'shoes': 250,
          'accessories': 80,
        };
      case 'luxury':
        return {
          'tops': 300,
          'bottoms': 350,
          'dresses': 400,
          'shoes': 500,
          'accessories': 150,
        };
      default:
        return {
          'tops': 100,
          'bottoms': 100,
          'dresses': 150,
          'shoes': 200,
          'accessories': 50,
        };
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await AuthService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.neutralGray,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryBlue,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildProfileCard(),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildStatsCard(),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildSettingsCard(),
                    const SizedBox(height: AppConstants.spacingXL),
                    _buildSignOutButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.primaryBlue,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: AppConstants.softShadow,
          ),
          child: const Icon(
            Icons.person,
            color: AppConstants.neutralWhite,
            size: 24,
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Profile',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
              Text(
                'Manage your style preferences',
                style: TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  fontSize: 14,
                  color: AppConstants.textDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        if (!_isEditing)
          IconButton(
            onPressed: _toggleEdit,
            icon: const Icon(Icons.edit),
            style: IconButton.styleFrom(
              backgroundColor: AppConstants.accentPink,
              foregroundColor: AppConstants.neutralWhite,
            ),
          ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.softShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: AppConstants.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.spacingM),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontFamily: AppConstants.primaryFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              icon: Icons.person_outline,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Age Field
            _buildTextField(
              controller: _ageController,
              label: 'Age',
              icon: Icons.cake_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 120) {
                    return 'Please enter a valid age';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Bio Field
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.description_outlined,
              enabled: _isEditing,
              maxLines: 3,
            ),

            const SizedBox(height: AppConstants.spacingL),

            // Gender
            _buildDropdown(
              value: _selectedGender,
              label: 'Gender',
              icon: Icons.person,
              items: const ['woman', 'man', 'non-binary', 'prefer-not-to-say'],
              enabled: _isEditing,
              onChanged: (value) {
                setState(() => _selectedGender = value);
              },
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Style Preferences
            _buildDropdown(
              value: _selectedStylePreference,
              label: 'Style Preference',
              icon: Icons.style,
              items: const [
                'minimalist',
                'bohemian',
                'classic',
                'edgy',
                'romantic',
                'sporty',
                'vintage',
                'trendy',
              ],
              enabled: _isEditing,
              onChanged: (value) {
                setState(() => _selectedStylePreference = value);
              },
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Body Type
            _buildDropdown(
              value: _selectedBodyType,
              label: 'Body Type',
              icon: Icons.accessibility,
              items: const ['petite', 'athletic', 'curvy', 'tall', 'plus-size'],
              enabled: _isEditing,
              onChanged: (value) {
                setState(() => _selectedBodyType = value);
              },
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Budget Range
            _buildDropdown(
              value: _selectedBudget,
              label: 'Budget Range',
              icon: Icons.attach_money,
              items: const [
                'budget-friendly',
                'mid-range',
                'high-end',
                'luxury',
              ],
              enabled: _isEditing,
              onChanged: (value) {
                setState(() => _selectedBudget = value);
              },
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Lifestyle
            _buildDropdown(
              value: _selectedLifestyle,
              label: 'Lifestyle',
              icon: Icons.work_outline,
              items: const [
                'student',
                'professional',
                'creative',
                'athlete',
                'stay-at-home',
                'entrepreneur',
              ],
              enabled: _isEditing,
              onChanged: (value) {
                setState(() => _selectedLifestyle = value);
              },
            ),

            if (_isEditing) ...[
              const SizedBox(height: AppConstants.spacingXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadUserProfile(); // Reset to original values
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppConstants.accentCoral),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: AppConstants.primaryFont,
                          color: AppConstants.accentCoral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryBlue,
                        foregroundColor: AppConstants.neutralWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppConstants.neutralWhite,
                                ),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontFamily: AppConstants.primaryFont,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontFamily: AppConstants.secondaryFont,
        color: enabled
            ? AppConstants.textDark
            : AppConstants.textDark.withValues(alpha: 0.6),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppConstants.neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppConstants.neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.primaryBlue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: enabled
            ? AppConstants.neutralWhite
            : AppConstants.neutralGray,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required bool enabled,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value != null && items.contains(value) ? value : null,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppConstants.neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: AppConstants.neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.primaryBlue,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: enabled
            ? AppConstants.neutralWhite
            : AppConstants.neutralGray,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item
                .replaceAll('-', ' ')
                .split(' ')
                .map((word) => word[0].toUpperCase() + word.substring(1))
                .join(' '),
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              color: AppConstants.textDark,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppConstants.accentGreen,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Your Style Stats',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.checkroom,
                  label: 'Items in Closet',
                  value: _totalClothingItems.toString(),
                  color: AppConstants.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.favorite,
                  label: 'Saved Inspirations',
                  value: _savedInspirations.toString(),
                  color: AppConstants.accentPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 12,
              color: AppConstants.textDark.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: AppConstants.accentGreen,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Settings & Preferences',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () => _showNotificationSettings(),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & Data',
            subtitle: 'Control your data and privacy settings',
            onTap: () => _showPrivacySettings(),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => _showHelpSupport(),
          ),
          const SizedBox(height: AppConstants.spacingM),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAbout(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: Icon(icon, color: AppConstants.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppConstants.primaryFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppConstants.secondaryFont,
                      fontSize: 14,
                      color: AppConstants.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppConstants.textDark.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Notification preferences coming soon! 🔔'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Data'),
        content: const Text('Privacy settings coming soon! 🔒'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Help and support features coming soon! 🆘'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Closet Fairy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text(
              'Closet Fairy helps you organize your wardrobe and discover your personal style.',
            ),
            SizedBox(height: 8),
            Text('Built with Flutter and Supabase.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppConstants.accentCoral),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
