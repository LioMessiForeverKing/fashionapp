import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AIFairyService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  // Generate outfit suggestions based on user's closet and preferences
  static Future<List<Map<String, dynamic>>> generateOutfitSuggestions({
    required List<Map<String, dynamic>> closetItems,
    String? occasion,
    String? weather,
    String? mood,
  }) async {
    try {
      final prompt = _buildOutfitPrompt(closetItems, occasion, weather, mood);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseOutfitResponse(response);
      }

      return _getFallbackSuggestions();
    } catch (e) {
      // Error generating outfit suggestions: $e
      return _getFallbackSuggestions();
    }
  }

  // Generate style advice based on user's preferences
  static Future<String> generateStyleAdvice({
    required List<Map<String, dynamic>> closetItems,
    String? question,
  }) async {
    try {
      final prompt = _buildStyleAdvicePrompt(closetItems, question);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseStyleAdviceResponse(response);
      }

      return _getFallbackStyleAdvice();
    } catch (e) {
      // Error generating style advice: $e
      return _getFallbackStyleAdvice();
    }
  }

  // Generate outfit suggestions based on a specific item
  static Future<List<Map<String, dynamic>>> generateItemBasedOutfits({
    required Map<String, dynamic> selectedItem,
    required List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
    String? occasion,
    String? weather,
    String? mood,
  }) async {
    try {
      final prompt = _buildItemBasedPrompt(
        selectedItem,
        closetItems,
        userProfile,
        occasion,
        weather,
        mood,
      );
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseOutfitResponse(response);
      }

      return _getFallbackItemBasedSuggestions(selectedItem);
    } catch (e) {
      // Error generating item-based outfit suggestions: $e
      return _getFallbackItemBasedSuggestions(selectedItem);
    }
  }

  // Generate random surprise outfits
  static Future<List<Map<String, dynamic>>> generateSurpriseOutfits({
    required List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final prompt = _buildSurprisePrompt(closetItems, userProfile);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseOutfitResponse(response);
      }

      return _getFallbackSurpriseSuggestions();
    } catch (e) {
      // Error generating surprise outfits: $e
      return _getFallbackSurpriseSuggestions();
    }
  }

  // Build outfit suggestion prompt
  static String _buildOutfitPrompt(
    List<Map<String, dynamic>> closetItems,
    String? occasion,
    String? weather,
    String? mood,
  ) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    return '''
You are a fashion AI assistant helping create outfit suggestions. 

User's closet contains: $itemsText

Context:
- Occasion: ${occasion ?? 'casual day'}
- Weather: ${weather ?? 'mild'}
- Mood: ${mood ?? 'comfortable'}

Please suggest 3 different outfit combinations using items from their closet. For each outfit, provide:
1. A creative name for the outfit
2. List of specific items to wear
3. Brief styling tips
4. Why this outfit works for the occasion

Format your response as a JSON array with this structure:
[
  {
    "name": "Outfit Name",
    "items": ["item1", "item2", "item3"],
    "tips": "Styling advice",
    "reason": "Why this works"
  }
]

Keep suggestions practical and achievable with their current wardrobe.
''';
  }

  // Build style advice prompt
  static String _buildStyleAdvicePrompt(
    List<Map<String, dynamic>> closetItems,
    String? question,
  ) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    return '''
You are a fashion AI assistant providing personalized style advice.

User's closet contains: $itemsText

Question: ${question ?? 'What styling advice do you have for me?'}

Please provide helpful, personalized fashion advice based on their current wardrobe. Keep it positive, practical, and encouraging. Focus on:
- How to maximize their current pieces
- Styling tips for their existing items
- Suggestions for future additions
- Confidence-building advice

Keep the response conversational and under 200 words.
''';
  }

  // Build item-based outfit prompt
  static String _buildItemBasedPrompt(
    Map<String, dynamic> selectedItem,
    List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
    String? occasion,
    String? weather,
    String? mood,
  ) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    final selectedItemText =
        '${selectedItem['subcategory']} (${selectedItem['color']}, ${selectedItem['category']})';

    // Extract user profile information
    final demographics = userProfile?['demographics'] as Map<String, dynamic>?;
    final gender = demographics?['gender'] ?? 'not specified';
    final bodyType = demographics?['body_type'] ?? 'not specified';
    final stylePreferences =
        userProfile?['style_preferences'] as List<dynamic>?;
    final styleText = stylePreferences?.isNotEmpty == true
        ? stylePreferences!.join(', ')
        : 'not specified';

    return '''
You are a fashion AI assistant helping create outfit suggestions based on a specific item.

User wants to wear: $selectedItemText

Their closet contains: $itemsText

User Profile:
- Gender: $gender
- Body Type: $bodyType
- Style Preferences: $styleText

Context:
- Occasion: ${occasion ?? 'casual day'}
- Weather: ${weather ?? 'mild'}
- Mood: ${mood ?? 'comfortable'}

Please suggest 3 different outfit combinations that work well with the selected item. For each outfit, provide:
1. A creative name for the outfit
2. List of specific items to wear (including the selected item)
3. Brief styling tips
4. Why this outfit works for the occasion

Format your response as a JSON array with this structure:
[
  {
    "name": "Outfit Name",
    "items": ["selected_item", "item2", "item3"],
    "tips": "Styling advice",
    "reason": "Why this works"
  }
]

Make sure the selected item is included in each outfit suggestion.
''';
  }

  // Build surprise outfit prompt
  static String _buildSurprisePrompt(
    List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
  ) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    // Extract user profile information
    final demographics = userProfile?['demographics'] as Map<String, dynamic>?;
    final gender = demographics?['gender'] ?? 'not specified';
    final bodyType = demographics?['body_type'] ?? 'not specified';
    final stylePreferences =
        userProfile?['style_preferences'] as List<dynamic>?;
    final styleText = stylePreferences?.isNotEmpty == true
        ? stylePreferences!.join(', ')
        : 'not specified';

    return '''
You are a fashion AI assistant creating surprise outfit combinations.

User's closet contains: $itemsText

User Profile:
- Gender: $gender
- Body Type: $bodyType
- Style Preferences: $styleText

Create 3 completely random, creative, and unexpected outfit combinations from their wardrobe. Be bold and experimental! Mix different styles, colors, and categories in fun ways. Consider their gender and body type for appropriate fits. For each outfit, provide:
1. A fun, creative name for the outfit
2. List of specific items to wear
3. Brief styling tips
4. Why this unexpected combination works

Format your response as a JSON array with this structure:
[
  {
    "name": "Creative Outfit Name",
    "items": ["item1", "item2", "item3"],
    "tips": "Styling advice",
    "reason": "Why this unexpected combo works"
  }
]

Be creative and don't be afraid to suggest bold combinations!
''';
  }

  // Call Gemini API
  static Future<String?> _callGeminiAPI(String prompt) async {
    try {
      final url =
          '$_baseUrl/models/gemini-2.5-flash-lite:generateContent?key=${AppConstants.kGeminiApiKey}';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Gemini API error: ${response.statusCode} - ${response.body}
        return null;
      }
    } catch (e) {
      // Error calling Gemini API: $e
      return null;
    }
  }

  // Parse outfit response
  static List<Map<String, dynamic>> _parseOutfitResponse(String response) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final List<dynamic> outfits = jsonDecode(jsonString);
        return outfits.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Error parsing outfit response: $e
    }

    return _getFallbackSuggestions();
  }

  // Parse style advice response
  static String _parseStyleAdviceResponse(String response) {
    // Clean up the response and return it
    return response.trim();
  }

  // Fallback outfit suggestions
  static List<Map<String, dynamic>> _getFallbackSuggestions() {
    return [
      {
        'name': 'Classic Casual',
        'items': ['Basic T-shirt', 'Jeans', 'Sneakers'],
        'tips': 'Perfect for everyday activities',
        'reason': 'Timeless and comfortable combination',
      },
      {
        'name': 'Smart Casual',
        'items': ['Button-up Shirt', 'Chinos', 'Loafers'],
        'tips': 'Great for casual meetings or dinner',
        'reason': 'Elevated casual look that\'s still comfortable',
      },
      {
        'name': 'Weekend Vibes',
        'items': ['Hoodie', 'Joggers', 'Sneakers'],
        'tips': 'Relaxed and cozy for lazy days',
        'reason': 'Maximum comfort for relaxation time',
      },
    ];
  }

  // Fallback style advice
  static String _getFallbackStyleAdvice() {
    return '''
Your wardrobe has great potential! Here are some tips to maximize your style:

1. **Mix and Match**: Try pairing different colors and textures from your closet
2. **Layer Smart**: Use jackets and cardigans to create depth
3. **Accessorize**: Add scarves, jewelry, or bags to elevate simple outfits
4. **Fit Matters**: Ensure your clothes fit well - it makes everything look better
5. **Confidence**: The best accessory is confidence - wear what makes you feel great!

Remember, style is personal. Experiment with different combinations and find what makes you feel most like yourself! ✨
''';
  }

  // Fallback item-based suggestions
  static List<Map<String, dynamic>> _getFallbackItemBasedSuggestions(
    Map<String, dynamic> selectedItem,
  ) {
    final itemName = selectedItem['subcategory'] ?? 'Selected Item';
    return [
      {
        'name': 'Classic with $itemName',
        'items': [itemName, 'Basic T-shirt', 'Jeans'],
        'tips': 'Keep it simple and let your chosen piece shine',
        'reason': 'Classic combination that always works',
      },
      {
        'name': 'Elevated $itemName',
        'items': [itemName, 'Button-up Shirt', 'Chinos'],
        'tips': 'Dress it up for a more polished look',
        'reason': 'Perfect for smart casual occasions',
      },
      {
        'name': 'Layered $itemName',
        'items': [itemName, 'Cardigan', 'Basic Tee'],
        'tips': 'Add layers for depth and interest',
        'reason': 'Great for transitional weather',
      },
    ];
  }

  // Fallback surprise suggestions
  static List<Map<String, dynamic>> _getFallbackSurpriseSuggestions() {
    return [
      {
        'name': 'Bold Mix & Match',
        'items': ['Colorful Top', 'Patterned Pants', 'Statement Shoes'],
        'tips': 'Don\'t be afraid to mix patterns and colors!',
        'reason':
            'Sometimes the best outfits come from unexpected combinations',
      },
      {
        'name': 'Vintage Vibes',
        'items': ['Retro Shirt', 'High-waisted Pants', 'Classic Sneakers'],
        'tips': 'Channel your inner vintage style',
        'reason': 'Vintage pieces add character to any outfit',
      },
      {
        'name': 'Athleisure Chic',
        'items': ['Sporty Top', 'Casual Pants', 'Sneakers'],
        'tips': 'Comfort meets style in this versatile look',
        'reason': 'Perfect for active days that still need to look good',
      },
    ];
  }

  // Generate seasonal outfit suggestions
  static Future<List<Map<String, dynamic>>> generateSeasonalOutfits({
    required String season,
    required List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final prompt = _buildSeasonalPrompt(season, closetItems, userProfile);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseOutfitResponse(response);
      }

      return _getFallbackSeasonalSuggestions(season);
    } catch (e) {
      // Error generating seasonal outfits: $e
      return _getFallbackSeasonalSuggestions(season);
    }
  }

  // Generate occasion-based outfit suggestions
  static Future<List<Map<String, dynamic>>> generateOccasionOutfits({
    required String occasion,
    required List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final prompt = _buildOccasionPrompt(occasion, closetItems, userProfile);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseOutfitResponse(response);
      }

      return _getFallbackOccasionSuggestions(occasion);
    } catch (e) {
      // Error generating occasion outfits: $e
      return _getFallbackOccasionSuggestions(occasion);
    }
  }

  // Build seasonal outfit prompt
  static String _buildSeasonalPrompt(
    String season,
    List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
  ) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    // Extract user profile information
    final demographics = userProfile?['demographics'] as Map<String, dynamic>?;
    final gender = demographics?['gender'] ?? 'not specified';
    final bodyType = demographics?['body_type'] ?? 'not specified';
    final stylePreferences =
        userProfile?['style_preferences'] as List<dynamic>?;
    final styleText = stylePreferences?.isNotEmpty == true
        ? stylePreferences!.join(', ')
        : 'not specified';

    return '''
You are a fashion AI assistant creating seasonal outfit suggestions.

User's closet contains: $itemsText

User Profile:
- Gender: $gender
- Body Type: $bodyType
- Style Preferences: $styleText

Season: $season

Please suggest 3 different outfit combinations perfect for $season weather and activities. Consider:
- Appropriate layering for $season temperatures
- Seasonal colors and fabrics
- $season-appropriate activities and occasions
- User's style preferences and body type

For each outfit, provide:
1. A creative name for the outfit
2. List of specific items to wear
3. Brief styling tips
4. Why this outfit works for $season

Format your response as a JSON array with this structure:
[
  {
    "name": "Outfit Name",
    "items": ["item1", "item2", "item3"],
    "tips": "Styling advice",
    "reason": "Why this works for $season"
  }
]

Make suggestions practical and achievable with their current wardrobe.
''';
  }

  // Build occasion outfit prompt
  static String _buildOccasionPrompt(
    String occasion,
    List<Map<String, dynamic>> closetItems,
    Map<String, dynamic>? userProfile,
  ) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    // Extract user profile information
    final demographics = userProfile?['demographics'] as Map<String, dynamic>?;
    final gender = demographics?['gender'] ?? 'not specified';
    final bodyType = demographics?['body_type'] ?? 'not specified';
    final stylePreferences =
        userProfile?['style_preferences'] as List<dynamic>?;
    final styleText = stylePreferences?.isNotEmpty == true
        ? stylePreferences!.join(', ')
        : 'not specified';

    return '''
You are a fashion AI assistant creating occasion-specific outfit suggestions.

User's closet contains: $itemsText

User Profile:
- Gender: $gender
- Body Type: $bodyType
- Style Preferences: $styleText

Occasion: $occasion

Please suggest 3 different outfit combinations perfect for $occasion. Consider:
- Appropriate formality level for $occasion
- Comfort and practicality for the event
- User's style preferences and body type
- Confidence-boosting combinations

For each outfit, provide:
1. A creative name for the outfit
2. List of specific items to wear
3. Brief styling tips
4. Why this outfit works for $occasion

Format your response as a JSON array with this structure:
[
  {
    "name": "Outfit Name",
    "items": ["item1", "item2", "item3"],
    "tips": "Styling advice",
    "reason": "Why this works for $occasion"
  }
]

Make suggestions practical and achievable with their current wardrobe.
''';
  }

  // Fallback seasonal suggestions
  static List<Map<String, dynamic>> _getFallbackSeasonalSuggestions(
    String season,
  ) {
    switch (season.toLowerCase()) {
      case 'summer':
        return [
          {
            'name': 'Summer Breeze',
            'items': ['Light T-shirt', 'Shorts', 'Sandals'],
            'tips': 'Keep it light and breezy for hot days',
            'reason': 'Perfect for warm summer weather',
          },
          {
            'name': 'Beach Ready',
            'items': ['Tank Top', 'Linen Pants', 'Flip Flops'],
            'tips': 'Comfortable and stylish for summer activities',
            'reason': 'Great for casual summer outings',
          },
          {
            'name': 'Summer Evening',
            'items': ['Light Dress', 'Cardigan', 'Flats'],
            'tips': 'Layer for cooler evening temperatures',
            'reason': 'Versatile for day-to-evening transitions',
          },
        ];
      case 'winter':
        return [
          {
            'name': 'Cozy Winter',
            'items': ['Sweater', 'Jeans', 'Boots'],
            'tips': 'Layer with a warm jacket for extra warmth',
            'reason': 'Classic winter comfort and style',
          },
          {
            'name': 'Winter Chic',
            'items': ['Turtleneck', 'Wool Pants', 'Ankle Boots'],
            'tips': 'Add a statement coat for extra style',
            'reason': 'Sophisticated winter look',
          },
          {
            'name': 'Snow Day',
            'items': ['Thermal Top', 'Fleece Pants', 'Snow Boots'],
            'tips': 'Perfect for snowy weather activities',
            'reason': 'Practical and warm for winter adventures',
          },
        ];
      default:
        return _getFallbackSuggestions();
    }
  }

  // Fallback occasion suggestions
  static List<Map<String, dynamic>> _getFallbackOccasionSuggestions(
    String occasion,
  ) {
    switch (occasion.toLowerCase()) {
      case 'work':
        return [
          {
            'name': 'Professional Classic',
            'items': ['Blouse', 'Trousers', 'Heels'],
            'tips': 'Keep accessories minimal and professional',
            'reason': 'Perfect for office environments',
          },
          {
            'name': 'Business Casual',
            'items': ['Button-up Shirt', 'Chinos', 'Loafers'],
            'tips': 'Comfortable yet polished for work',
            'reason': 'Great for casual office days',
          },
          {
            'name': 'Smart Professional',
            'items': ['Blazer', 'Dress', 'Pumps'],
            'tips': 'Add a statement necklace for personality',
            'reason': 'Ideal for important meetings',
          },
        ];
      case 'date-night':
        return [
          {
            'name': 'Romantic Evening',
            'items': ['Little Black Dress', 'Heels', 'Statement Jewelry'],
            'tips': 'Keep makeup elegant and accessories minimal',
            'reason': 'Classic and timeless for special evenings',
          },
          {
            'name': 'Casual Date',
            'items': ['Nice Top', 'Dark Jeans', 'Boots'],
            'tips': 'Add a leather jacket for extra style',
            'reason': 'Comfortable yet stylish for casual dates',
          },
          {
            'name': 'Dinner Date',
            'items': ['Silk Blouse', 'Midi Skirt', 'Heels'],
            'tips': 'Choose colors that complement your skin tone',
            'reason': 'Perfect for dinner and drinks',
          },
        ];
      case 'casual':
        return [
          {
            'name': 'Weekend Vibes',
            'items': ['Hoodie', 'Joggers', 'Sneakers'],
            'tips': 'Perfect for running errands or relaxing',
            'reason': 'Maximum comfort for casual days',
          },
          {
            'name': 'Coffee Shop',
            'items': ['Sweater', 'Jeans', 'Ankle Boots'],
            'tips': 'Add a scarf for extra style',
            'reason': 'Comfortable yet put-together',
          },
          {
            'name': 'Brunch Ready',
            'items': ['T-shirt', 'Midi Skirt', 'Flats'],
            'tips': 'Accessorize with a cute bag',
            'reason': 'Perfect for weekend brunch dates',
          },
        ];
      case 'party':
        return [
          {
            'name': 'Party Glam',
            'items': ['Sequin Top', 'Black Pants', 'Heels'],
            'tips': 'Add bold makeup and statement jewelry',
            'reason': 'Perfect for dancing and celebrating',
          },
          {
            'name': 'Cocktail Party',
            'items': ['Cocktail Dress', 'Heels', 'Clutch'],
            'tips': 'Keep accessories elegant and minimal',
            'reason': 'Ideal for sophisticated gatherings',
          },
          {
            'name': 'House Party',
            'items': ['Fun Top', 'Jeans', 'Boots'],
            'tips': 'Add a leather jacket for edge',
            'reason': 'Comfortable yet stylish for house parties',
          },
        ];
      default:
        return _getFallbackSuggestions();
    }
  }
}
