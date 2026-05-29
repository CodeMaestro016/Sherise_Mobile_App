import 'package:flutter/material.dart';

void showMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String? requiredValidator(String? value, {int min = 2}) {
  if (value == null || value.trim().isEmpty) return 'Required';
  if (value.trim().length < min) return 'Minimum $min characters';
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email is required';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim());
  return ok ? null : 'Enter a valid email';
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone number is required';
  return RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(value.trim())
      ? null
      : 'Enter a valid phone number';
}
