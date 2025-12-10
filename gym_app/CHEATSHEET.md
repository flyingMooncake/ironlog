# IronLog Gym App - Developer Cheatsheet

Quick reference guide for navigating the codebase and finding components fast.

---

## 🗂️ PROJECT STRUCTURE

```
lib/
├── models/              # Data models (13 total)
├── repositories/        # Database access layer (CRUD operations)
├── providers/           # Riverpod state management
├── services/            # Business logic (export, haptics, favorites)
├── screens/             # UI screens
│   ├── profile/
│   ├── templates/
│   ├── history/
│   ├── workout/
│   ├── exercises/
│   └── home/
├── core/
│   ├── database/        # DB schema & helper
│   ├── theme/           # Colors & styling
│   ├── utils/           # Helper functions
│   └── router/          # GoRouter config
└── widgets/             # Reusable components
```

---

## 🎯 QUICK NAVIGATION MAP

### 🏋️ WORKOUT TEMPLATES
**Main Screen**: `lib/screens/templates/templates_screen.dart`
- Line 1005-1161: Duplicate template logic (with group selector)
- Line 1175-1264: Share group (natural language)
- Line 1266-1324: Export group (JSON)
- Line 610-760: Create template dialog

**Editor**: `lib/screens/templates/template_editor_screen.dart`

**Models**:
- `lib/models/workout_template.dart` - WorkoutTemplate & TemplateExercise
- `lib/models/template_group.dart` - TemplateGroup

**Repository**: `lib/repositories/template_repository.dart`
- Line 12-32: `createTemplate()` - Creates template + exercises
- Line 82-110: `updateTemplate()` - Updates template
- Line 113-120: `deleteTemplate()`

**Provider**: `lib/providers/template_provider.dart`

---

### 👤 USER PROFILE
**Screen**: `lib/screens/profile/profile_screen.dart`
- Line 121-153: Personal info card (weight, height, age, BFP%)
- Line 222-283: Settings card
- Line 387-439: Unit system dialog
- Line 441-516: Rest timer dialog
- Line 530-588: `_saveProfile()` method

**Model**: `lib/models/user_profile.dart`
- Fields: id, weight, height, age, bfpPercentage, unitSystem, restTimerDefault, autoStartRestTimer

**Repository**: `lib/repositories/user_repository.dart`
- Line 9-15: `getUserProfile()`
- Line 18-40: `saveUserProfile()`
- Line 59-72: `updateUnitSystem()`
- Line 74-87: `updateRestTimer()`

**Provider**: `lib/providers/user_provider.dart`

---

### 📊 WORKOUT HISTORY
**Detail Screen**: `lib/screens/history/workout_detail_screen.dart`
- Line 29-123: `_shareWorkout()` - Natural language share

**Models**:
- `lib/models/workout_session.dart` - Workout sessions
- `lib/models/workout_set.dart` - Individual sets

---

### 💪 EXERCISES
**Models**:
- `lib/models/exercise.dart` - Exercise definitions
- `lib/models/exercise_target.dart` - Goals/targets

**Repository**: `lib/repositories/exercise_repository.dart`

**Provider**: `lib/providers/exercise_provider.dart`

---

### 🗄️ DATABASE

**Schema**: `lib/core/database/schema.dart`
- Line 2-15: `createUserProfile` (includes bfp_percentage)
- Line 17-22: `createWeightHistory`
- Line 24-36: `createExercises`
- Line 38-51: `createWorkoutSessions`
- Line 53-71: `createWorkoutSets`
- Line 108-128: `createWorkoutTemplates`
- Line 130-144: `createTemplateExercises`
- Line 146-163: `createBodyMeasurements`

**Helper**: `lib/core/database/database_helper.dart`
- Line 63-138: `_onOpen()` - Database migrations for existing users
- Line 71-75: Migration for bfp_percentage column

**Tables**:
```
user_profile, weight_history, exercises, workout_sessions, workout_sets,
exercise_targets, personal_records, app_meta, template_groups,
workout_templates, template_exercises, body_measurements, progress_photos,
scheduled_workouts, rest_days
```

---

## 🔍 COMMON TASKS

### ✅ Add a new field to UserProfile
1. Update schema: `lib/core/database/schema.dart` (line 2-15)
2. Add migration: `lib/core/database/database_helper.dart` (in `_onOpen()`)
3. Update model: `lib/models/user_profile.dart`
   - Add field to class
   - Update constructor
   - Update `fromMap()` method
   - Update `toMap()` method
4. Update repository: `lib/repositories/user_repository.dart`
   - Update all methods that create UserProfile instances
5. Update UI: `lib/screens/profile/profile_screen.dart`
   - Add controller (line 23-27)
   - Dispose controller (line 30-36)
   - Initialize controller (line 67-80)
   - Add input field (line 121-165)
   - Update `_saveProfile()` (line 530-588)

### ✅ Create a new template feature
1. Add UI in: `lib/screens/templates/templates_screen.dart`
2. Update repository: `lib/repositories/template_repository.dart`
3. Invalidate provider: `ref.invalidate(allTemplatesProvider);`

### ✅ Add sharing feature
**Pattern**: See workout share (line 29-123 in workout_detail_screen.dart)
```dart
import 'package:share_plus/share_plus.dart';

final buffer = StringBuffer();
// Build text with buffer.writeln()
Share.share(text, subject: 'Title');
```

### ✅ Add export/import (JSON)
**Pattern**: See group export (templates_screen.dart:1266-1324)
```dart
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

// Export
final exportData = { /* data */ };
final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
await Share.shareXFiles([XFile.fromData(utf8.encode(jsonString), ...]);

// Import
final result = await FilePicker.platform.pickFiles(...);
final jsonString = utf8.decode(file.bytes!);
final data = jsonDecode(jsonString);
```

---

## 📦 KEY DEPENDENCIES

```yaml
flutter_riverpod: ^2.4.9        # State management
sqflite: ^2.3.2                 # SQLite database
go_router: ^13.2.0              # Navigation
share_plus: ^7.2.1              # Sharing functionality
file_picker: ^6.0.0             # File selection
intl: ^0.18.0                   # Date formatting
```

---

## 🎨 THEMING

**Colors**: `lib/core/theme/colors.dart`
```dart
AppColors.background
AppColors.surface
AppColors.surfaceElevated
AppColors.primary
AppColors.textPrimary
AppColors.textSecondary
AppColors.textMuted
AppColors.success
AppColors.error
AppColors.warning
```

---

## 🔄 STATE MANAGEMENT (Riverpod)

### Key Providers
- `userProfileProvider` - User profile data
- `allTemplatesProvider` - All workout templates
- `allTemplateGroupsProvider` - All template groups
- `templateRepositoryProvider` - Template repository instance
- `exerciseRepositoryProvider` - Exercise repository instance
- `workoutDetailsProvider(id)` - Workout details by ID

### Refresh Pattern
```dart
ref.invalidate(providerName);  // Refresh provider
final data = ref.read(provider);  // Read once
final data = ref.watch(provider); // Watch for changes
```

---

## 🐛 RECENT FIXES

### Duplicate Template Bug (Fixed)
**Issue**: Exercise IDs were copied, causing conflicts with `ConflictAlgorithm.replace`
**Location**: `lib/screens/templates/templates_screen.dart:1128-1135`
**Fix**: Remove exercise IDs with `.copyWith(id: null)` before creating duplicate

### BFP% Addition (Completed)
**Files Changed**:
- `lib/core/database/schema.dart:8` - Added column
- `lib/core/database/database_helper.dart:71-75` - Migration
- `lib/models/user_profile.dart` - Added field
- `lib/repositories/user_repository.dart` - Updated methods
- `lib/screens/profile/profile_screen.dart:156-161` - UI field

### Group Share Feature (Added)
**Location**: `lib/screens/templates/templates_screen.dart:1175-1264`
**Function**: `_shareGroup()` - Natural language share for template groups

---

## 🚀 COMMON PATTERNS

### Dialog Pattern
```dart
showDialog<ReturnType>(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: Text('Title', style: TextStyle(color: AppColors.textPrimary)),
    content: // content,
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, result), child: Text('OK')),
    ],
  ),
);
```

### SnackBar Pattern
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Message'),
    backgroundColor: AppColors.success,
  ),
);
```

### Database Insert Pattern
```dart
final db = await _dbHelper.database;
final id = await db.insert(
  'table_name',
  object.toMap(),
  conflictAlgorithm: ConflictAlgorithm.replace,
);
```

### Navigation
```dart
context.push('/route');        // Navigate to route
context.pop();                 // Go back
```

---

## 📝 NOTES

- **Database version**: Currently at version 1
- **Migrations**: All handled in `_onOpen()` for backward compatibility
- **Unit system**: Supports both metric (kg, cm) and imperial (lbs, in)
- **Rest timer**: Auto-start feature with customizable default duration
- **Template groups**: Templates can be organized into collapsible groups
- **Exercise IDs**: Always remove IDs when duplicating to avoid conflicts

---

## 🔗 RELATED FILES MAPPING

| Feature | Screen | Model | Repository | Provider |
|---------|--------|-------|------------|----------|
| Templates | templates_screen.dart | workout_template.dart | template_repository.dart | template_provider.dart |
| Template Groups | templates_screen.dart | template_group.dart | template_group_repository.dart | template_provider.dart |
| User Profile | profile_screen.dart | user_profile.dart | user_repository.dart | user_provider.dart |
| Workouts | workout_detail_screen.dart | workout_session.dart | workout_repository.dart | workout_provider.dart |
| Exercises | exercise_screen.dart | exercise.dart | exercise_repository.dart | exercise_provider.dart |
| Body Measurements | body_measurements_screen.dart | body_measurement.dart | body_measurement_repository.dart | - |
| Weight Tracking | bodyweight_screen.dart | weight_entry.dart | weight_repository.dart | weight_history_provider.dart |

---

**Last Updated**: 2025-12-10
**Version**: 1.0.0

---

_This cheatsheet is a living document. Update it whenever you add new features or make significant changes to the codebase._
