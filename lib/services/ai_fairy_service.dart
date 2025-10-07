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
      print('Error generating outfit suggestions: $e');
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
      print('Error generating style advice: $e');
      return _getFallbackStyleAdvice();
    }
  }

  // Generate outfit suggestions based on a specific item
  static Future<List<Map<String, dynamic>>> generateItemBasedOutfits({
    required Map<String, dynamic> selectedItem,
    required List<Map<String, dynamic>> closetItems,
    String? occasion,
    String? weather,
    String? mood,
  }) async {
    try {
      final prompt = _buildItemBasedPrompt(
        selectedItem,
        closetItems,
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
      print('Error generating item-based outfit suggestions: $e');
      return _getFallbackItemBasedSuggestions(selectedItem);
    }
  }

  // Generate random surprise outfits
  static Future<List<Map<String, dynamic>>> generateSurpriseOutfits({
    required List<Map<String, dynamic>> closetItems,
  }) async {
    try {
      final prompt = _buildSurprisePrompt(closetItems);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseOutfitResponse(response);
      }

      return _getFallbackSurpriseSuggestions();
    } catch (e) {
      print('Error generating surprise outfits: $e');
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

    return '''
You are a fashion AI assistant helping create outfit suggestions based on a specific item.

User wants to wear: $selectedItemText

Their closet contains: $itemsText

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
  static String _buildSurprisePrompt(List<Map<String, dynamic>> closetItems) {
    final itemsText = closetItems
        .map((item) {
          return '${item['subcategory']} (${item['color']}, ${item['category']})';
        })
        .join(', ');

    return '''
You are a fashion AI assistant creating surprise outfit combinations.

User's closet contains: $itemsText

Create 3 completely random, creative, and unexpected outfit combinations from their wardrobe. Be bold and experimental! Mix different styles, colors, and categories in fun ways. For each outfit, provide:
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
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
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
      print('Error parsing outfit response: $e');
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
}
