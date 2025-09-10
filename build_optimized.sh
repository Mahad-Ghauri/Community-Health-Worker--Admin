#!/bin/bash

# Flutter Build Script with Minification and Obfuscation
# This script builds optimized Android APK and AAB files

echo "🚀 Building Flutter App with Minification and Obfuscation..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build APK with optimization flags
echo "📱 Building optimized APK..."
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --target-platform android-arm64 \
  --shrink

# Build AAB (Android App Bundle) for Play Store
echo "📦 Building optimized AAB for Play Store..."
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --target-platform android-arm64

# Build multi-architecture APK
echo "🔧 Building multi-architecture APK..."
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi

echo "✅ Build completed successfully!"
echo ""
echo "📍 Output files:"
echo "   - APK: build/app/outputs/flutter-apk/app-release.apk"
echo "   - AAB: build/app/outputs/bundle/release/app-release.aab"
echo "   - Split APKs: build/app/outputs/flutter-apk/app-*-release.apk"
echo "   - Debug symbols: build/app/outputs/symbols/"
echo ""
echo "💡 Tips:"
echo "   - Use AAB for Play Store uploads"
echo "   - Keep debug symbols for crash reporting"
echo "   - Test the release build thoroughly before publishing"
