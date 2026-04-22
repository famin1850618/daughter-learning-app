import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习成效')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('成效报告', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('第二阶段开放', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
