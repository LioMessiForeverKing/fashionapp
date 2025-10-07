import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../services/ai_fairy_service.dart';
import '../services/closet_service.dart';
import '../services/user_service.dart';

class AIFairyPage extends StatefulWidget {
  const AIFairyPage({super.key});

  @override
  State<AIFairyPage> createState() => _AIFairyPageState();
}

class _AIFairyPageState extends State<AIFairyPage>
    with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _closetItems = [];
  List<Map<String, dynamic>> _outfitSuggestions = [];
  String _styleAdvice = '';
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isGeneratingOutfits = false;
  bool _isGeneratingAdvice = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sparkleAnimation;

  // Item selection
  Map<String, dynamic>? _selectedItem;
  bool _isGeneratingItemSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadClosetItems();
    _loadUserProfile();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClosetItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await ClosetService.getClothingItems();
      setState(() {
        _closetItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load closet items: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService.getUserProfile();
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      // User profile loading is not critical, continue without it
      // Error loading user profile: $e
    }
  }

  Future<void> _generateStyleAdvice() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ask a question! 💭'),
          backgroundColor: AppConstants.accentCoral,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAdvice = true);
    HapticFeedback.lightImpact();

    try {
      final advice = await AIFairyService.generateStyleAdvice(
        closetItems: _closetItems,
        question: _questionController.text.trim(),
      );

      setState(() {
        _styleAdvice = advice;
        _isGeneratingAdvice = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Style advice ready!'),
            backgroundColor: AppConstants.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingAdvice = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate advice: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _generateItemBasedOutfits() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item first! 👗'),
          backgroundColor: AppConstants.accentCoral,
        ),
      );
      return;
    }

    setState(() => _isGeneratingItemSuggestions = true);
    HapticFeedback.lightImpact();

    try {
      final suggestions = await AIFairyService.generateItemBasedOutfits(
        selectedItem: _selectedItem!,
        closetItems: _closetItems,
        userProfile: _userProfile,
      );

      setState(() {
        _outfitSuggestions = suggestions;
        _isGeneratingItemSuggestions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Outfit suggestions ready!'),
            backgroundColor: AppConstants.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingItemSuggestions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate suggestions: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _generateSurpriseOutfits() async {
    setState(() => _isGeneratingOutfits = true);
    HapticFeedback.lightImpact();

    try {
      final suggestions = await AIFairyService.generateSurpriseOutfits(
        closetItems: _closetItems,
        userProfile: _userProfile,
      );

      setState(() {
        _outfitSuggestions = suggestions;
        _isGeneratingOutfits = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Surprise outfits ready!'),
            backgroundColor: AppConstants.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingOutfits = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate surprise outfits: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.neutralGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _closetItems.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: const BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppConstants.radiusL),
        ),
        boxShadow: AppConstants.softShadow,
      ),
      child: Row(
        children: [
          // Sparkle animation
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _sparkleAnimation.value * 2 * 3.14159,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppConstants.accentYellow,
                  size: 28,
                ),
              );
            },
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              '🧚‍♀️ AI Fairy',
              style: const TextStyle(
                fontFamily: AppConstants.primaryFont,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadClosetItems,
            icon: const Icon(Icons.refresh, color: AppConstants.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
          ),
          SizedBox(height: AppConstants.spacingL),
          Text(
            'Loading your closet...',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 16,
              color: AppConstants.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checkroom,
              size: 80,
              color: AppConstants.textDark.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppConstants.spacingL),
            const Text(
              'Your Closet is Empty',
              style: TextStyle(
                fontFamily: AppConstants.primaryFont,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Add some clothing items to your closet first, then I can help you create amazing outfits!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                fontSize: 16,
                color: AppConstants.textDark.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to upload tab
                // This would need to be implemented with a callback to the parent
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Items to Closet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryBlue,
                foregroundColor: AppConstants.neutralWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXL,
                  vertical: AppConstants.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Selection Section
          _buildItemSelectionSection(),

          const SizedBox(height: AppConstants.spacingXL),

          // Outfit Generation Section
          _buildOutfitSection(),

          const SizedBox(height: AppConstants.spacingXL),

          // Style Advice Section
          _buildStyleAdviceSection(),

          const SizedBox(height: AppConstants.spacingXL),

          // Results
          if (_outfitSuggestions.isNotEmpty) _buildOutfitResults(),
          if (_styleAdvice.isNotEmpty) _buildStyleAdviceResult(),

          // Quick Actions Section
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildItemSelectionSection() {
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
              Icon(Icons.checkroom, color: AppConstants.accentPink, size: 24),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Pick an Item',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Selected Item Display
          if (_selectedItem != null) _buildSelectedItemCard(),

          const SizedBox(height: AppConstants.spacingL),

          // Item Selection Grid
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _closetItems.length,
              itemBuilder: (context, index) {
                final item = _closetItems[index];
                final isSelected = _selectedItem?['id'] == item['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedItem = item;
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.accentPink.withValues(alpha: 0.2)
                          : AppConstants.neutralGray,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: isSelected
                            ? AppConstants.accentPink
                            : AppConstants.primaryBlue.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(item['category']),
                          color: isSelected
                              ? AppConstants.accentPink
                              : AppConstants.textDark,
                          size: 24,
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          item['subcategory'] ?? 'Item',
                          style: TextStyle(
                            fontFamily: AppConstants.secondaryFont,
                            fontSize: 10,
                            color: isSelected
                                ? AppConstants.accentPink
                                : AppConstants.textDark,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppConstants.spacingL),

          // Generate Item-Based Outfits Button
          if (_selectedItem != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingItemSuggestions
                    ? null
                    : _generateItemBasedOutfits,
                icon: _isGeneratingItemSuggestions
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
                    : const Icon(Icons.style),
                label: Text(
                  _isGeneratingItemSuggestions
                      ? 'Creating Outfits...'
                      : 'What to Wear with This?',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentPink,
                  foregroundColor: AppConstants.neutralWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.accentPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.accentPink.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(_selectedItem!['category']),
            color: AppConstants.accentPink,
            size: 24,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedItem!['subcategory'] ?? 'Selected Item',
                  style: const TextStyle(
                    fontFamily: AppConstants.primaryFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                Text(
                  '${_selectedItem!['color']} • ${_selectedItem!['category']}',
                  style: TextStyle(
                    fontFamily: AppConstants.secondaryFont,
                    fontSize: 12,
                    color: AppConstants.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedItem = null;
              });
            },
            icon: const Icon(
              Icons.close,
              color: AppConstants.accentPink,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitSection() {
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
                Icons.auto_awesome,
                color: AppConstants.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Surprise Me!',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Get 3 completely random, creative outfit combinations from your closet!',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Surprise Me Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingOutfits ? null : _generateSurpriseOutfits,
              icon: _isGeneratingOutfits
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
                  : const Icon(Icons.casino),
              label: Text(
                _isGeneratingOutfits
                    ? 'Creating Surprises...'
                    : 'Surprise Me! 🎲',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryBlue,
                foregroundColor: AppConstants.neutralWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAdviceSection() {
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
              Icon(Icons.psychology, color: AppConstants.accentCoral, size: 24),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Style Advice',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: 'Ask me anything about style...',
              hintStyle: TextStyle(
                color: AppConstants.textDark.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color: AppConstants.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: const BorderSide(
                  color: AppConstants.primaryBlue,
                  width: 2,
                ),
              ),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: AppConstants.spacingL),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingAdvice ? null : _generateStyleAdvice,
              icon: _isGeneratingAdvice
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
                  : const Icon(Icons.lightbulb),
              label: Text(_isGeneratingAdvice ? 'Thinking...' : 'Get Advice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentCoral,
                foregroundColor: AppConstants.neutralWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitResults() {
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
          const Text(
            '✨ Outfit Suggestions',
            style: TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          ..._outfitSuggestions.map((outfit) => _buildOutfitCard(outfit)),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outfit['name'] ?? 'Outfit',
            style: const TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Items: ${(outfit['items'] as List).join(', ')}',
            style: const TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            outfit['tips'] ?? '',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAdviceResult() {
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
          const Text(
            '💡 Style Advice',
            style: TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            _styleAdvice,
            style: const TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 16,
              color: AppConstants.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
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
              Icon(Icons.flash_on, color: AppConstants.accentYellow, size: 24),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Quick action buttons
          Wrap(
            spacing: AppConstants.spacingM,
            runSpacing: AppConstants.spacingM,
            children: [
              _buildQuickActionButton(
                icon: Icons.wb_sunny,
                label: 'Summer Outfits',
                color: AppConstants.accentYellow,
                onTap: () => _generateSeasonalOutfits('summer'),
              ),
              _buildQuickActionButton(
                icon: Icons.ac_unit,
                label: 'Winter Outfits',
                color: AppConstants.primaryBlue,
                onTap: () => _generateSeasonalOutfits('winter'),
              ),
              _buildQuickActionButton(
                icon: Icons.work,
                label: 'Work Outfits',
                color: AppConstants.accentGreen,
                onTap: () => _generateOccasionOutfits('work'),
              ),
              _buildQuickActionButton(
                icon: Icons.favorite,
                label: 'Date Night',
                color: AppConstants.accentPink,
                onTap: () => _generateOccasionOutfits('date-night'),
              ),
              _buildQuickActionButton(
                icon: Icons.sports,
                label: 'Casual',
                color: AppConstants.accentCoral,
                onTap: () => _generateOccasionOutfits('casual'),
              ),
              _buildQuickActionButton(
                icon: Icons.celebration,
                label: 'Party',
                color: AppConstants.accentPink,
                onTap: () => _generateOccasionOutfits('party'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSeasonalOutfits(String season) async {
    setState(() => _isGeneratingOutfits = true);
    HapticFeedback.lightImpact();

    try {
      final suggestions = await AIFairyService.generateSeasonalOutfits(
        season: season,
        closetItems: _closetItems,
        userProfile: _userProfile,
      );

      setState(() {
        _outfitSuggestions = suggestions;
        _isGeneratingOutfits = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ${season.capitalize()} outfits ready!'),
            backgroundColor: AppConstants.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingOutfits = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate ${season} outfits: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _generateOccasionOutfits(String occasion) async {
    setState(() => _isGeneratingOutfits = true);
    HapticFeedback.lightImpact();

    try {
      final suggestions = await AIFairyService.generateOccasionOutfits(
        occasion: occasion,
        closetItems: _closetItems,
        userProfile: _userProfile,
      );

      setState(() {
        _outfitSuggestions = suggestions;
        _isGeneratingOutfits = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ ${occasion.replaceAll('-', ' ').capitalize()} outfits ready!',
            ),
            backgroundColor: AppConstants.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingOutfits = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate ${occasion} outfits: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'tops':
        return Icons.checkroom;
      case 'bottoms':
        return Icons.directions_walk;
      case 'dresses':
        return Icons.woman;
      case 'outerwear':
        return Icons.ac_unit;
      case 'shoes':
        return Icons.directions_walk;
      case 'accessories':
        return Icons.diamond;
      default:
        return Icons.checkroom;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
