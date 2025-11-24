#!/bin/bash

# Setup script for custom app icons and splash screen
# This script helps you set up your custom app icon and splash screen

echo "🎨 Custom App Icon & Splash Screen Setup"
echo "========================================"
echo ""

# Check if directories exist
if [ ! -d "assets/icon" ]; then
    mkdir -p assets/icon
    echo "✅ Created assets/icon directory"
fi

if [ ! -d "assets/splash" ]; then
    mkdir -p assets/splash
    echo "✅ Created assets/splash directory"
fi

# Check if garenalogo.png exists and offer to use it
if [ -f "assets/images/garenalogo.png" ]; then
    echo ""
    echo "📸 Found garenalogo.png in assets/images/"
    read -p "Do you want to use this as your app icon? (y/n): " use_existing
    
    if [ "$use_existing" = "y" ] || [ "$use_existing" = "Y" ]; then
        echo "📋 Copying garenalogo.png to icon and splash directories..."
        cp assets/images/garenalogo.png assets/icon/app_icon.png
        cp assets/images/garenalogo.png assets/splash/splash_logo.png
        echo "✅ Images copied!"
        echo ""
        echo "⚠️  IMPORTANT: Make sure your logo is:"
        echo "   - App icon: 1024x1024 pixels (will be auto-resized)"
        echo "   - Splash logo: 512x512 pixels (will be auto-resized)"
        echo ""
        read -p "Press Enter to continue with icon generation..."
    fi
fi

# Check if app_icon.png exists
if [ ! -f "assets/icon/app_icon.png" ]; then
    echo ""
    echo "❌ app_icon.png not found in assets/icon/"
    echo "📝 Please add your 1024x1024 app icon to: assets/icon/app_icon.png"
    echo ""
    read -p "Press Enter after adding your icon to continue..."
fi

# Check if splash_logo.png exists
if [ ! -f "assets/splash/splash_logo.png" ]; then
    echo ""
    echo "❌ splash_logo.png not found in assets/splash/"
    echo "📝 Please add your 512x512 splash logo to: assets/splash/splash_logo.png"
    echo ""
    read -p "Press Enter after adding your splash logo to continue..."
fi

# Generate icons
echo ""
echo "🔧 Generating app icons..."
flutter pub get
dart run flutter_launcher_icons

if [ $? -eq 0 ]; then
    echo "✅ App icons generated successfully!"
else
    echo "❌ Error generating app icons. Please check your configuration."
    exit 1
fi

# Generate splash screen
echo ""
echo "🎨 Generating splash screen..."
dart run flutter_native_splash:create

if [ $? -eq 0 ]; then
    echo "✅ Splash screen generated successfully!"
else
    echo "❌ Error generating splash screen. Please check your configuration."
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Run: flutter clean"
echo "   2. Run: flutter run"
echo "   3. Check your app icon on the home screen"
echo "   4. Check splash screen on app launch"
echo ""
echo "✨ Your custom icon and splash screen are ready!"

