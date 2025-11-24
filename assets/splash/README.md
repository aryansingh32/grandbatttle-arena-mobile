# Splash Screen Directory

## Instructions

1. Place your splash screen logo here: `splash_logo.png`
2. Recommended size: **512x512 pixels**
3. Format: PNG (with transparency recommended)
4. This logo will be shown when the app starts

## After adding your splash logo:

1. Update `pubspec.yaml` if your logo has a different name
2. Run: `dart run flutter_native_splash:create`
3. Clean and rebuild: `flutter clean && flutter run`

## Customization

You can customize the splash screen background color in `pubspec.yaml`:
```yaml
flutter_native_splash:
  color: "#000000"  # Change to your brand color
```

