#!/bin/bash

# DailyGrowth Mobile Build Script
# Ensures proper environment variable configuration for mobile platforms

set -e

echo "🚀 Building DailyGrowth Mobile App"
echo "=================================="

# Check if env.json exists
if [ ! -f "env.json" ]; then
    echo "❌ Error: env.json file not found!"
    echo "Please create env.json with your Supabase credentials"
    exit 1
fi

# Extract environment variables from env.json
SUPABASE_URL=$(grep -o '"SUPABASE_URL"[^,]*' env.json | grep -o '[^"]*$' | head -1)
SUPABASE_ANON_KEY=$(grep -o '"SUPABASE_ANON_KEY"[^,]*' env.json | grep -o '[^"]*$' | head -1)

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Missing Supabase credentials in env.json"
    exit 1
fi

echo "✅ Environment variables loaded"
echo "📍 Supabase URL: ${SUPABASE_URL:0:30}..."
echo "🔑 Supabase Key: ${SUPABASE_ANON_KEY:0:10}..."

# Build commands with environment variables
DART_DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

case "$1" in
    "android")
        echo "🤖 Building for Android..."
        flutter build apk $DART_DEFINES --release
        echo "✅ Android APK built successfully!"
        echo "📦 Location: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    "ios")
        echo "🍎 Building for iOS..."
        flutter build ios $DART_DEFINES --release
        echo "✅ iOS build completed successfully!"
        ;;
    "run-android")
        echo "🤖 Running on Android device..."
        flutter run $DART_DEFINES --release
        ;;
    "run-ios")
        echo "🍎 Running on iOS device..."
        flutter run $DART_DEFINES --release
        ;;
    "debug-android")
        echo "🐛 Running Android in debug mode..."
        flutter run $DART_DEFINES --debug
        ;;
    "debug-ios")
        echo "🐛 Running iOS in debug mode..."
        flutter run $DART_DEFINES --debug
        ;;
    *)
        echo "Usage: $0 {android|ios|run-android|run-ios|debug-android|debug-ios}"
        echo ""
        echo "Examples:"
        echo "  $0 android          # Build Android APK"
        echo "  $0 ios              # Build iOS app"
        echo "  $0 run-android      # Run on Android device"
        echo "  $0 debug-android    # Debug on Android device"
        exit 1
        ;;
esac

echo "🎉 Build completed successfully!"
