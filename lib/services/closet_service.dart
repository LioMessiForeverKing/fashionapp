import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ClosetService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Upload image to Supabase storage
  static Future<String> uploadImage(File imageFile) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}/clothing_$timestamp.jpg';

      // Upload file to Supabase storage
      await _supabase.storage
          .from('clothing-items')
          .upload(fileName, imageFile);

      // Get public URL
      final imageUrl = _supabase.storage
          .from('clothing-items')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get all clothing items for the current user
  static Future<List<Map<String, dynamic>>> getClothingItems({
    String? category,
    String? searchQuery,
    List<String>? tags,
    String? color,
    String? season,
    String? formality,
    bool? isFavorite,
    int limit = 50,
    int offset = 0,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      var query = _supabase
          .from('clothing_items')
          .select('*')
          .eq('user_id', user.id);

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'subcategory.ilike.%$searchQuery%,brand.ilike.%$searchQuery%,notes.ilike.%$searchQuery%',
        );
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.overlaps('tags', tags);
      }

      if (color != null && color.isNotEmpty) {
        query = query.eq('color', color);
      }

      if (season != null && season.isNotEmpty) {
        query = query.eq('season', season);
      }

      if (formality != null && formality.isNotEmpty) {
        query = query.eq('formality', formality);
      }

      if (isFavorite != null) {
        query = query.eq('is_favorite', isFavorite);
      }

      final List<Map<String, dynamic>> items = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return items;
    } catch (e) {
      print('Error fetching clothing items: $e');
      throw Exception('Failed to fetch clothing items: $e');
    }
  }

  // Add a new clothing item
  static Future<Map<String, dynamic>> addClothingItem({
    required String imageUrl,
    required String category,
    required String subcategory,
    required String color,
    String? pattern,
    String? fabric,
    String? brand,
    String? size,
    List<String>? tags,
    String? season,
    String? formality,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final itemData = {
        'user_id': user.id,
        'image_url': imageUrl,
        'category': category,
        'subcategory': subcategory,
        'color': color,
        'pattern': pattern,
        'fabric': fabric,
        'brand': brand,
        'size': size,
        'tags': tags ?? [],
        'season': season ?? 'all-year',
        'formality': formality ?? 'casual',
        'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
        'purchase_price': purchasePrice,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('clothing_items')
          .insert(itemData)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error adding clothing item: $e');
      throw Exception('Failed to add clothing item: $e');
    }
  }

  // Update a clothing item
  static Future<Map<String, dynamic>> updateClothingItem({
    required String itemId,
    String? imageUrl,
    String? category,
    String? subcategory,
    String? color,
    String? pattern,
    String? fabric,
    String? brand,
    String? size,
    List<String>? tags,
    String? season,
    String? formality,
    bool? isFavorite,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? notes,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (category != null) updateData['category'] = category;
      if (subcategory != null) updateData['subcategory'] = subcategory;
      if (color != null) updateData['color'] = color;
      if (pattern != null) updateData['pattern'] = pattern;
      if (fabric != null) updateData['fabric'] = fabric;
      if (brand != null) updateData['brand'] = brand;
      if (size != null) updateData['size'] = size;
      if (tags != null) updateData['tags'] = tags;
      if (season != null) updateData['season'] = season;
      if (formality != null) updateData['formality'] = formality;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;
      if (purchaseDate != null)
        updateData['purchase_date'] = purchaseDate.toIso8601String().split(
          'T',
        )[0];
      if (purchasePrice != null) updateData['purchase_price'] = purchasePrice;
      if (notes != null) updateData['notes'] = notes;

      final response = await _supabase
          .from('clothing_items')
          .update(updateData)
          .eq('id', itemId)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error updating clothing item: $e');
      throw Exception('Failed to update clothing item: $e');
    }
  }

  // Delete a clothing item
  static Future<void> deleteClothingItem(String itemId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('clothing_items')
          .delete()
          .eq('id', itemId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error deleting clothing item: $e');
      throw Exception('Failed to delete clothing item: $e');
    }
  }

  // Toggle favorite status
  static Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('clothing_items')
          .update({
            'is_favorite': !isFavorite,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Get clothing item by ID
  static Future<Map<String, dynamic>?> getClothingItem(String itemId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('clothing_items')
          .select()
          .eq('id', itemId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching clothing item: $e');
      return null;
    }
  }

  // Get clothing statistics
  static Future<Map<String, dynamic>> getClothingStats() async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('clothing_items')
          .select('category, is_favorite, times_worn')
          .eq('user_id', user.id);

      final stats = <String, dynamic>{
        'total_items': response.length,
        'favorite_items': response
            .where((item) => item['is_favorite'] == true)
            .length,
        'categories': <String, int>{},
        'total_times_worn': 0,
      };

      // Count by category
      for (final item in response) {
        final category = item['category'] as String;
        stats['categories'][category] =
            (stats['categories'][category] ?? 0) + 1;
        stats['total_times_worn'] += (item['times_worn'] as int? ?? 0);
      }

      return stats;
    } catch (e) {
      print('Error fetching clothing stats: $e');
      return {
        'total_items': 0,
        'favorite_items': 0,
        'categories': <String, int>{},
        'total_times_worn': 0,
      };
    }
  }

  // Get available filter options
  static Map<String, List<String>> getFilterOptions() {
    return {
      'categories': [
        'tops',
        'bottoms',
        'dresses',
        'outerwear',
        'shoes',
        'accessories',
      ],
      'colors': [
        'black',
        'white',
        'gray',
        'brown',
        'beige',
        'navy',
        'blue',
        'red',
        'pink',
        'green',
        'yellow',
        'purple',
        'orange',
        'cream',
        'denim',
      ],
      'seasons': ['all-year', 'spring', 'summer', 'fall', 'winter'],
      'formality': [
        'casual',
        'smart-casual',
        'business-casual',
        'business',
        'formal',
        'black-tie',
      ],
      'patterns': [
        'solid',
        'striped',
        'floral',
        'polka-dot',
        'plaid',
        'animal-print',
        'geometric',
      ],
      'fabrics': [
        'cotton',
        'silk',
        'denim',
        'wool',
        'polyester',
        'linen',
        'leather',
        'suede',
      ],
    };
  }
}
