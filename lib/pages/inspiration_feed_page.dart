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
                    color: AppConstants.primaryBlue.withOpacity(0.1),
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
                  color: AppConstants.textDark.withOpacity(0.5),
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
        backgroundColor: AppConstants.primaryBlue.withOpacity(0.1),
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
              color: AppConstants.textDark.withOpacity(0.6),
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
          childAspectRatio: 0.75,
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
              // Image
              Positioned.fill(
                child: Image.network(
                  inspiration['image_url'],
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
                        Colors.black.withOpacity(0.7),
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
                      color: AppConstants.neutralWhite.withOpacity(0.9),
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
                          color: AppConstants.neutralWhite.withOpacity(0.8),
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
              color: AppConstants.textDark.withOpacity(0.3),
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
    // TODO: Implement inspiration detail view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${inspiration['title']} - Detail view coming soon!'),
        backgroundColor: AppConstants.primaryBlue,
      ),
    );
  }
}
