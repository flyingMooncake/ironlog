# IronLog Version 1.1 - Planned Features

This document outlines planned features for version 1.1 of IronLog.

---

## 🎯 Goals for Version 1.1

Focus on visual learning aids and user customization to enhance the workout experience.

---

## 📋 Planned Features

### High Priority

#### 1. **Exercise Videos/Images**
- **Description**: Add visual guides for proper exercise form
- **Features**:
  - Upload or link exercise demonstration videos
  - Add form check images (starting position, end position)
  - View videos/images in exercise details screen
  - Optional: Show thumbnail preview in exercise picker
- **Database**: Add `video_url` and `image_urls` columns to exercises table
- **Rationale**: Visual guides help users learn proper form and reduce injury risk

#### 2. **Dark/Light Theme Toggle**
- **Description**: Allow users to switch between dark and light themes
- **Features**:
  - Theme selector in Profile settings
  - System default option (follows device theme)
  - Smooth theme transitions
  - Persistent theme preference
- **Database**: Add `theme_preference` column to user_profile table
- **Rationale**: User preference and accessibility

#### 3. **Data Import**
- **Description**: Complete the import functionality to complement existing export
- **Features**:
  - Import from JSON backup files
  - Validation and error handling
  - Merge or replace existing data options
  - Progress indicator for large imports
- **Rationale**: Complete backup/restore functionality for data safety

---

### Medium Priority

#### 4. **Workout Reminders/Notifications**
- **Description**: Send notifications for scheduled workouts
- **Features**:
  - Customizable reminder time (e.g., 1 hour before, day before)
  - Toggle reminders on/off globally
  - Per-workout reminder settings
  - Rest day reminders (optional)
- **Technical**: Requires local notifications package
- **Rationale**: Helps users stay consistent with their workout schedule

#### 5. **Export to CSV**
- **Description**: Alternative export format for spreadsheet analysis
- **Features**:
  - Export workout history to CSV
  - Export PRs to CSV
  - Export body measurements to CSV
  - Customizable date ranges
- **Rationale**: Power users may want to analyze data in Excel/Sheets

#### 6. **Share Workouts**
- **Description**: Share workout summaries with friends or on social media
- **Features**:
  - Generate shareable workout summary
  - Include exercises, sets, volume, duration
  - Optional: Include PRs achieved
  - Share as text or image
- **Technical**: Requires share package
- **Rationale**: Social accountability and motivation

---

### Low Priority / Nice to Have

#### 7. **Muscle Recovery Tracking**
- **Description**: Track muscle soreness and recovery status
- **Features**:
  - Mark muscle groups as sore (1-5 scale)
  - Recovery timeline visualization
  - Workout suggestions based on recovery
  - History of soreness over time
- **Database**: New `muscle_recovery` table
- **Rationale**: Helps prevent overtraining and optimize workout planning

#### 8. **Achievements/Badges System**
- **Description**: Gamification to motivate consistent training
- **Features**:
  - Badges for milestones (100 workouts, 1000kg volume, etc.)
  - Streak tracking (consecutive workout days)
  - Achievement notifications
  - Badge display in profile
- **Database**: New `achievements` table
- **Rationale**: Adds fun and motivation

#### 9. **Workout Insights/AI Suggestions**
- **Description**: Smart insights based on workout data
- **Features**:
  - Identify weak muscle groups (underworked)
  - Suggest deload weeks based on volume
  - Progression recommendations
  - Optimal rest day suggestions
- **Technical**: Requires analytics algorithms
- **Rationale**: Help users optimize their training

#### 10. **Advanced Template Features**
- **Description**: Enhance template system with more flexibility
- **Features**:
  - Template categories/tags (Push, Pull, Legs, etc.)
  - Template sharing (export/import specific templates)
  - Progressive overload rules (auto-increase weight/reps)
  - Superset/circuit pre-planning in templates
- **Rationale**: Makes templates more powerful and reusable

---

## 🔧 Technical Improvements for 1.1

### Code Quality
- [ ] Add comprehensive unit tests
- [ ] Add integration tests for critical flows
- [ ] Improve error handling across the app
- [ ] Add logging framework for debugging

### Performance
- [ ] Optimize database queries (add more indexes if needed)
- [ ] Lazy load images in progress photos
- [ ] Cache frequently accessed data
- [ ] Profile and optimize slow screens

### UX Improvements
- [ ] Add onboarding tutorial for new users
- [ ] Improve empty states with actionable CTAs
- [ ] Add keyboard shortcuts for desktop version
- [ ] Improve accessibility (screen reader support)

---

## 🚀 Future Considerations (Version 2.0+)

### Cloud Sync (Major Feature)
- Multi-device synchronization
- Cloud backup
- Account system
- Requires backend infrastructure

### Social Features
- Follow friends
- Compare stats
- Workout challenges
- Community templates

### Advanced Analytics
- Machine learning predictions
- Form analysis (camera-based)
- Voice commands during workout
- Wearable integration (heart rate, etc.)

---

## 📊 Development Priorities

1. **User Requests**: Prioritize features based on user feedback
2. **Impact vs Effort**: Focus on high-impact, low-effort features first
3. **Core Experience**: Don't compromise core workout tracking quality
4. **Performance**: Keep app fast and responsive
5. **Simplicity**: Maintain clean, intuitive UI

---

## 🗓️ Tentative Timeline

**Version 1.1 Target**: Q1 2026

**Phases**:
- Phase 1 (Month 1): Exercise videos/images, Theme toggle
- Phase 2 (Month 2): Data import, Workout reminders
- Phase 3 (Month 3): CSV export, Share workouts, Polish

---

**Notes**:
- Features may be added/removed based on user feedback
- Timeline is flexible and depends on development capacity
- Focus remains on quality over quantity

**Last Updated**: December 2025
