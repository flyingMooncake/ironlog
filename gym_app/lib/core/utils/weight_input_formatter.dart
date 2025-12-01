import 'package:flutter/services.dart';

/// Custom text input formatter for weight input
/// Allows normal decimal input with one decimal place
class WeightInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow digits and one decimal point
    final text = newValue.text;

    // If empty, allow it
    if (text.isEmpty) {
      return newValue;
    }

    // Check if valid number format
    if (!RegExp(r'^\d*\.?\d{0,1}$').hasMatch(text)) {
      return oldValue;
    }

    // Don't allow multiple decimal points
    if (text.split('.').length > 2) {
      return oldValue;
    }

    return newValue;
  }
}
