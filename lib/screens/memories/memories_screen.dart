import 'package:flutter/material.dart';

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFFDF2F8), const Color(0xFFFFF5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'We are working hard to bring you\nthis feature in a future update.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
