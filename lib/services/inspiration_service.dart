import 'package:supabase_flutter/supabase_flutter.dart';

class InspirationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Sample inspiration data for demo purposes
  static final List<Map<String, dynamic>> _sampleInspirations = [
    {
      'id': '1',
      'image_url':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=600&fit=crop',
      'title': 'Minimalist Office Look',
      'description': 'Clean and professional for the modern workplace',
      'style_keywords': ['minimalist', 'professional', 'clean'],
      'color_palette': ['black', 'white', 'gray'],
      'occasion': 'work',
      'formality': 'business-casual',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '2',
      'image_url':
          'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=400&h=600&fit=crop',
      'title': 'Boho Weekend Vibes',
      'description': 'Free-spirited and comfortable for weekend adventures',
      'style_keywords': ['boho', 'casual', 'comfortable'],
      'color_palette': ['brown', 'cream', 'green'],
      'occasion': 'casual-weekend',
      'formality': 'casual',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '3',
      'image_url':
          'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&h=600&fit=crop',
      'title': 'Elegant Date Night',
      'description': 'Sophisticated and romantic for special evenings',
      'style_keywords': ['romantic', 'elegant', 'sophisticated'],
      'color_palette': ['black', 'red', 'gold'],
      'occasion': 'date-night',
      'formality': 'formal',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '4',
      'image_url':
          'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400&h=600&fit=crop',
      'title': 'Preppy Spring Style',
      'description': 'Classic and polished for spring occasions',
      'style_keywords': ['preppy', 'classic', 'polished'],
      'color_palette': ['navy', 'white', 'pink'],
      'occasion': 'party',
      'formality': 'smart-casual',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '5',
      'image_url':
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&h=600&fit=crop',
      'title': 'Edgy Street Style',
      'description': 'Bold and unconventional for making a statement',
      'style_keywords': ['edgy', 'bold', 'unconventional'],
      'color_palette': ['black', 'white', 'silver'],
      'occasion': 'party',
      'formality': 'casual',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '6',
      'image_url':
          'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=400&h=600&fit=crop',
      'title': 'Casual Coffee Date',
      'description': 'Relaxed and comfortable for everyday moments',
      'style_keywords': ['casual', 'comfortable', 'relaxed'],
      'color_palette': ['blue', 'white', 'denim'],
      'occasion': 'casual-weekend',
      'formality': 'casual',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '7',
      'image_url':
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&h=600&fit=crop',
      'title': 'Romantic Garden Party',
      'description': 'Feminine and dreamy for outdoor celebrations',
      'style_keywords': ['romantic', 'feminine', 'dreamy'],
      'color_palette': ['pink', 'white', 'green'],
      'occasion': 'party',
      'formality': 'smart-casual',
      'source': 'unsplash',
      'is_saved': false,
    },
    {
      'id': '8',
      'image_url':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=600&fit=crop',
      'title': 'Modern Minimalist',
      'description': 'Clean lines and simple elegance',
      'style_keywords': ['minimalist', 'modern', 'clean'],
      'color_palette': ['white', 'black', 'beige'],
      'occasion': 'work',
      'formality': 'business-casual',
      'source': 'unsplash',
      'is_saved': false,
    },
  ];

  // Get inspiration feed (for now using sample data)
  static Future<List<Map<String, dynamic>>> getInspirationFeed({
    String? searchQuery,
    List<String>? styleFilters,
    List<String>? colorFilters,
    String? occasionFilter,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    List<Map<String, dynamic>> inspirations = List.from(_sampleInspirations);

    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      inspirations = inspirations.where((inspiration) {
        final title = inspiration['title'].toString().toLowerCase();
        final description = inspiration['description'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    if (styleFilters != null && styleFilters.isNotEmpty) {
      inspirations = inspirations.where((inspiration) {
        final keywords = List<String>.from(inspiration['style_keywords'] ?? []);
        return styleFilters.any((filter) => keywords.contains(filter));
      }).toList();
    }

    if (colorFilters != null && colorFilters.isNotEmpty) {
      inspirations = inspirations.where((inspiration) {
        final colors = List<String>.from(inspiration['color_palette'] ?? []);
        return colorFilters.any(
          (filter) => colors.contains(filter.toLowerCase()),
        );
      }).toList();
    }

    if (occasionFilter != null && occasionFilter.isNotEmpty) {
      inspirations = inspirations.where((inspiration) {
        return inspiration['occasion'] == occasionFilter;
      }).toList();
    }

    return inspirations;
  }

  // Save inspiration to user's collection
  static Future<void> saveInspiration(String inspirationId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Find the inspiration in sample data
      final inspiration = _sampleInspirations.firstWhere(
        (item) => item['id'] == inspirationId,
        orElse: () => throw Exception('Inspiration not found'),
      );

      // Save to database
      await _supabase.from('inspirations').insert({
        'user_id': user.id,
        'image_url': inspiration['image_url'],
        'source_url': 'https://unsplash.com',
        'source': inspiration['source'],
        'style_keywords': inspiration['style_keywords'],
        'color_palette': inspiration['color_palette'],
        'occasion': inspiration['occasion'],
        'formality': inspiration['formality'],
        'is_saved': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update local state
      final index = _sampleInspirations.indexWhere(
        (item) => item['id'] == inspirationId,
      );
      if (index != -1) {
        _sampleInspirations[index]['is_saved'] = true;
      }
    } catch (e) {
      print('Error saving inspiration: $e');
      throw Exception('Failed to save inspiration');
    }
  }

  // Remove inspiration from user's collection
  static Future<void> unsaveInspiration(String inspirationId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Remove from database
      await _supabase
          .from('inspirations')
          .delete()
          .eq('user_id', user.id)
          .eq(
            'image_url',
            _sampleInspirations.firstWhere(
              (item) => item['id'] == inspirationId,
            )['image_url'],
          );

      // Update local state
      final index = _sampleInspirations.indexWhere(
        (item) => item['id'] == inspirationId,
      );
      if (index != -1) {
        _sampleInspirations[index]['is_saved'] = false;
      }
    } catch (e) {
      print('Error unsaving inspiration: $e');
      throw Exception('Failed to unsave inspiration');
    }
  }

  // Get user's saved inspirations
  static Future<List<Map<String, dynamic>>> getSavedInspirations() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('inspirations')
          .select()
          .eq('user_id', user.id)
          .eq('is_saved', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching saved inspirations: $e');
      return [];
    }
  }

  // Get available filter options
  static Map<String, List<String>> getFilterOptions() {
    return {
      'styles': ['minimalist', 'boho', 'preppy', 'edgy', 'romantic', 'casual'],
      'colors': [
        'black',
        'white',
        'navy',
        'gray',
        'red',
        'pink',
        'blue',
        'green',
        'yellow',
        'purple',
        'orange',
        'brown',
      ],
      'occasions': ['work', 'date-night', 'casual-weekend', 'party', 'travel'],
    };
  }
}
