import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Create basic user record when they first sign in
  static Future<void> createBasicUserRecord() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if user already exists
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // Create basic user record
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? user.email?.split('@').first,
          'profile_image_url': user.userMetadata?['avatar_url'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        // User record created successfully
      }
    } catch (e) {
      // Error creating basic user record: $e
      // Don't throw here as this is not critical for auth flow
    }
  }

  // Create or update user profile
  static Future<void> createOrUpdateUserProfile({
    required List<String> stylePreferences,
    required String ageRange,
    required String bodyType,
    required List<String> favoriteColors,
    required String lifestyle,
    required String gender,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Ensure basic user record exists first
      await createBasicUserRecord();

      // Prepare the data
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ?? user.email?.split('@').first,
        'profile_image_url': user.userMetadata?['avatar_url'],
        'style_preferences': stylePreferences,
        'demographics': {
          'age_range': ageRange,
          'body_type': bodyType,
          'lifestyle': lifestyle,
          'gender': gender,
        },
        'color_preferences': {
          'favorite_colors': favoriteColors,
          'avoid_colors': <String>[], // Empty for now
          'palette_preference': 'mixed', // Default value
        },
        'budget_preferences': {
          'tops': 100,
          'bottoms': 100,
          'dresses': 150,
          'shoes': 200,
          'accessories': 50,
        },
        'shopping_frequency': 'moderate',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert or update user profile
      await _supabase.from('users').upsert(userData, onConflict: 'id');

      // User profile updated successfully
    } catch (e) {
      // Error updating user profile: $e
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      // Error fetching user profile: $e
      return null;
    }
  }

  // Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final profile = await getUserProfile();
      if (profile == null) return false;

      // Check if required fields are populated
      final demographics = profile['demographics'] as Map<String, dynamic>?;
      final stylePreferences = profile['style_preferences'] as List<dynamic>?;
      final colorPreferences =
          profile['color_preferences'] as Map<String, dynamic>?;

      return demographics != null &&
          demographics.isNotEmpty &&
          stylePreferences != null &&
          stylePreferences.isNotEmpty &&
          colorPreferences != null &&
          colorPreferences.isNotEmpty;
    } catch (e) {
      // Error checking onboarding status: $e
      return false;
    }
  }

  // Update specific user preferences
  static Future<void> updateUserPreferences({
    List<String>? stylePreferences,
    Map<String, dynamic>? demographics,
    Map<String, dynamic>? colorPreferences,
    Map<String, dynamic>? budgetPreferences,
    String? shoppingFrequency,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (stylePreferences != null) {
        updateData['style_preferences'] = stylePreferences;
      }
      if (demographics != null) {
        updateData['demographics'] = demographics;
      }
      if (colorPreferences != null) {
        updateData['color_preferences'] = colorPreferences;
      }
      if (budgetPreferences != null) {
        updateData['budget_preferences'] = budgetPreferences;
      }
      if (shoppingFrequency != null) {
        updateData['shopping_frequency'] = shoppingFrequency;
      }

      await _supabase.from('users').update(updateData).eq('id', user.id);

      // User preferences updated successfully
    } catch (e) {
      // Error updating user preferences: $e
      throw Exception('Failed to update user preferences: $e');
    }
  }

  // Log user activity
  static Future<void> logActivity({
    required String activityType,
    Map<String, dynamic>? activityData,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _supabase.from('user_activities').insert({
        'user_id': user.id,
        'activity_type': activityType,
        'activity_data': activityData ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Error logging activity: $e
      // Don't throw here as this is not critical
    }
  }
}
