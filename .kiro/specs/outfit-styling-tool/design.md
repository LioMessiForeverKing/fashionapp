# Closet Fairy - Design Document

## Overview

Closet Fairy v1 is a mobile-first Flutter application that helps users digitize their wardrobe and get AI-powered styling suggestions. The MVP focuses on the core user journey: upload clothing items, organize them in a digital closet, and receive outfit suggestions that primarily use existing pieces.

The app prioritizes simplicity and immediate value - users can quickly photograph their clothes and start getting styling help without complex setup or overwhelming features.

## Architecture

### Technology Stack
- **Frontend**: Flutter (cross-platform mobile)
- **Backend**: Supabase (PostgreSQL database, authentication, storage)
- **Authentication**: Google OAuth via Supabase Auth
- **Image Storage**: Supabase Storage with automatic optimization
- **AI/ML**: Integration with fashion AI APIs for background removal and style analysis

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │────│   Supabase      │────│  External APIs  │
│                 │    │                 │    │                 │
│ • UI/UX         │    │ • Database      │    │ • Background    │
│ • State Mgmt    │    │ • Auth          │    │   Removal       │
│ • Local Cache   │    │ • Storage       │    │ • Style AI      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Screen Designs and User Interface

### 1. Authentication Screen
```
┌─────────────────────────────────┐
│                                 │
│         ✨ Closet Fairy         │
│                                 │
│    Your personal style fairy    │
│      is here to help! 🧚‍♀️        │
│                                 │
│                                 │
│  ┌─────────────────────────────┐ │
│  │  📱 Continue with Google    │ │
│  └─────────────────────────────┘ │
│                                 │
│     Transform your closet       │
│     into endless outfits        │
│                                 │
└─────────────────────────────────┘
```

### 2. Onboarding Profile Setup
```
┌─────────────────────────────────┐
│  ← Back    Tell us about you    │
│                                 │
│  What's your style vibe? ✨     │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │Boho │ │Mini │ │Prep │       │
│  │ 🌸  │ │ 🖤  │ │ 👔  │       │
│  └─────┘ └─────┘ └─────┘       │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐       │
│  │Edgy │ │Roma │ │Casu │       │
│  │ ⚡  │ │ 🌹  │ │ 👕  │       │
│  └─────┘ └─────┘ └─────┘       │
│                                 │
│           ┌─────────┐           │
│           │Continue │           │
│           └─────────┘           │
└─────────────────────────────────┘
```

### 3. Main Navigation (Bottom Tabs)
```
┌─────────────────────────────────┐
│                                 │
│         Main Content            │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│─────────────────────────────────│
│ 💫    👗    📷    👤    ⚙️     │
│Inspo Closet Upload Profile Set │
└─────────────────────────────────┘
```

### 4. Inspiration Feed Screen
```
┌─────────────────────────────────┐
│ 💫 Inspiration      🔍 Search   │
│                                 │
│ ┌─────────────┐ ┌─────────────┐ │
│ │             │ │             │ │
│ │   Outfit    │ │   Outfit    │ │
│ │   Image     │ │   Image     │ │
│ │             │ │             │ │
│ │      ❤️      │ │      ❤️      │ │
│ └─────────────┘ └─────────────┘ │
│                                 │
│ ┌─────────────┐ ┌─────────────┐ │
│ │             │ │             │ │
│ │   Outfit    │ │   Outfit    │ │
│ │   Image     │ │   Image     │ │
│ │             │ │             │ │
│ │      ❤️      │ │      ❤️      │ │
│ └─────────────┘ └─────────────┘ │
└─────────────────────────────────┘
```

### 5. My Closet Screen
```
┌─────────────────────────────────┐
│ 👗 My Closet        🔍 ⚙️       │
│                                 │
│ All  Tops  Bottoms  Dresses     │
│ ●    ○     ○       ○            │
│                                 │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ │
│ │     │ │     │ │     │ │     │ │
│ │Item │ │Item │ │Item │ │Item │ │
│ │  1  │ │  2  │ │  3  │ │  4  │ │
│ └─────┘ └─────┘ └─────┘ └─────┘ │
│                                 │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ │
│ │     │ │     │ │     │ │     │ │
│ │Item │ │Item │ │Item │ │Item │ │
│ │  5  │ │  6  │ │  7  │ │  8  │ │
│ └─────┘ └─────┘ └─────┘ └─────┘ │
│                                 │
│              ┌─────────┐        │
│              │   +     │        │
│              │ Add Item│        │
│              └─────────┘        │
└─────────────────────────────────┘
```

### 6. Upload/Camera Screen
```
┌─────────────────────────────────┐
│ ← Back      📷 Add Item         │
│                                 │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │                             │ │
│ │        Camera Preview       │ │
│ │                             │ │
│ │     (Background removal     │ │
│ │      preview overlay)       │ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│     📁 Gallery    🔄 Flip       │
│                                 │
│              ┌─────┐            │
│              │  📷  │            │
│              │Capture│           │
│              └─────┘            │
└─────────────────────────────────┘
```

### 7. Item Details/Categorization Screen
```
┌─────────────────────────────────┐
│ ← Back      Save Item      ✓    │
│                                 │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │      Processed Image        │ │
│ │    (Background Removed)     │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│ Category: Tops ▼                │
│ ┌─────────────────────────────┐ │
│ │ Blouse                      │ │
│ └─────────────────────────────┘ │
│                                 │
│ Color: Black ▼                  │
│ Season: All Year ▼              │
│                                 │
│ Tags: #work #casual #favorite   │
│                                 │
│              ┌─────────┐        │
│              │  Save   │        │
│              └─────────┘        │
└─────────────────────────────────┘
```

### 8. Item Detail View (from closet)
```
┌─────────────────────────────────┐
│ ← Back      Black Skirt    ⋯    │
│                                 │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │                             │ │
│ │        Item Image           │ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│ Long Black Skirt                │
│ Added: 2 days ago               │
│ Worn: 3 times                   │
│                                 │
│ ┌─────────────────────────────┐ │
│ │     ✨ Style This Piece     │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │      📝 Edit Details        │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 9. Outfit Suggestions Screen
```
┌─────────────────────────────────┐
│ ← Back    Outfit Ideas     ⚙️    │
│                                 │
│ Styling your: Black Skirt       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  ┌─────┐ ┌─────┐ ┌─────┐   │ │
│ │  │White│ │Black│ │Brown│   │ │
│ │  │Blous│ │Skirt│ │Boot │   │ │
│ │  └─────┘ └─────┘ └─────┘   │ │
│ │                             │ │
│ │ "Classic and elegant for    │ │
│ │  work or dinner"            │ │
│ │                             │ │
│ │        ❤️  💾  👗           │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │  ┌─────┐ ┌─────┐ ┌─────┐   │ │
│ │  │Crop │ │Black│ │Sneak│   │ │
│ │  │ Top │ │Skirt│ │ ers │   │ │
│ │  └─────┘ └─────┘ └─────┘   │ │
│ │                             │ │
│ │ "Casual boho vibe perfect   │ │
│ │  for weekend brunch"        │ │
│ │                             │ │
│ │        ❤️  💾  👗           │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 10. Profile Screen
```
┌─────────────────────────────────┐
│          👤 Profile             │
│                                 │
│      ┌─────────────────┐        │
│      │   Profile Pic   │        │
│      │                 │        │
│      └─────────────────┘        │
│                                 │
│         [User Name]             │
│      [user@email.com]           │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 👗 My Style Preferences     │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 📊 My Closet Stats          │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 💝 Saved Outfits            │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ⚙️  Settings                │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## Components and Interfaces

### Core Components

#### 1. Authentication Component
- Google OAuth integration via Supabase Auth
- Session management and token refresh
- User profile creation and updates

#### 2. Camera Component
- Native camera integration
- Real-time background removal preview
- Image capture and processing
- Gallery selection option

#### 3. Closet Management Component
- Grid view of clothing items
- Category filtering and search
- Item detail views
- CRUD operations for clothing items

#### 4. AI Styling Component
- Outfit generation algorithms
- Style matching logic
- Recommendation explanations
- User preference learning

#### 5. Image Processing Component
- Background removal integration
- Image optimization and compression
- Thumbnail generation
- Cloud storage management

### Data Models

#### User Model
```dart
class User {
  String id;
  String email;
  String name;
  String? profileImageUrl;
  List<String> stylePreferences;
  Map<String, dynamic> demographics;
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### ClothingItem Model
```dart
class ClothingItem {
  String id;
  String userId;
  String imageUrl;
  String category; // tops, bottoms, dresses, shoes, accessories
  String subcategory; // blouse, jeans, sneakers, etc.
  String color;
  List<String> tags;
  String season; // all-year, spring, summer, fall, winter
  int timesWorn;
  DateTime createdAt;
  DateTime lastWorn;
}
```

#### Outfit Model
```dart
class Outfit {
  String id;
  String userId;
  List<String> clothingItemIds;
  String? inspirationImageUrl;
  String occasion;
  String description;
  bool isFavorite;
  DateTime createdAt;
}
```

#### Inspiration Model
```dart
class Inspiration {
  String id;
  String userId;
  String imageUrl;
  List<String> styleKeywords;
  String source;
  bool isSaved;
  DateTime createdAt;
}
```

## Error Handling

### Network Errors
- Offline mode for viewing saved content
- Retry mechanisms for failed uploads
- User-friendly error messages
- Graceful degradation of features

### Image Processing Errors
- Fallback for background removal failures
- Manual cropping options
- Quality validation and feedback
- Storage error recovery

### Authentication Errors
- Clear sign-in error messages
- Session expiry handling
- Account recovery options
- Privacy and security notifications

## Testing Strategy

### Unit Testing
- Data model validation
- Business logic components
- Image processing utilities
- API integration functions

### Widget Testing
- UI component behavior
- User interaction flows
- State management validation
- Navigation testing

### Integration Testing
- End-to-end user journeys
- Database operations
- Authentication flows
- Image upload and processing

## User Flow Diagram

### Primary User Journey (MVP)

```
Start App
    ↓
[First Time User?] ──Yes──→ Google Sign-In ──→ Profile Setup ──→ Onboarding Tutorial
    ↓ No                                                              ↓
Main App (Inspiration Feed)                                          ↓
    ↓                                                               ↓
[User Action Choice] ←──────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ A) Browse Inspiration  B) View Closet  C) Upload Item  D) Profile│
└─────────────────────────────────────────────────────────────────┘
    ↓                    ↓               ↓                ↓
A) Inspiration Feed → Save Inspiration → View Saved Items
    ↓
B) My Closet → Select Item → Style This Piece → View Outfit Suggestions → Save/Share Outfit
    ↓
C) Upload Item → Camera/Gallery → Background Removal → Categorize → Save to Closet
    ↓
D) Profile → View Stats → Edit Preferences → Settings

### Detailed Upload Flow
Upload Item
    ↓
Open Camera Interface
    ↓
[Take Photo or Select from Gallery]
    ↓
AI Background Removal Processing
    ↓
Preview Processed Image
    ↓
[Accept Image?] ──No──→ Retake Photo
    ↓ Yes
Categorization Screen
    ↓
Select Category (Auto-suggested)
    ↓
Add Color, Season, Tags
    ↓
Save to Closet
    ↓
Success Message + "Style This Piece?" Option

### Detailed Styling Flow
Select Item from Closet
    ↓
Tap "Style This Piece"
    ↓
AI Generates Outfit Suggestions
    ↓
Display 3-5 Outfit Options with Explanations
    ↓
[User Action on Outfit]
    ↓
┌─────────────────────────────────────────┐
│ A) Save Outfit  B) Share  C) Try Another│
└─────────────────────────────────────────┘
    ↓              ↓         ↓
A) Save to Profile → Success Message
    ↓
B) Share Options → Social/Export
    ↓
C) Generate More Suggestions → Return to Suggestions
```

### Key User Scenarios

**Scenario 1: New User Onboarding**
1. Download app → Google Sign-In → Profile setup (2 minutes)
2. Upload first 3-5 clothing items (5 minutes)
3. Get first styling suggestion → Save favorite outfit
4. Total time to value: ~7 minutes

**Scenario 2: Daily Styling Help**
1. Open app → Go to Closet
2. Select item they want to wear
3. View styling suggestions
4. Choose outfit and get dressed
5. Total time: ~2 minutes

**Scenario 3: Inspiration-Driven Styling**
1. Browse inspiration feed
2. Save inspiring look
3. Get suggestions to recreate with owned items
4. Discover new ways to style existing pieces
5. Total time: ~3-5 minutes

## Simple User Flow Diagram

```
App Launch → Google Sign-In → Profile Setup → Main App
                                                ↓
                                    ┌─────────────────┐
                                    │  Bottom Tabs    │
                                    └─────────────────┘
                                            ↓
        ┌─────────────┬─────────────┬─────────────┬─────────────┐
        ↓             ↓             ↓             ↓             ↓
   Inspiration    My Closet      Upload       Profile      Settings
        ↓             ↓             ↓             ↓             ↓
   Browse Feed → Select Item → Take Photo → View Stats → Edit Prefs
        ↓             ↓             ↓
   Save Inspo → Style This → Categorize
                    ↓             ↓
            Outfit Suggestions → Save Item
                    ↓
               Save Outfit
```