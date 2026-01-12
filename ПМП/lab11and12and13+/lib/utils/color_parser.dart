import 'package:flutter/material.dart';

class ColorParser {
  static const Color _fallbackColor = Color(0xFFd0c9b7);

  static Color fromString(String? value, {Color? defaultColor}) {
    if (value == null || value.trim().isEmpty) {
      return defaultColor ?? _fallbackColor;
    }

    var normalized = value.trim();
    final colorMatch = RegExp(r'0x[0-9a-fA-F]+').firstMatch(normalized) ??
        RegExp(r'[0-9a-fA-F]{6,8}').firstMatch(normalized);

    if (colorMatch != null) {
      normalized = colorMatch.group(0)!;
    } else {
      normalized = normalized
          .replaceAll('Color', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll('#', '')
          .replaceAll('0x', '');
    }

    normalized = normalized
        .replaceAll('#', '')
        .replaceAll('Color', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    if (normalized.startsWith('0x') || normalized.startsWith('0X')) {
      normalized = normalized.substring(2);
    }

    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }

    final colorValue = int.tryParse(normalized, radix: 16);
    if (colorValue == null) {
      return defaultColor ?? _fallbackColor;
    }

    return Color(colorValue);
  }
}

