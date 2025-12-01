# IronLog Changelog

All notable changes to the IronLog gym tracking app.

---

## [1.0.0] - December 2025 - CURRENT VERSION

### 🎉 Initial Release - Feature Complete

#### Core Features
- ✅ Complete workout tracking system
- ✅ Exercise library with 100+ pre-seeded exercises
- ✅ Workout templates and history
- ✅ Personal record tracking (4 PR types)
- ✅ Progress tracking (body measurements, photos, weight)
- ✅ Workout calendar and scheduling
- ✅ Rest timer with auto-start

#### Recent Additions (Pre-Release)
- ✅ **Drop Sets Support** - Mark and track drop sets
- ✅ **Superset Support** - Visual grouping and management
- ✅ **Advanced Weight Input** - +/- buttons, comma support, smart formatting
- ✅ **Improved Active Workout UI** - Save button, cancel confirmation
- ✅ **Goal Setting** - Set and track lift targets
- ✅ **Progress Photos** - Camera/gallery with multiple photo types
- ✅ **Exercise Instructions** - View and edit form tips

#### Bug Fixes
- 🐛 Fixed TextField controller recreation causing cursor jumps
- 🐛 Fixed navigation "nothing to pop" error
- 🐛 Fixed database migration order (tables before indexes)
- 🐛 Fixed undefined AppColors.border errors
- 🐛 Fixed weight input behaving incorrectly (2010 → 2.0 issue)
- 🐛 Removed unused imports and variables

#### Code Quality
- 🔧 Improved TextField management with StatefulWidgets
- 🔧 Removed unused code and variables
- 🔧 Fixed all compilation errors
- 🔧 Cleaned up warnings

---

## [Unreleased] - Version 1.1 Planning

### Planned Features
See [VERSION_1.1.md](VERSION_1.1.md) for detailed roadmap.

**High Priority:**
- Exercise videos/images for form guidance
- Dark/Light theme toggle
- Data import functionality

**Medium Priority:**
- Workout reminders/notifications
- CSV export
- Share workouts

**Low Priority:**
- Muscle recovery tracking
- Achievements/badges
- Advanced analytics

---

## Version History

### v1.0.0 (December 2025) - CURRENT
- Initial release
- All core features complete
- Production ready

### Future Versions
- v1.1.0 - Planned Q1 2026
- v2.0.0 - Cloud sync (TBD)

---

## Feature Status

### ✅ Completed (v1.0)
- Workout tracking (sets, reps, weight, drop sets, supersets)
- Exercise library with search and filters
- Templates system
- Workout history
- Personal records (automatic detection)
- Body tracking (weight, measurements, photos)
- Workout calendar and scheduling
- Rest day tracking
- Rest timer with auto-start
- Goal/target setting
- Statistics and analytics
- Data export (JSON)

### 📋 Planned (v1.1)
- Exercise videos/images
- Theme toggle
- Data import
- Workout reminders
- CSV export
- Share functionality

### 🔮 Future Considerations
- Cloud sync
- Social features
- Advanced AI insights
- Wearable integration

---

## Database Schema Version

**Current**: v1
- Supports all v1.0 features
- Migration system in place
- Compatible with future versions

---

## Platform Support

**Current Platforms:**
- ✅ Android
- ✅ Linux Desktop
- ⏳ iOS (buildable but untested)
- ⏳ Windows Desktop (buildable but untested)
- ⏳ macOS (buildable but untested)

---

## Known Issues

**None** - All critical issues resolved for v1.0 release

**Minor/Cosmetic:**
- Some linting warnings (prefer_const, etc.) - non-blocking
- Test file outdated (widget_test.dart) - doesn't affect app

---

## Contributing

For bug reports or feature requests, please create an issue with:
1. Clear description
2. Steps to reproduce (for bugs)
3. Expected vs actual behavior
4. Device/platform information

---

**Maintained by**: IronLog Development Team
**License**: [Your License Here]
**Repository**: [Your Repo URL Here]

---

_Last Updated: December 2025_
