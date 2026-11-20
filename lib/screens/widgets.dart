import 'package:flutter/material.dart';

/// A big rounded, colourful button used on the start and game over screens.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 30),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        textStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 6,
      ),
    );
  }
}

/// Dark see-through background that lets the road show behind a screen.
class ScreenBackdrop extends StatelessWidget {
  const ScreenBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC0D1B2A), Color(0x991B263B), Color(0xCC0D1B2A)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
