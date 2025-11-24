# 🎨 Complete Guide: Custom App Icon & Splash Screen

## ✅ What's Been Set Up

I've configured your Flutter app to use custom app icons and splash screens. Here's what's ready:

### 📦 Packages Installed
- ✅ `flutter_launcher_icons` - Generates app icons for all platforms
- ✅ `flutter_native_splash` - Creates native splash screens

### 📁 Directories Created
- ✅ `assets/icon/` - For your app icon
- ✅ `assets/splash/` - For your splash screen logo

### ⚙️ Configuration Added
- ✅ App icon configuration in `pubspec.yaml`
- ✅ Splash screen configuration in `pubspec.yaml`

## 🚀 Quick Start (3 Steps)

### Step 1: Add Your Images

**App Icon:**
- Place your logo at: `assets/icon/app_icon.png`
- Size: **1024x1024 pixels** (PNG recommended)
- This will be used everywhere (home screen, app info, notifications, etc.)

**Splash Logo:**
- Place your logo at: `assets/splash/splash_logo.png`
- Size: **512x512 pixels** (PNG recommended)
- This appears when the app starts

### Step 2: Generate Icons & Splash

**Option A: Use the Setup Script (Easiest)**
```bash
./setup_icons.sh
```

**Option B: Manual Commands**
```bash
# Generate app icons
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create
```

### Step 3: Clean & Rebuild

```bash
flutter clean
flutter run
```

## 🎨 Customization

### Change Colors

Edit `pubspec.yaml`:

**App Icon Background (Android Adaptive Icon):**
```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#FFD700"  # Your brand color
```

**Splash Screen Background:**
```yaml
flutter_native_splash:
  color: "#000000"  # Splash background color
  android_12:
    color: "#000000"  # Android 12+ background
```

### Change Image Paths

If your images have different names or locations:

```yaml
flutter_launcher_icons:
  image_path: "assets/icon/your_icon.png"  # Your path

flutter_native_splash:
  image: assets/splash/your_logo.png  # Your path
```

## 📱 What Gets Updated

### App Icons (All Platforms)
- ✅ **Home Screen** - Launcher icon
- ✅ **App Drawer** - App list icon
- ✅ **App Info** - Settings/About icon
- ✅ **Notifications** - Notification icon
- ✅ **Recent Apps** - Recent apps switcher
- ✅ **System UI** - All system icons

### Splash Screen
- ✅ **Android** - All versions (including Android 12+)
- ✅ **iOS** - Launch screen
- ✅ **Background Color** - Customizable
- ✅ **Logo Position** - Centered by default

## 🔍 Where Icons Appear

1. **Home Screen** - The icon you tap to open the app
2. **App Drawer** - In the list of all apps
3. **App Info** - Settings > Apps > Your App
4. **Notifications** - Top left corner of notifications
5. **Recent Apps** - When you switch between apps
6. **Background** - Top left when app is in background (Android)

## 🛠️ Using Your Existing Logo

If you want to use `garenalogo.png`:

```bash
# Copy to icon directory
cp assets/images/garenalogo.png assets/icon/app_icon.png

# Copy to splash directory  
cp assets/images/garenalogo.png assets/splash/splash_logo.png

# Generate icons
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Clean and rebuild
flutter clean
flutter run
```

## 📋 Image Requirements

### App Icon
- **Format:** PNG (recommended) or JPG
- **Size:** 1024x1024 pixels (square)
- **Background:** Transparent or solid color
- **Note:** Will be auto-resized for different densities

### Splash Logo
- **Format:** PNG (recommended)
- **Size:** 512x512 pixels (square)
- **Background:** Transparent (recommended)
- **Note:** Will be centered on splash screen

## 🔄 Updating Icons/Splash

If you change your icon or splash image:

1. Replace the image file
2. Run generation commands:
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

To remove the custom splash screen:

```bash
dart run flutter_native_splash:remove
```

## ✅ Verification Checklist

After setup, check:

- [ ] App icon appears on home screen (not Flutter default)
- [ ] App icon in app drawer
- [ ] App icon in app info/settings
- [ ] Splash screen shows on app launch
- [ ] Splash screen logo is visible and centered
- [ ] Notification icon uses your custom icon
- [ ] Icons look good on different screen sizes

## 🐛 Troubleshooting

### Icons Not Updating?

1. **Clean build:**
   ```bash
   flutter clean
   rm -rf build/
   ```

2. **Regenerate icons:**
   ```bash
   dart run flutter_launcher_icons
   ```

3. **Rebuild:**
   ```bash
   flutter run
   ```

4. **Uninstall and reinstall app** (sometimes needed)

### Splash Screen Not Showing?

1. Check image path in `pubspec.yaml`
2. Verify image exists at specified path
3. Regenerate splash:
   ```bash
   dart run flutter_native_splash:create
   ```
4. Clean and rebuild

### Icon Looks Blurry?

- Ensure source image is 1024x1024 pixels
- Use PNG format (not JPG)
- Avoid compression artifacts
- Use high-quality source image

### Wrong Colors?

- Update colors in `pubspec.yaml`
- Regenerate icons/splash
- Clean and rebuild

## 📚 Additional Resources

- [flutter_launcher_icons Documentation](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_native_splash Documentation](https://pub.dev/packages/flutter_native_splash)

## 🎯 Quick Reference Commands

```bash
# Generate app icons
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create

# Remove splash screen
dart run flutter_native_splash:remove

# Clean and rebuild
flutter clean && flutter run
```

---

**Ready to go!** Just add your images and run the generation commands. 🚀

