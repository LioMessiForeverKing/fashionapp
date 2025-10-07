#!/bin/bash

# Closet Fairy - TestFlight Build Script
# This script prepares the app for TestFlight submission

echo "🧚‍♀️ Preparing Closet Fairy for TestFlight submission..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Update pods
echo "📦 Updating iOS dependencies..."
cd ios
pod install --repo-update
cd ..

# Build iOS app for release
echo "🏗️ Building iOS app for release..."
flutter build ios --release --no-codesign

echo "✅ Build completed successfully!"
echo ""
echo "📱 Next steps for TestFlight submission:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select 'Any iOS Device (arm64)' as the target"
echo "3. Go to Product > Archive"
echo "4. Once archived, click 'Distribute App'"
echo "5. Select 'App Store Connect'"
echo "6. Follow the prompts to upload to TestFlight"
echo ""
echo "🎉 Your Closet Fairy app is ready for TestFlight!"
