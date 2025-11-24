# 🎨 Custom App Icon & Splash Screen Setup Guide

## 📋 Prerequisites

1. **Your App Icon Image:**
   - Format: PNG (recommended) or JPG
   - Size: **1024x1024 pixels** (square)
   - Background: Transparent or solid color
   - File name: `app_icon.png`
   - Location: `assets/icon/app_icon.png`

2. **Your Splash Screen Logo:**
   - Format: PNG (recommended)
   - Size: **512x512 pixels** (square, will be centered)
   - Background: Transparent (recommended)
   - File name: `splash_logo.png`
   - Location: `assets/splash/splash_logo.png`

## 🚀 Step-by-Step Setup

### Step 1: Create Required Directories

```bash
mkdir -p assets/icon
mkdir -p assets/splash
```

### Step 2: Add Your Images

1. **App Icon:**
   - Copy your 1024x1024 icon to: `assets/icon/app_icon.png`
   - This will be used for:
     - App launcher icon (home screen)
     - App info icon
     - Notification icon
     - All app icons everywhere

2. **Splash Screen Logo:**
   - Copy your 512x512 logo to: `assets/splash/splash_logo.png`
   - This will be shown when app starts

### Step 3: Update pubspec.yaml Configuration

The configuration is already added to `pubspec.yaml`. You just need to:

1. **Update icon path** (if different):
   ```yaml
   flutter_launcher_icons:
     image_path: "assets/icon/app_icon.png"  # Your icon path
   ```

2. **Update splash screen path** (if different):
   ```yaml
   flutter_native_splash:
     image: assets/splash/splash_logo.png  # Your splash logo path
   ```

3. **Customize colors** (optional):
   ```yaml
   flutter_launcher_icons:
     adaptive_icon_background: "#FFD700"  # Your brand color
   
   flutter_native_splash:
     color: "#000000"  # Splash screen background color
   ```

### Step 4: Install Dependencies

```bash
flutter pub get
```

### Step 5: Generate App Icons

```bash
dart run flutter_launcher_icons
```

This will:
- Generate icons for all Android densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Generate iOS app icons
- Update notification icons
- Create adaptive icons for Android

### Step 6: Generate Splash Screen

```bash
dart run flutter_native_splash:create
```

This will:
- Create Android splash screen
- Create iOS splash screen
- Update native configuration files

### Step 7: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

## 🎨 Customization Options

### App Icon Colors

Edit in `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#FFD700"  # Background color for adaptive icon
  adaptive_icon_foreground: "assets/icon/app_icon.png"  # Foreground icon
```

### Splash Screen Colors

Edit in `pubspec.yaml`:
```yaml
flutter_native_splash:
  color: "#000000"  # Background color
  android_12:
    color: "#000000"  # Android 12+ background
    icon_background_color: "#000000"  # Icon background
```

### Splash Screen Position

```yaml
flutter_native_splash:
  android_gravity: center  # Options: center, top, bottom, left, right, etc.
  ios_content_mode: center  # Options: center, scaleAspectFit, scaleAspectFill
```

## 📱 Platform-Specific Notes

### Android
- Icons are generated in: `android/app/src/main/res/mipmap-*/`
- Splash screen: `android/app/src/main/res/drawable/launch_background.xml`
- Adaptive icons supported (Android 8.0+)

### iOS
- Icons are generated in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Splash screen: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

## 🔄 Regenerating Icons/Splash

If you change your icon or splash image:

1. Replace the image file
2. Run the generation command again:
   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter run
   ```

## 🗑️ Removing Splash Screen

To remove the splash screen:
```bash
dart run flutter_native_splash:remove
```

## ✅ Verification Checklist

After setup, verify:

- [ ] App icon appears correctly on home screen
- [ ] App icon appears in app drawer
- [ ] App icon appears in app info/settings
- [ ] Splash screen shows on app launch
- [ ] Splash screen logo is centered and visible
- [ ] Notification icon uses your custom icon
- [ ] Icons look good on different screen densities

## 🐛 Troubleshooting

### Icons not updating?
1. Run `flutter clean`
2. Delete `build/` folder
3. Regenerate icons
4. Rebuild app

### Splash screen not showing?
1. Check image path in `pubspec.yaml`
2. Verify image exists at specified path
3. Run `dart run flutter_native_splash:create` again
4. Clean and rebuild

### Icon looks blurry?
- Ensure source image is 1024x1024 pixels
- Use PNG format (not JPG)
- Avoid compression artifacts

### Splash screen too small/large?
- Adjust `ios_content_mode` or `android_gravity`
- Try different image sizes (512x512 recommended)

---

**Need Help?** Check the package documentation:
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)

