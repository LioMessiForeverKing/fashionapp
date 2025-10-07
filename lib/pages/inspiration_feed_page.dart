import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../services/inspiration_service.dart';

class InspirationFeedPage extends StatefulWidget {
  const InspirationFeedPage({super.key});

  @override
  State<InspirationFeedPage> createState() => _InspirationFeedPageState();
}

class _InspirationFeedPageState extends State<InspirationFeedPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _inspirations = [];
  List<Map<String, dynamic>> _filteredInspirations = [];
  bool _isLoading = true;
  bool _isSearching = false;

  // Filter states
  List<String> _selectedStyles = [];
  List<String> _selectedColors = [];
  String? _selectedOccasion;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

    _loadInspirations();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadInspirations() async {
    setState(() => _isLoading = true);

    try {
      final inspirations = await InspirationService.getInspirationFeed(
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        styleFilters: _selectedStyles.isNotEmpty ? _selectedStyles : null,
        colorFilters: _selectedColors.isNotEmpty ? _selectedColors : null,
        occasionFilter: _selectedOccasion,
      );

      setState(() {
        _inspirations = inspirations;
        _filteredInspirations = inspirations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load inspirations: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInspirations = _inspirations.where((inspiration) {
        // Style filter
        if (_selectedStyles.isNotEmpty) {
          final keywords = List<String>.from(
            inspiration['style_keywords'] ?? [],
          );
          if (!_selectedStyles.any((style) => keywords.contains(style))) {
            return false;
          }
        }

        // Color filter
        if (_selectedColors.isNotEmpty) {
          final colors = List<String>.from(inspiration['color_palette'] ?? []);
          if (!_selectedColors.any(
            (color) => colors.contains(color.toLowerCase()),
          )) {
            return false;
          }
        }

        // Occasion filter
        if (_selectedOccasion != null && _selectedOccasion!.isNotEmpty) {
          if (inspiration['occasion'] != _selectedOccasion) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStyles.clear();
      _selectedColors.clear();
      _selectedOccasion = null;
      _searchController.clear();
    });
    _loadInspirations();
  }

  Future<void> _toggleSave(String inspirationId, bool isCurrentlySaved) async {
    HapticFeedback.lightImpact();

    try {
      if (isCurrentlySaved) {
        await InspirationService.unsaveInspiration(inspirationId);
      } else {
        await InspirationService.saveInspiration(inspirationId);
      }

      // Update local state
      setState(() {
        final index = _filteredInspirations.indexWhere(
          (item) => item['id'] == inspirationId,
        );
        if (index != -1) {
          _filteredInspirations[index]['is_saved'] = !isCurrentlySaved;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlySaved
                  ? 'Removed from saved'
                  : 'Saved to your collection!',
            ),
            backgroundColor: isCurrentlySaved
                ? AppConstants.accentCoral
                : AppConstants.accentGreen,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${isCurrentlySaved ? 'unsave' : 'save'} inspiration',
            ),
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
            // Header with Search
            _buildHeader(),

            // Filter Chips
            if (_selectedStyles.isNotEmpty ||
                _selectedColors.isNotEmpty ||
                _selectedOccasion != null)
              _buildActiveFilters(),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredInspirations.isEmpty
                  ? _buildEmptyState()
                  : _buildInspirationGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppConstants.spacingM,
        left: AppConstants.spacingL,
        right: AppConstants.spacingL,
        bottom: AppConstants.spacingM,
      ),
      decoration: const BoxDecoration(
        color: AppConstants.neutralWhite,
        boxShadow: AppConstants.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '💫 Inspiration',
                style: const TextStyle(
                  fontFamily: AppConstants.primaryFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showFilterModal(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: AppConstants.textDark,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppConstants.neutralGray,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _isSearching = value.isNotEmpty);
                _loadInspirations();
              },
              decoration: InputDecoration(
                hintText: 'Search for styles, colors, occasions...',
                hintStyle: TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  color: AppConstants.textDark.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppConstants.textDark,
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _isSearching = false);
                          _loadInspirations();
                        },
                        icon: const Icon(
                          Icons.clear,
                          color: AppConstants.textDark,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._selectedStyles.map(
                    (style) => _buildFilterChip(style, 'style'),
                  ),
                  ..._selectedColors.map(
                    (color) => _buildFilterChip(color, 'color'),
                  ),
                  if (_selectedOccasion != null)
                    _buildFilterChip(_selectedOccasion!, 'occasion'),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear All',
              style: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                color: AppConstants.accentCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.spacingS),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppConstants.primaryBlue.withValues(alpha: 0.1),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: AppConstants.textDark,
        ),
        onDeleted: () {
          setState(() {
            switch (type) {
              case 'style':
                _selectedStyles.remove(label);
                break;
              case 'color':
                _selectedColors.remove(label);
                break;
              case 'occasion':
                _selectedOccasion = null;
                break;
            }
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppConstants.textDark),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'No inspirations found',
            style: const TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton(
            onPressed: _clearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
              foregroundColor: AppConstants.neutralWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
            ),
            child: const Text(
              'Clear Filters',
              style: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationGrid() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8, // Increased from 0.75 to give more height
          crossAxisSpacing: AppConstants.spacingM,
          mainAxisSpacing: AppConstants.spacingM,
        ),
        itemCount: _filteredInspirations.length,
        itemBuilder: (context, index) {
          final inspiration = _filteredInspirations[index];
          return _buildInspirationCard(inspiration);
        },
      ),
    );
  }

  Widget _buildInspirationCard(Map<String, dynamic> inspiration) {
    final isSaved = inspiration['is_saved'] as bool;

    return GestureDetector(
      onTap: () => _showInspirationDetail(inspiration),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: AppConstants.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          child: Stack(
            children: [
              // Image - Simplified for testing
              Image.network(
                inspiration['image_url'],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppConstants.neutralGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryBlue,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppConstants.neutralGray,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppConstants.textDark,
                      size: 48,
                    ),
                  );
                },
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Save button
              Positioned(
                top: AppConstants.spacingM,
                right: AppConstants.spacingM,
                child: GestureDetector(
                  onTap: () => _toggleSave(inspiration['id'], isSaved),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.neutralWhite.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved
                          ? AppConstants.accentCoral
                          : AppConstants.textDark,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        inspiration['title'],
                        style: const TextStyle(
                          fontFamily: AppConstants.primaryFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.neutralWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        inspiration['description'],
                        style: TextStyle(
                          fontFamily: AppConstants.secondaryFont,
                          fontSize: 12,
                          color: AppConstants.neutralWhite.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterModal(),
    );
  }

  Widget _buildFilterModal() {
    final filterOptions = InspirationService.getFilterOptions();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusXL),
          topRight: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppConstants.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.textDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontFamily: AppConstants.primaryFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontFamily: AppConstants.secondaryFont,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style Filters
                  _buildFilterSection(
                    'Style',
                    filterOptions['styles']!,
                    _selectedStyles,
                    (value) {
                      setState(() {
                        if (_selectedStyles.contains(value)) {
                          _selectedStyles.remove(value);
                        } else {
                          _selectedStyles.add(value);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Color Filters
                  _buildFilterSection(
                    'Colors',
                    filterOptions['colors']!,
                    _selectedColors,
                    (value) {
                      setState(() {
                        if (_selectedColors.contains(value)) {
                          _selectedColors.remove(value);
                        } else {
                          _selectedColors.add(value);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Occasion Filters
                  _buildOccasionFilter(filterOptions['occasions']!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    return Column(
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
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () => onToggle(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryBlue
                      : AppConstants.neutralGray,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: AppConstants.secondaryFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppConstants.neutralWhite
                        : AppConstants.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOccasionFilter(List<String> occasions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Occasion',
          style: TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: occasions.map((occasion) {
            final isSelected = _selectedOccasion == occasion;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOccasion = isSelected ? null : occasion;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConstants.primaryBlue
                      : AppConstants.neutralGray,
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Text(
                  occasion.replaceAll('-', ' ').toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppConstants.secondaryFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppConstants.neutralWhite
                        : AppConstants.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showInspirationDetail(Map<String, dynamic> inspiration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInspirationDetailModal(inspiration),
    );
  }

  Widget _buildInspirationDetailModal(Map<String, dynamic> inspiration) {
    final isSaved = inspiration['is_saved'] as bool;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppConstants.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.textDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inspiration['title'] ?? 'Fashion Inspiration',
                    style: const TextStyle(
                      fontFamily: AppConstants.primaryFont,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleSave(inspiration['id'], isSaved),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSaved
                          ? AppConstants.accentCoral.withValues(alpha: 0.1)
                          : AppConstants.neutralGray,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved
                          ? AppConstants.accentCoral
                          : AppConstants.textDark,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: AppConstants.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                child: Image.network(
                  inspiration['image_url'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppConstants.neutralGray,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryBlue,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppConstants.neutralGray,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppConstants.textDark,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  inspiration['description'] ?? 'Beautiful fashion inspiration',
                  style: const TextStyle(
                    fontFamily: AppConstants.secondaryFont,
                    fontSize: 16,
                    color: AppConstants.textDark,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppConstants.spacingL),

                // Style tags
                if (inspiration['style_keywords'] != null &&
                    (inspiration['style_keywords'] as List).isNotEmpty)
                  _buildTagsSection('Style', inspiration['style_keywords']),

                const SizedBox(height: AppConstants.spacingM),

                // Color palette
                if (inspiration['color_palette'] != null &&
                    (inspiration['color_palette'] as List).isNotEmpty)
                  _buildColorPalette(inspiration['color_palette']),

                const SizedBox(height: AppConstants.spacingL),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement "Create Outfit" functionality
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Create Outfit feature coming soon! ✨',
                              ),
                              backgroundColor: AppConstants.accentGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.style, size: 20),
                        label: const Text('Create Outfit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryBlue,
                          foregroundColor: AppConstants.neutralWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement share functionality
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon! 📤'),
                              backgroundColor: AppConstants.accentGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryBlue,
                          side: const BorderSide(
                            color: AppConstants.primaryBlue,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(String title, List<dynamic> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  child: Text(
                    tag.toString().toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppConstants.secondaryFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorPalette(List<dynamic> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Palette',
          style: TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: colors
              .take(6)
              .map(
                (color) => Container(
                  margin: const EdgeInsets.only(right: AppConstants.spacingS),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getColorFromString(color.toString()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppConstants.textDark.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'gray':
        return Colors.grey;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      case 'navy':
        return const Color(0xFF1B2951);
      case 'cream':
        return const Color(0xFFF5F5DC);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'denim':
        return const Color(0xFF1560BD);
      default:
        return Colors.grey;
    }
  }
}
