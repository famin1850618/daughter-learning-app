import 'package:flutter/material.dart';
import '../models/subject.dart';
import 'curriculum_chapter_edit_screen.dart';

class CurriculumManagementScreen extends StatelessWidget {
  const CurriculumManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('课程知识库')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '选择科目管理章节，支持增删和排序',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: Subject.values.length,
              itemBuilder: (context, index) {
                final subject = Subject.values[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CurriculumChapterEditScreen(subject: subject),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(subject.emoji,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(height: 8),
                          Text(
                            subject.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject.gradeRangeLabel,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
