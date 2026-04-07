import 'package:flutter/material.dart';

Widget buildButton({required VoidCallback onPressedFallback}) {
  return ElevatedButton.icon(
    icon: const Icon(Icons.login),
    label: const Text('Google Login'),
    onPressed: onPressedFallback,
  );
}
