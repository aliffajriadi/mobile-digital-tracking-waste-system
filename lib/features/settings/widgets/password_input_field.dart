import 'package:flutter/material.dart';

class PasswordInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final bool hasValue;
  final VoidCallback onToggleVisibility;

  const PasswordInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.hasValue,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF14A38B);
    const filledGrey = Color(0xFFE9ECF0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8A99A8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: hasValue ? primaryColor : filledGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: hasValue ? Colors.black : Colors.black87,
            style: TextStyle(
              color: hasValue ? Colors.black : Colors.black87,
              fontSize: 14,
              letterSpacing: obscureText ? 3.0 : 1.0,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.remove_red_eye_rounded,
                  color: hasValue ? primaryColor : primaryColor,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}