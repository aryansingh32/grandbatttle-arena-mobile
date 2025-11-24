# 🚀 Quick Start: Custom App Icon & Splash Screen

## ⚡ Quick Setup (5 Minutes)

### Step 1: Prepare Your Images

1. **App Icon** (1024x1024 PNG):
   - Create or resize your logo to 1024x1024 pixels
   - Save as: `assets/icon/app_icon.png`
   - **Tip:** Use a tool like [Canva](https://www.canva.com) or [Figma](https://www.figma.com) to create/resize

2. **Splash Logo** (512x512 PNG):
   - Create or resize your logo to 512x512 pixels  
   - Save as: `assets/splash/splash_logo.png`
   - **Tip:** Can be the same as app icon, just smaller

### Step 2: Customize Colors (Optional)

Edit `pubspec.yaml` and change these colors to match your brand:

```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#FFD700"  # Your brand color (e.g., gold)

flutter_native_splash:
  color: "#000000"  # Splash screen background color
  android_12:
    color: "#000000"  # Android 12+ background
```

### Step 3: Generate Icons & Splash

Run these commands:

```bash
# Install dependencies (if not done)
flutter pub get

# Generate app icons
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create

# Clean and rebuild
flutter clean
flutter run
```

### Step 4: Verify

- [ ] App icon appears on home screen
- [ ] App icon in app drawer
- [ ] Splash screen shows on launch
- [ ] Notification icon uses your icon

## 🎨 Using Your Existing Logo

If you want to use `garenalogo.png`:

1. Copy it to the icon directory:
   ```bash
   cp assets/images/garenalogo.png assets/icon/app_icon.png
   cp assets/images/garenalogo.png assets/splash/splash_logo.png
   ```

2. Resize if needed (should be 1024x1024 for icon, 512x512 for splash)

3. Run the generation commands above

## 📝 What Gets Updated

### App Icons:
- ✅ Home screen launcher icon
- ✅ App drawer icon
- ✅ App info/settings icon
- ✅ Notification icon
- ✅ All system icons

### Splash Screen:
- ✅ Android splash screen (all versions)
- ✅ iOS splash screen
- ✅ Background color
- ✅ Logo positioning

## 🔄 After Making Changes

If you update your icon or splash image:

1. Replace the image file
2. Run generation commands again
3. Clean and rebuild

---

**That's it!** Your custom icon and splash screen will be ready.

