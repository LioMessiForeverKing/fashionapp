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
                color: AppConstants.textDark.withOpacity(0.5),
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
        backgroundColor: AppConstants.primaryBlue.withOpacity(0.1),
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
              color: AppConstants.textDark.withOpacity(0.6),
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
                      color: AppConstants.neutralWhite.withOpacity(0.9),
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
                    color: AppConstants.primaryBlue.withOpacity(0.9),
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
                        Colors.black.withOpacity(0.8),
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
                            color: AppConstants.neutralWhite.withOpacity(0.8),
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
                  color: AppConstants.textDark.withOpacity(0.7),
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
                    color: AppConstants.primaryBlue.withOpacity(0.1),
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
                      color: AppConstants.textDark.withOpacity(0.2),
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
                : AppConstants.textDark.withOpacity(0.5),
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
            AppConstants.neutralGray.withOpacity(0.3),
            AppConstants.neutralGray.withOpacity(0.6),
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
            AppConstants.neutralGray.withOpacity(0.3),
            AppConstants.neutralGray.withOpacity(0.6),
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
    // TODO: Implement item detail modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['subcategory']} - Detail view coming soon!'),
        backgroundColor: AppConstants.primaryBlue,
      ),
    );
  }

  void _showFilterModal() {
    // TODO: Implement filter modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter modal coming soon! 🔍'),
        backgroundColor: AppConstants.accentGreen,
      ),
    );
  }
}
