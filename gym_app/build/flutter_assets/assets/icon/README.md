# IronLog App Icons

This directory contains the app icons and splash screen for IronLog.

## Quick Setup

Run the icon generator script to create placeholder icons:

```bash
python3 generate_icons.py
```

Then generate the app icons:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## Custom Icons

To use custom icons:

1. Replace `icon.png` with your 1024x1024px app icon
2. Replace `icon_foreground.png` with your 1024x1024px foreground icon (for Android adaptive icon)
3. Replace `splash.png` with your 512x512px splash screen icon
4. Run the generation commands above

## Design Guidelines

**App Icon:**
- Size: 1024x1024px
- Format: PNG with transparency
- Theme: Dark background with orange/red accent
- Symbol: Dumbbell or barbell icon

**Splash Screen:**
- Size: 512x512px
- Format: PNG with transparency
- Background color: #1a1a1a (set in pubspec.yaml)
- Should match the app icon design

## Colors

- Background: #1a1a1a (dark gray)
- Primary: #ff6b35 (orange-red)
- Surface: #2d2d2d
