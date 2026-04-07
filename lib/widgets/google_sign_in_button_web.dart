import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildButton({required VoidCallback onPressedFallback}) {
  return SizedBox(
    width: 250,
    height: 50,
    child: web.renderButton(
      configuration: web.GSIButtonConfiguration(
        theme: web.GSIButtonTheme.filledBlue,
        size: web.GSIButtonSize.large,
      ),
    ),
  );
}
