import 'package:sqflite/sqflite.dart';

class SeedData {
  static Future<void> seedExercises(Database db) async {
    final exercises = [
      // === CHEST (12) ===
      {'name': 'Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Incline Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Decline Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Incline Dumbbell Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Dumbbell Fly', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Fly (Low to High)', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Cable Fly (High to Low)', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Machine Chest Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Pec Deck Machine', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Push-ups', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Dips (Chest Focus)', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'bodyweight'},
      {'name': 'Assisted Dips (Chest)', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps,shoulders', 'tracking_type': 'assisted_weight_reps', 'equipment': 'machine'},

      // === BACK (15) ===
      {'name': 'Conventional Deadlift', 'primary_muscle': 'back', 'secondary_muscles': 'hamstrings,glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Barbell Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Pendlay Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'T-Bar Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Seated Cable Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Lat Pulldown (Wide Grip)', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Lat Pulldown (Close Grip)', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Pull-ups', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Chin-ups', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Assisted Pull-ups', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'assisted_weight_reps', 'equipment': 'machine'},
      {'name': 'Assisted Chin-ups', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps,back', 'tracking_type': 'assisted_weight_reps', 'equipment': 'machine'},
      {'name': 'Face Pulls', 'primary_muscle': 'back', 'secondary_muscles': 'shoulders,traps', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Straight Arm Pulldown', 'primary_muscle': 'lats', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Machine Row', 'primary_muscle': 'back', 'secondary_muscles': 'biceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Rack Pulls', 'primary_muscle': 'back', 'secondary_muscles': 'traps,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Good Mornings', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'hamstrings,glutes', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},

      // === SHOULDERS (12) ===
      {'name': 'Overhead Press (Barbell)', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Seated Dumbbell Press', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Arnold Press', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Lateral Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Front Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Rear Delt Fly', 'primary_muscle': 'shoulders', 'secondary_muscles': 'back', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Lateral Raise', 'primary_muscle': 'shoulders', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Upright Row', 'primary_muscle': 'shoulders', 'secondary_muscles': 'traps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Machine Shoulder Press', 'primary_muscle': 'shoulders', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Barbell Shrugs', 'primary_muscle': 'traps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Shrugs', 'primary_muscle': 'traps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Reverse Pec Deck', 'primary_muscle': 'shoulders', 'secondary_muscles': 'back', 'tracking_type': 'weight_reps', 'equipment': 'machine'},

      // === BICEPS (10) ===
      {'name': 'Barbell Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'EZ Bar Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Dumbbell Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Hammer Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Preacher Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Concentration Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Incline Dumbbell Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Spider Curl', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Reverse Curl', 'primary_muscle': 'biceps', 'secondary_muscles': 'forearms', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},

      // === TRICEPS (10) ===
      {'name': 'Close Grip Bench Press', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Skull Crushers', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Tricep Pushdown (Rope)', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Tricep Pushdown (Bar)', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Overhead Tricep Extension', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Dumbbell Kickback', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Diamond Push-ups', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Dips (Tricep Focus)', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'bodyweight'},
      {'name': 'Assisted Dips (Tricep)', 'primary_muscle': 'triceps', 'secondary_muscles': 'chest,shoulders', 'tracking_type': 'assisted_weight_reps', 'equipment': 'machine'},
      {'name': 'Cable Overhead Extension', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Machine Tricep Extension', 'primary_muscle': 'triceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},

      // === FOREARMS (6) ===
      {'name': 'Wrist Curls', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Reverse Wrist Curls', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Farmer Walks', 'primary_muscle': 'forearms', 'secondary_muscles': 'traps,fullBody', 'tracking_type': 'weight_time', 'equipment': 'dumbbell'},
      {'name': 'Dead Hangs', 'primary_muscle': 'forearms', 'secondary_muscles': 'lats', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Plate Pinch', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'other'},
      {'name': 'Grip Crushers', 'primary_muscle': 'forearms', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'other'},

      // === QUADS (12) ===
      {'name': 'Barbell Back Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Front Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,abs', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Goblet Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Leg Press', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Hack Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Bulgarian Split Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Lunges', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Walking Lunges', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Leg Extension', 'primary_muscle': 'quads', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Sissy Squat', 'primary_muscle': 'quads', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Step-ups', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Box Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},

      // === HAMSTRINGS (8) ===
      {'name': 'Romanian Deadlift', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Stiff Leg Deadlift', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Lying Leg Curl', 'primary_muscle': 'hamstrings', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Seated Leg Curl', 'primary_muscle': 'hamstrings', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Nordic Curl', 'primary_muscle': 'hamstrings', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Glute Ham Raise', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes', 'tracking_type': 'reps_only', 'equipment': 'machine'},
      {'name': 'Single Leg Deadlift', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes,lowerBack', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Cable Pull Through', 'primary_muscle': 'hamstrings', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'cable'},

      // === GLUTES (8) ===
      {'name': 'Barbell Hip Thrust', 'primary_muscle': 'glutes', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Machine Hip Thrust', 'primary_muscle': 'glutes', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Glute Bridge', 'primary_muscle': 'glutes', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'bodyweight'},
      {'name': 'Cable Kickback', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Donkey Kicks', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Sumo Deadlift', 'primary_muscle': 'glutes', 'secondary_muscles': 'quads,hamstrings,back', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Sumo Squat', 'primary_muscle': 'glutes', 'secondary_muscles': 'quads', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},
      {'name': 'Frog Pumps', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},

      // === CALVES (6) ===
      {'name': 'Standing Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Seated Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Leg Press Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Donkey Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Single Leg Calf Raise', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Jump Rope', 'primary_muscle': 'calves', 'secondary_muscles': 'cardio', 'tracking_type': 'time', 'equipment': 'other'},

      // === ABS (12) ===
      {'name': 'Crunches', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Hanging Leg Raise', 'primary_muscle': 'abs', 'secondary_muscles': 'obliques', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Cable Crunch', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Ab Wheel Rollout', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'other'},
      {'name': 'Plank', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Side Plank', 'primary_muscle': 'obliques', 'secondary_muscles': 'abs', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Russian Twists', 'primary_muscle': 'obliques', 'secondary_muscles': 'abs', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Bicycle Crunches', 'primary_muscle': 'abs', 'secondary_muscles': 'obliques', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Mountain Climbers', 'primary_muscle': 'abs', 'secondary_muscles': 'cardio', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Dead Bug', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Hollow Hold', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'V-ups', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},

      // === LOWER BACK (5) ===
      {'name': 'Back Extensions', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Reverse Hypers', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Superman Hold', 'primary_muscle': 'lowerBack', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Bird Dog', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'abs', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},
      {'name': 'Jefferson Curl', 'primary_muscle': 'lowerBack', 'secondary_muscles': 'hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'dumbbell'},

      // === FULL BODY / COMPOUND (10) ===
      {'name': 'Clean and Jerk', 'primary_muscle': 'fullBody', 'secondary_muscles': 'shoulders,quads,back', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Snatch', 'primary_muscle': 'fullBody', 'secondary_muscles': 'shoulders,back,quads', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Power Clean', 'primary_muscle': 'fullBody', 'secondary_muscles': 'back,traps,quads', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Clean Pull', 'primary_muscle': 'fullBody', 'secondary_muscles': 'back,traps', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Thrusters', 'primary_muscle': 'fullBody', 'secondary_muscles': 'quads,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'barbell'},
      {'name': 'Man Makers', 'primary_muscle': 'fullBody', 'secondary_muscles': '', 'tracking_type': 'reps_only', 'equipment': 'dumbbell'},
      {'name': 'Turkish Get-up', 'primary_muscle': 'fullBody', 'secondary_muscles': 'abs,shoulders', 'tracking_type': 'weight_reps', 'equipment': 'kettlebell'},
      {'name': 'Kettlebell Swing', 'primary_muscle': 'fullBody', 'secondary_muscles': 'glutes,hamstrings', 'tracking_type': 'weight_reps', 'equipment': 'kettlebell'},
      {'name': 'Battle Ropes', 'primary_muscle': 'fullBody', 'secondary_muscles': 'cardio', 'tracking_type': 'time', 'equipment': 'other'},
      {'name': 'Burpees', 'primary_muscle': 'fullBody', 'secondary_muscles': 'cardio', 'tracking_type': 'reps_only', 'equipment': 'bodyweight'},

      // === MACHINES (15) ===
      {'name': 'Smith Machine Squat', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Smith Machine Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': 'triceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Cable Crossover', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'cable'},
      {'name': 'Assisted Pull-up Machine', 'primary_muscle': 'lats', 'secondary_muscles': 'biceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Chest Supported Row Machine', 'primary_muscle': 'back', 'secondary_muscles': 'biceps', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Hip Abductor Machine', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Hip Adductor Machine', 'primary_muscle': 'quads', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Preacher Curl Machine', 'primary_muscle': 'biceps', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Abdominal Crunch Machine', 'primary_muscle': 'abs', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Rotary Torso Machine', 'primary_muscle': 'obliques', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Glute Kickback Machine', 'primary_muscle': 'glutes', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Calf Raise Machine', 'primary_muscle': 'calves', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Low Row Machine', 'primary_muscle': 'back', 'secondary_muscles': 'biceps,lats', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Chest Fly Machine', 'primary_muscle': 'chest', 'secondary_muscles': '', 'tracking_type': 'weight_reps', 'equipment': 'machine'},
      {'name': 'Vertical Leg Press', 'primary_muscle': 'quads', 'secondary_muscles': 'glutes', 'tracking_type': 'weight_reps', 'equipment': 'machine'},

      // === CARDIO (10) ===
      {'name': 'Treadmill Running', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,calves', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Rowing Machine', 'primary_muscle': 'cardio', 'secondary_muscles': 'back,biceps', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Assault Bike', 'primary_muscle': 'cardio', 'secondary_muscles': 'fullBody', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Stair Climber', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,glutes', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Elliptical', 'primary_muscle': 'cardio', 'secondary_muscles': '', 'tracking_type': 'time', 'equipment': 'machine'},
      {'name': 'Sled Push', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,glutes', 'tracking_type': 'weight_time', 'equipment': 'other'},
      {'name': 'Sled Pull', 'primary_muscle': 'cardio', 'secondary_muscles': 'back,hamstrings', 'tracking_type': 'weight_time', 'equipment': 'other'},
      {'name': 'Box Jumps', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,calves', 'tracking_type': 'reps_only', 'equipment': 'other'},
      {'name': 'Sprints', 'primary_muscle': 'cardio', 'secondary_muscles': 'quads,hamstrings', 'tracking_type': 'time', 'equipment': 'bodyweight'},
      {'name': 'Incline Treadmill Walk', 'primary_muscle': 'cardio', 'secondary_muscles': 'glutes,calves', 'tracking_type': 'time', 'equipment': 'machine'},
    ];

    final batch = db.batch();
    for (final exercise in exercises) {
      batch.insert(
        'exercises',
        {...exercise, 'is_custom': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);

    // Mark as seeded
    await db.insert(
      'app_meta',
      {'key': 'exercises_seeded', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
