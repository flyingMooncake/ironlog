# IronLog Features Documentation

This document tracks all implemented features in the IronLog gym tracking app.

---

## 🏋️ Core Workout Features

### Active Workout Tracking
- ✅ Start workout from multiple sources (empty, template, history)
- ✅ Add exercises dynamically during workout
- ✅ Track sets with weight and reps
- ✅ **Advanced weight input:**
  - +/- buttons for 0.5kg increments
  - Comma (,) support as decimal separator
  - Smart number formatting (removes trailing .0)
  - No controller recreation issues
- ✅ Mark warmup sets (excluded from volume calculations)
- ✅ **Mark drop sets** (excluded from PR detection, red indicator)
- ✅ **Superset support:**
  - Create supersets (group consecutive exercises)
  - Visual indicators (blue border, "SUPERSET" label)
  - Remove exercises from supersets
  - Saves superset_id to database
- ✅ Manual PR marking (checkbox per set)
- ✅ **Automatic PR detection** for all non-warmup and non-drop sets
- ✅ Delete exercises and sets during workout
- ✅ View previous workout data for each exercise
- ✅ Real-time volume calculation
- ✅ Workout duration tracking
- ✅ Save workout to history
- ✅ **Workout and set notes** - Add notes to entire workout or individual sets
- ✅ **Back/cancel button** with confirmation dialog
- ✅ **Prominent save button** (green button in app bar)

### Workout Templates (Workouts Tab)
- ✅ **Dedicated "Workouts" tab in bottom navigation**
- ✅ Create custom workout templates
- ✅ Name and description for each template
- ✅ **Duplicate/copy templates** with new name
- ✅ Delete templates
- ✅ View template exercise count
- ✅ Track last used date
- ✅ Quick start workout from template
- ✅ **Edit templates** (add/remove exercises, reorder, set targets)
- ✅ **Load template into active workout** - Fully functional
- ✅ **Load from history into active workout** - Copy exercises from previous workouts

### Start Workout Dialog
- ✅ **3-tab interface:**
  - **Empty**: Start blank workout
  - **Templates**: Choose from saved templates
  - **History**: Load previous workout
- ✅ Template list with exercise count
- ✅ History list with date/time
- ✅ One-tap workout start

---

## 📊 Progress & Analytics

### Personal Records (PRs)
- ✅ **Automatic PR tracking** on workout completion
- ✅ **4 PR types tracked:**
  - Max Weight (heaviest weight for any rep count)
  - Estimated 1RM (using Epley formula)
  - Max Reps (most reps at any weight)
  - Max Volume (highest weight × reps)
- ✅ PR celebration screen after workout
- ✅ Detailed PR breakdown by exercise
- ✅ PR history screen (Profile → Personal Records)
- ✅ Filter PRs by type
- ✅ View achievement dates

### Workout Statistics
- ✅ Statistics screen with analytics (Profile → Statistics)
- ✅ **Period selector:** 7D, 30D, 90D, 1Y
- ✅ **Overview cards:**
  - Total workouts
  - Total volume
  - Average volume per workout
  - Total sets
- ✅ **Volume progression chart** (line chart over time)
- ✅ **Workout frequency chart** (bar chart by day of week)

### Body Tracking
- ✅ **Bodyweight tracking** over time
- ✅ **Body measurements tracking:**
  - 11 measurement points (chest, waist, hips, arms, thighs, calves, shoulders, neck)
  - Progress comparison with previous measurements
  - Change indicators (+/- values)
  - Optional notes per measurement
- ✅ **Progress photos:**
  - Take or upload progress photos
  - Photo types: front, side, back, custom
  - Weight tracking per photo
  - Grid view with date stamps
  - Full-screen photo viewer
  - Delete photos
- ✅ Date-stamped entries
- ✅ Historical view

---

## 📚 Exercise Library

### Exercise Management
- ✅ Pre-seeded exercise database
- ✅ Search exercises by name
- ✅ Filter by muscle group
- ✅ Create custom exercises
- ✅ **Exercise history in picker** - Shows last workout data when adding exercises
- ✅ **Exercise form tips & instructions** - View and edit exercise instructions
- ✅ Exercise details:
  - Primary muscle
  - Secondary muscles
  - Equipment type
  - Notes/instructions (editable for custom exercises)
- ✅ Exercise progress tracking (per exercise)
- ✅ 1RM progression history

### Exercise Tools (Accessible from Exercises → Calculator icon)
- ✅ **1RM Calculator:**
  - Calculate estimated 1RM from any weight/rep combination
  - Training percentages (60%-100%)
  - Rep range recommendations per percentage
  - Color-coded intensity levels
- ✅ **Plate Calculator:**
  - Calculate plates needed for target weight
  - Bar weight selector (15kg/20kg)
  - Visual plate loading guide
  - Adjustable target weight

---

## ⏱️ Timer & Tools

### Rest Timer
- ✅ Persistent rest timer widget
- ✅ Displays at bottom of active workout screen
- ✅ Adjustable time (+15s, +30s, -15s buttons)
- ✅ Circular progress indicator
- ✅ Play/pause controls
- ✅ Reset functionality
- ✅ Completion notification with haptic feedback
- ✅ Default rest time configurable in profile
- ✅ **Auto-start after completing set** (configurable in profile)

---

## 📅 Workout Planning & Scheduling

### Workout Calendar
- ✅ **Calendar view** with month navigation
- ✅ **Schedule workouts:**
  - Select template to schedule
  - Pick date for workout
  - View scheduled workouts on calendar
  - Mark workouts as completed
  - Delete scheduled workouts
- ✅ **Rest day tracking:**
  - Mark specific days as rest days
  - Visual indicators on calendar
  - Optional notes for rest days
  - Remove rest days
- ✅ **Calendar indicators:**
  - Scheduled workouts (green dot)
  - Rest days (yellow dot)
  - Day details panel showing all events
- ✅ Quick jump to today
- ✅ Upcoming workouts view

---

## 📜 History & Review

### Workout History
- ✅ List all completed workouts
- ✅ Sort by date (newest first)
- ✅ View workout details:
  - Duration
  - Total volume
  - Exercises performed
  - All sets with weight/reps
- ✅ Date/time stamps
- ✅ Delete workouts
- ⏳ Load workout from history - **TODO**

---

## 👤 Profile & Settings

### User Profile
- ✅ Personal information:
  - Weight
  - Height
  - Age
- ✅ Unit system (metric/imperial)
- ✅ Default rest timer duration
- ✅ Auto-save profile changes

### Data Management
- ✅ **Export workout data to JSON**
- ✅ Backup all workout history
- ⏳ Import data - **TODO**

---

## 🎨 UI/UX Features

### Navigation
- ✅ **5-tab bottom navigation:**
  1. Home
  2. **Workouts** (Templates)
  3. Exercises
  4. History
  5. Profile
- ✅ **Fixed navigation bug:** Tapping tab always goes to tab root (even from detail screens)
- ✅ Tab state preservation
- ✅ Material Design 3 theming
- ✅ Dark theme by default

### Visual Feedback
- ✅ Haptic feedback on interactions
- ✅ Success/error notifications
- ✅ Loading indicators
- ✅ Empty state illustrations
- ✅ Color-coded data (PRs, muscle groups, etc.)
- ✅ Smooth animations

### User Experience
- ✅ Offline-first (local SQLite database)
- ✅ No ads, no subscriptions
- ✅ Quick actions and shortcuts
- ✅ Confirmation dialogs for destructive actions
- ✅ Undo-friendly operations

---

## 🗄️ Database & Architecture

### Data Models
- ✅ User Profile
- ✅ Exercises
- ✅ Workout Sessions
- ✅ Workout Sets (with superset support)
- ✅ Personal Records
- ✅ Body Measurements
- ✅ Workout Templates
- ✅ Template Exercises
- ✅ Weight History
- ✅ Exercise Targets/Goals
- ✅ Progress Photos
- ✅ Scheduled Workouts
- ✅ Rest Days

### Technical Features
- ✅ SQLite local database
- ✅ Riverpod state management
- ✅ Go Router navigation
- ✅ Repository pattern
- ✅ Indexed database queries for performance
- ✅ Database seeding (exercises)

---

## 📋 Pending Features / TODOs

### High Priority
- [x] **Template Editor** - Add/remove exercises from templates (COMPLETED)
- [x] **Load template into workout** - Populate active workout with template exercises (COMPLETED)
- [x] **Load from history** - Copy exercises from past workout into new workout (COMPLETED)
- [x] **Auto-start rest timer** - Automatically start timer when set is complete (COMPLETED)
- [x] **Exercise history in picker** - Show last workout data for each exercise (COMPLETED)
- [x] **Exercise instructions** - Add detailed form tips and instructions per exercise (COMPLETED)
- [x] **Goal setting** - Set targets for lifts and track progress (COMPLETED)
- [x] **Progress photos** - Visual progress tracking with photos (COMPLETED)
- [x] **Workout scheduling** - Plan workouts in advance (COMPLETED)
- [x] **Rest day tracking** - Mark and track rest days (COMPLETED)

### Medium Priority
- [ ] **Exercise video/image** - Visual guides for proper form

### Low Priority / Nice to Have
- [ ] **Dark/Light theme toggle** - User preference for theme
- [ ] **Export to CSV** - Alternative export format
- [ ] **Share workouts** - Share workout summary
- [ ] **Workout calendar view** - Calendar visualization of workout history
- [ ] **Muscle recovery tracking** - Track muscle soreness/recovery
- [ ] **Workout reminders** - Notifications for scheduled workouts
- [ ] **Achievements/badges** - Gamification elements
- [ ] **Data sync** (future) - Cloud backup and multi-device sync

---

## 🏗️ Architecture Notes

### Key Directories
```
lib/
├── core/
│   ├── database/         # Database setup, schema, seeding
│   ├── router/           # Go Router navigation config
│   ├── theme/            # Colors, theme definitions
│   └── utils/            # Utility classes (formatters, etc.)
├── models/               # Data models
├── providers/            # Riverpod state providers
├── repositories/         # Database access layer
├── screens/              # UI screens by feature
│   ├── home/
│   ├── workout/
│   ├── exercises/
│   ├── history/
│   ├── profile/
│   └── templates/
├── services/             # Business logic services (haptics, etc.)
└── widgets/              # Reusable widgets
```

### Design Patterns
- **Repository Pattern** - Separates data access from business logic
- **Provider Pattern** - State management with Riverpod
- **Feature-First Organization** - Code organized by feature/screen

---

## 📝 Notes

- App name: **IronLog**
- Platform: Flutter (cross-platform)
- Current targets: Android, Linux (desktop)
- Database version: 1
- No external API dependencies
- Fully offline-capable

---

**Last Updated:** December 2025

**Version:** 1.0.0 (Release Ready)

## Recent Additions - Version 1.0 (December 2025)
- ✅ Exercise form tips & instructions (view/edit in exercise progress screen)
- ✅ Goal setting feature (fully functional with progress tracking)
- ✅ Progress photos (camera/gallery support with photo types)
- ✅ Workout calendar with scheduling
- ✅ Rest day tracking
- ✅ **Drop sets support** (mark sets as drop sets, excluded from PRs)
- ✅ **Superset support** (visual grouping, create/manage supersets)
- ✅ **Advanced weight input** (+/- buttons, comma support, smart formatting)
- ✅ **Improved active workout UI** (save button, back confirmation)
- ✅ **Code quality improvements** (fixed TextField controllers, removed unused code)
