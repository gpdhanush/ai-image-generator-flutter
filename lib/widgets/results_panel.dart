import 'package:flutter/material.dart';

class ResultsPanel extends StatelessWidget {
  final Widget child;

  const ResultsPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 75, 4, 64).withOpacity(0.85),
            const Color.fromARGB(255, 23, 23, 181).withOpacity(0.6),
          ],
        ),
      ),
      child: Center(child: child),
    );
  }
}
