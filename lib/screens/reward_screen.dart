import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('奖励中心')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏆', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('积分与奖励', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('第三阶段开放', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
