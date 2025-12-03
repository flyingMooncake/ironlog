# IronLog - Free Gym Tracker

**Offline-first gym tracking app. No ads. No subscriptions. Ever.**

## Project Structure

This repository contains:
- `gym_app/` - The Flutter application
- `.github/workflows/` - GitHub Actions for iOS builds
- `.gitignore` - Git ignore rules

## Getting Started

Navigate to the gym_app directory:

```bash
cd gym_app
flutter pub get
flutter run
```

## Features

- Track workouts with weight, reps, sets
- 150+ pre-loaded exercises
- Exercise library with search and filters
- Workout templates with groups
- Workout history
- Progress tracking
- Personal records
- Body measurements
- Progress photos
- Dark mode UI

## Tech Stack

- Flutter 3.19+
- SQLite (offline-first)
- Riverpod for state management
- go_router for navigation
- fl_chart for progress graphs

## Build Instructions

### Android
```bash
cd gym_app
flutter build apk --release
```

### iOS
See [gym_app/BUILD_IOS_INSTRUCTIONS.md](gym_app/BUILD_IOS_INSTRUCTIONS.md) for detailed instructions on building iOS without a Mac using GitHub Actions.

## License

Built with Flutter. Runs completely offline.

