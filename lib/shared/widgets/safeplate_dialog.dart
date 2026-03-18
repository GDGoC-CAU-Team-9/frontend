import 'dart:ui';

import 'package:flutter/material.dart';

enum SafePlateDialogButtonKind { ghost, filled }

class SafePlateDialog extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;

  const SafePlateDialog({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF2F8F6), Color(0xFFEAF3F1)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2C3A5A57),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.14),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                if (message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5A6664),
                      height: 1.45,
                    ),
                  ),
                ],
                if (content != null) ...[const SizedBox(height: 14), content!],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(spacing: 10, runSpacing: 8, children: actions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SafePlateDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color accentColor;
  final SafePlateDialogButtonKind kind;

  const SafePlateDialogButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.accentColor = const Color(0xFF246C67),
  }) : kind = SafePlateDialogButtonKind.ghost;

  const SafePlateDialogButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    this.accentColor = const Color(0xFF0F8E83),
  }) : kind = SafePlateDialogButtonKind.filled;

  @override
  Widget build(BuildContext context) {
    final bool filled = kind == SafePlateDialogButtonKind.filled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: filled ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: accentColor.withValues(alpha: 0.35)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : accentColor,
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration safePlateDialogInputDecoration({
  required String labelText,
  String? hintText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFFFFFFF).withValues(alpha: 0.68),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD5E3E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD5E3E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF0F8E83), width: 1.8),
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF4F6361),
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
