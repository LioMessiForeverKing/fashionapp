import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../services/closet_service.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _clothingItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;

  // Filter states
  String? _selectedCategory;
  List<String> _selectedColors = [];
  String? _selectedSeason;
  String? _selectedFormality;
  bool? _showFavoritesOnly;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // View mode
  bool _isGridView = true;

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

    _validateFilterValues();
    _loadClothingItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _loadMoreItems();
    }
  }

  void _validateFilterValues() {
    final filterOptions = ClosetService.getFilterOptions();

    // Validate category
    if (_selectedCategory != null &&
        !filterOptions['categories']!.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

    // Validate season
    if (_selectedSeason != null &&
        !filterOptions['seasons']!.contains(_selectedSeason)) {
      _selectedSeason = null;
    }

    // Validate formality
    if (_selectedFormality != null &&
        !filterOptions['formality']!.contains(_selectedFormality)) {
      _selectedFormality = null;
    }

    // Validate colors
    _selectedColors = _selectedColors
        .where((color) => filterOptions['colors']!.contains(color))
        .toList();
  }

  Future<void> _loadClothingItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await ClosetService.getClothingItems(
        category: _selectedCategory,
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        color: _selectedColors.isNotEmpty ? _selectedColors.first : null,
        season: _selectedSeason,
        formality: _selectedFormality,
        isFavorite: _showFavoritesOnly,
      );

      setState(() {
        _clothingItems = items;
        _filteredItems = items;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load clothing items: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final moreItems = await ClosetService.getClothingItems(
        category: _selectedCategory,
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        color: _selectedColors.isNotEmpty ? _selectedColors.first : null,
        season: _selectedSeason,
        formality: _selectedFormality,
        isFavorite: _showFavoritesOnly,
        offset: _clothingItems.length,
      );

      setState(() {
        _clothingItems.addAll(moreItems);
        _filteredItems = _clothingItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more items: $e'),
            backgroundColor: AppConstants.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _refreshItems() async {
    setState(() {
      _clothingItems = [];
      _filteredItems = [];
      _isLoading = false;
    });
    await _loadClothingItems();
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _clothingItems.where((item) {
        // Category filter
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          if (item['category'] != _selectedCategory) return false;
        }

        // Color filter
        if (_selectedColors.isNotEmpty) {
          if (!_selectedColors.contains(item['color'])) return false;
        }

        // Season filter
        if (_selectedSeason != null && _selectedSeason!.isNotEmpty) {
          if (item['season'] != _selectedSeason) return false;
        }

        // Formality filter
        if (_selectedFormality != null && _selectedFormality!.isNotEmpty) {
          if (item['formality'] != _selectedFormality) return false;
        }

        // Favorites filter
        if (_showFavoritesOnly == true) {
          if (item['is_favorite'] != true) return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedColors = [];
      _selectedSeason = null;
      _selectedFormality = null;
      _showFavoritesOnly = null;
      _filteredItems = _clothingItems;
    });
  }

  Future<void> _toggleFavorite(String itemId, bool isCurrentlyFavorite) async {
    HapticFeedback.lightImpact();

    try {
      await ClosetService.toggleFavorite(itemId, isCurrentlyFavorite);

      // Update local state
      setState(() {
        final index = _filteredItems.indexWhere((item) => item['id'] == itemId);
        if (index != -1) {
          _filteredItems[index]['is_favorite'] = !isCurrentlyFavorite;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyFavorite
                  ? 'Removed from favorites'
                  : 'Added to favorites!',
            ),
            backgroundColor: isCurrentlyFavorite
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
            content: Text('Failed to update favorite: $e'),
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
            if (_selectedCategory != null ||
                _selectedColors.isNotEmpty ||
                _selectedSeason != null ||
                _selectedFormality != null ||
                _showFavoritesOnly == true)
              _buildActiveFilters(),

            // Content
            Expanded(
              child: _isLoading && _filteredItems.isEmpty
                  ? _buildLoadingState()
                  : _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to upload page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload feature coming soon! 📸'),
              backgroundColor: AppConstants.accentGreen,
            ),
          );
        },
        backgroundColor: AppConstants.primaryBlue,
        child: const Icon(Icons.add, color: AppConstants.neutralWhite),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '👗 My Closet',
                  style: const TextStyle(
                    fontFamily: AppConstants.primaryFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _isGridView = !_isGridView);
                },
                icon: Icon(
                  _isGridView ? Icons.list : Icons.grid_view,
                  color: AppConstants.textDark,
                ),
              ),
              IconButton(
                onPressed: _showFilterModal,
                icon: const Icon(
                  Icons.filter_list,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your closet...',
              hintStyle: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                color: AppConstants.textDark.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppConstants.textDark,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadClothingItems();
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: AppConstants.textDark,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppConstants.neutralGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
            ),
            style: const TextStyle(
              fontFamily: AppConstants.secondaryFont,
              color: AppConstants.textDark,
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                _loadClothingItems();
              }
            },
            onSubmitted: (value) => _loadClothingItems(),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedCategory != null)
              _buildFilterChip(_selectedCategory!, 'category'),
            ..._selectedColors.map((color) => _buildFilterChip(color, 'color')),
            if (_selectedSeason != null)
              _buildFilterChip(_selectedSeason!, 'season'),
            if (_selectedFormality != null)
              _buildFilterChip(_selectedFormality!, 'formality'),
            if (_showFavoritesOnly == true)
              _buildFilterChip('Favorites', 'favorites'),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  color: AppConstants.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.spacingS),
      child: Chip(
        label: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppConstants.secondaryFont,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppConstants.primaryBlue,
          ),
        ),
        backgroundColor: AppConstants.primaryBlue.withValues(alpha: 0.1),
        deleteIcon: const Icon(
          Icons.close,
          size: 16,
          color: AppConstants.primaryBlue,
        ),
        onDeleted: () {
          setState(() {
            switch (type) {
              case 'category':
                _selectedCategory = null;
                break;
              case 'color':
                _selectedColors.remove(label);
                break;
              case 'season':
                _selectedSeason = null;
                break;
              case 'formality':
                _selectedFormality = null;
                break;
              case 'favorites':
                _showFavoritesOnly = null;
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
          const Icon(Icons.checkroom, size: 64, color: AppConstants.textDark),
          const SizedBox(height: AppConstants.spacingL),
          const Text(
            'Your closet is empty',
            style: TextStyle(
              fontFamily: AppConstants.primaryFont,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Start building your digital wardrobe!',
            style: TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton.icon(
            onPressed: () {
              // Show coming soon message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Searching for your clothes... Coming Soon! 🔍',
                  ),
                  backgroundColor: AppConstants.accentGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Search for Your Clothes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
              foregroundColor: AppConstants.neutralWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return RefreshIndicator(
      onRefresh: _refreshItems,
      color: AppConstants.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: AppConstants.spacingM,
            mainAxisSpacing: AppConstants.spacingM,
          ),
          itemCount: _filteredItems.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _filteredItems.length) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryBlue,
                  ),
                ),
              );
            }

            final item = _filteredItems[index];
            return _buildClothingCard(item);
          },
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _refreshItems,
      color: AppConstants.primaryBlue,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: _filteredItems.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredItems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingL),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryBlue,
                  ),
                ),
              ),
            );
          }

          final item = _filteredItems[index];
          return _buildClothingListItem(item);
        },
      ),
    );
  }

  Widget _buildClothingCard(Map<String, dynamic> item) {
    final isFavorite = item['is_favorite'] as bool? ?? false;

    return GestureDetector(
      onTap: () => _showItemDetail(item),
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
              item['image_url'] != null &&
                      item['image_url'].toString().isNotEmpty
                  ? Image.network(
                      item['image_url'],
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
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),

              // Favorite button
              Positioned(
                top: AppConstants.spacingS,
                right: AppConstants.spacingS,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(item['id'], isFavorite),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppConstants.neutralWhite.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? AppConstants.accentCoral
                          : AppConstants.textDark,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Category badge
              Positioned(
                top: AppConstants.spacingS,
                left: AppConstants.spacingS,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Text(
                    item['category']?.toString().toUpperCase() ?? 'ITEM',
                    style: const TextStyle(
                      fontFamily: AppConstants.secondaryFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.neutralWhite,
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['subcategory'] ?? 'Clothing Item',
                        style: const TextStyle(
                          fontFamily: AppConstants.primaryFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.neutralWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item['brand'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item['brand'],
                          style: TextStyle(
                            fontFamily: AppConstants.secondaryFont,
                            fontSize: 12,
                            color: AppConstants.neutralWhite.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildClothingListItem(Map<String, dynamic> item) {
    final isFavorite = item['is_favorite'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.neutralWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: AppConstants.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spacingM),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child:
              item['image_url'] != null &&
                  item['image_url'].toString().isNotEmpty
              ? Image.network(
                  item['image_url'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
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
                    return _buildListImagePlaceholder();
                  },
                )
              : _buildListImagePlaceholder(),
        ),
        title: Text(
          item['subcategory'] ?? 'Clothing Item',
          style: const TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['brand'] != null)
              Text(
                item['brand'],
                style: TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  fontSize: 14,
                  color: AppConstants.textDark.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Text(
                    item['category']?.toString().toUpperCase() ?? 'ITEM',
                    style: const TextStyle(
                      fontFamily: AppConstants.secondaryFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorFromString(
                      item['color']?.toString() ?? 'gray',
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.textDark.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _toggleFavorite(item['id'], isFavorite),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite
                ? AppConstants.accentCoral
                : AppConstants.textDark.withValues(alpha: 0.5),
          ),
        ),
        onTap: () => _showItemDetail(item),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.neutralGray.withValues(alpha: 0.3),
            AppConstants.neutralGray.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.checkroom, color: AppConstants.textDark, size: 40),
      ),
    );
  }

  Widget _buildListImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.neutralGray.withValues(alpha: 0.3),
            AppConstants.neutralGray.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.checkroom, color: AppConstants.textDark, size: 24),
      ),
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
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'denim':
        return const Color(0xFF1560BD);
      default:
        return Colors.grey;
    }
  }

  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailModal(item),
    );
  }

  Widget _buildItemDetailModal(Map<String, dynamic> item) {
    final isFavorite = item['is_favorite'] as bool? ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                    item['subcategory'] ?? 'Clothing Item',
                    style: const TextStyle(
                      fontFamily: AppConstants.primaryFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleFavorite(item['id'], isFavorite),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? AppConstants.accentCoral
                        : AppConstants.textDark,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (item['image_url'] != null &&
                      item['image_url'].toString().isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                        boxShadow: AppConstants.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                        child: Image.network(
                          item['image_url'],
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
                              child: const Center(
                                child: Icon(
                                  Icons.checkroom,
                                  size: 64,
                                  color: AppConstants.textDark,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppConstants.neutralGray,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.checkroom,
                          size: 64,
                          color: AppConstants.textDark,
                        ),
                      ),
                    ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Basic Info
                  _buildDetailSection('Basic Information', [
                    _buildDetailItem(
                      'Category',
                      item['category']?.toString().toUpperCase() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      'Subcategory',
                      item['subcategory'] ?? 'N/A',
                    ),
                    _buildDetailItem('Brand', item['brand'] ?? 'N/A'),
                    _buildDetailItem('Size', item['size'] ?? 'N/A'),
                  ]),

                  const SizedBox(height: AppConstants.spacingL),

                  // Style Details
                  _buildDetailSection('Style Details', [
                    _buildDetailItem(
                      'Color',
                      item['color']?.toString().toUpperCase() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      'Pattern',
                      item['pattern']?.toString().toUpperCase() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      'Fabric',
                      item['fabric']?.toString().toUpperCase() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      'Season',
                      item['season']?.toString().toUpperCase() ?? 'N/A',
                    ),
                    _buildDetailItem(
                      'Formality',
                      item['formality']?.toString().toUpperCase() ?? 'N/A',
                    ),
                  ]),

                  const SizedBox(height: AppConstants.spacingL),

                  // Purchase Info
                  if (item['purchase_date'] != null ||
                      item['purchase_price'] != null)
                    _buildDetailSection('Purchase Information', [
                      if (item['purchase_date'] != null)
                        _buildDetailItem(
                          'Purchase Date',
                          item['purchase_date'],
                        ),
                      if (item['purchase_price'] != null)
                        _buildDetailItem(
                          'Purchase Price',
                          '\$${item['purchase_price']}',
                        ),
                    ]),

                  const SizedBox(height: AppConstants.spacingL),

                  // Tags
                  if (item['tags'] != null && (item['tags'] as List).isNotEmpty)
                    _buildTagsSection(item['tags'] as List<dynamic>),

                  const SizedBox(height: AppConstants.spacingL),

                  // Notes
                  if (item['notes'] != null &&
                      item['notes'].toString().isNotEmpty)
                    _buildNotesSection(item['notes']),

                  const SizedBox(height: AppConstants.spacingXL),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.neutralWhite,
              border: Border(
                top: BorderSide(
                  color: AppConstants.neutralGray.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement edit functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit functionality coming soon! ✏️'),
                          backgroundColor: AppConstants.accentGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConstants.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteItem(item['id']);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentCoral,
                      foregroundColor: AppConstants.neutralWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
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
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.neutralGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.secondaryFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppConstants.secondaryFont,
                fontSize: 14,
                color: AppConstants.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(List<dynamic> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
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
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: AppConstants.primaryBlue.withValues(alpha: 0.3),
                ),
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
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppConstants.neutralGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Text(
            notes,
            style: const TextStyle(
              fontFamily: AppConstants.secondaryFont,
              fontSize: 14,
              color: AppConstants.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteItem(String itemId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.accentCoral,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await ClosetService.deleteClothingItem(itemId);

        // Remove from local state
        setState(() {
          _clothingItems.removeWhere((item) => item['id'] == itemId);
          _filteredItems.removeWhere((item) => item['id'] == itemId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: AppConstants.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: $e'),
              backgroundColor: AppConstants.accentCoral,
            ),
          );
        }
      }
    }
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                const Text(
                  'Filter Items',
                  style: TextStyle(
                    fontFamily: AppConstants.primaryFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontFamily: AppConstants.secondaryFont,
                      color: AppConstants.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filter
                  _buildFilterSection(
                    'Category',
                    _selectedCategory,
                    ClosetService.getFilterOptions()['categories']!,
                    (value) => setState(() => _selectedCategory = value),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Color filter
                  _buildMultiSelectFilterSection(
                    'Colors',
                    _selectedColors,
                    ClosetService.getFilterOptions()['colors']!,
                    (colors) => setState(() => _selectedColors = colors),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Season filter
                  _buildFilterSection(
                    'Season',
                    _selectedSeason,
                    ClosetService.getFilterOptions()['seasons']!,
                    (value) => setState(() => _selectedSeason = value),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Formality filter
                  _buildFilterSection(
                    'Formality',
                    _selectedFormality,
                    ClosetService.getFilterOptions()['formality']!,
                    (value) => setState(() => _selectedFormality = value),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Favorites filter
                  _buildFavoritesFilter(),

                  const SizedBox(height: AppConstants.spacingXL),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              color: AppConstants.neutralWhite,
              border: Border(
                top: BorderSide(
                  color: AppConstants.neutralGray.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _applyFilters();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: AppConstants.neutralWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
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
    );
  }

  Widget _buildFilterSection(
    String title,
    String? selectedValue,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
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
        const SizedBox(height: AppConstants.spacingM),
        DropdownButtonFormField<String>(
          value: selectedValue != null && options.contains(selectedValue)
              ? selectedValue
              : null,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppConstants.neutralGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingM,
            ),
          ),
          style: const TextStyle(
            fontFamily: AppConstants.secondaryFont,
            color: AppConstants.textDark,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'All ${title.toLowerCase()}',
                style: const TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  color: AppConstants.textDark,
                ),
              ),
            ),
            ...options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppConstants.secondaryFont,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiSelectFilterSection(
    String title,
    List<String> selectedValues,
    List<String> options,
    void Function(List<String>) onChanged,
  ) {
    return Column(
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
        const SizedBox(height: AppConstants.spacingM),
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(
                option.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppConstants.secondaryFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppConstants.neutralWhite
                      : AppConstants.primaryBlue,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<String>.from(selectedValues);
                if (selected) {
                  newValues.add(option);
                } else {
                  newValues.remove(option);
                }
                onChanged(newValues);
              },
              backgroundColor: AppConstants.neutralGray,
              selectedColor: AppConstants.primaryBlue,
              checkmarkColor: AppConstants.neutralWhite,
              side: BorderSide(
                color: isSelected
                    ? AppConstants.primaryBlue
                    : AppConstants.neutralGray,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFavoritesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Show Only',
          style: TextStyle(
            fontFamily: AppConstants.primaryFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: FilterChip(
                label: const Text(
                  'FAVORITES',
                  style: TextStyle(
                    fontFamily: AppConstants.secondaryFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textDark,
                  ),
                ),
                selected: _showFavoritesOnly == true,
                onSelected: (selected) {
                  setState(() {
                    _showFavoritesOnly = selected ? true : null;
                  });
                },
                backgroundColor: AppConstants.neutralGray,
                selectedColor: AppConstants.accentPink,
                checkmarkColor: AppConstants.neutralWhite,
                side: BorderSide(
                  color: _showFavoritesOnly == true
                      ? AppConstants.accentPink
                      : AppConstants.neutralGray,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
