import 'package:flutter/material.dart';

class Spacing {
  Spacing._();

  static const Widget tiny = SizedBox(width: 4, height: 4);
  static const Widget small = SizedBox(width: 8, height: 8);
  static const Widget medium = SizedBox(width: 16, height: 16);
  static const Widget large = SizedBox(width: 24, height: 24);
  static const Widget xLarge = SizedBox(width: 32, height: 32);
  static const Widget xxLarge = SizedBox(width: 48, height: 48);
  static const Widget xxxLarge = SizedBox(width: 64, height: 64);
}

class UiUtils {
  UiUtils._();

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}
