/// Calculate volume for a single set
double calculateSetVolume(double? weight, int? reps) {
  if (weight == null || reps == null) return 0;
  return weight * reps;
}

/// Estimated 1RM using Epley formula: 1RM = weight × (1 + reps/30)
double calculateEpley1RM(double weight, int reps) {
  if (reps == 1) return weight;
  if (reps <= 0 || weight <= 0) return 0;
  return weight * (1 + reps / 30);
}

/// Estimated 1RM using Brzycki formula: 1RM = weight × (36 / (37 - reps))
double calculateBrzycki1RM(double weight, int reps) {
  if (reps == 1) return weight;
  if (reps >= 37 || reps <= 0 || weight <= 0) return 0;
  return weight * (36 / (37 - reps));
}

/// Calculate 1RM with selectable formula
double calculate1RM(double weight, int reps, {bool useBrzycki = false}) {
  if (useBrzycki) return calculateBrzycki1RM(weight, reps);
  return calculateEpley1RM(weight, reps);
}

/// Convert kg to lbs
double kgToLbs(double kg) => kg * 2.20462;

/// Convert lbs to kg
double lbsToKg(double lbs) => lbs / 2.20462;

/// Format duration in seconds to mm:ss
String formatDuration(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  return '$mins:${secs.toString().padLeft(2, '0')}';
}

/// Format weight with unit
String formatWeight(double weight, String unit) {
  return '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} $unit';
}
