import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pyq/features/auth/auth_controller.dart';
import 'package:pyq/features/auth/login_screen.dart';
import 'package:pyq/features/questions/question_list_screen.dart';

class ExamSelectionScreen extends ConsumerWidget {
  const ExamSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const exams = [
      {'name': 'UPSC', 'code': 'UPSC', 'icon': Icons.account_balance_rounded, 'color': Colors.amber},
      {'name': 'JEE Main', 'code': 'JEE_MAIN', 'icon': Icons.engineering_rounded, 'color': Colors.blue},
      {'name': 'JEE Advanced', 'code': 'JEE_ADVANCED', 'icon': Icons.bolt_rounded, 'color': Colors.blueGrey},
      {'name': 'NEET', 'code': 'NEET', 'icon': Icons.medical_services_rounded, 'color': Colors.red},
      {'name': 'NDA', 'code': 'NDA', 'icon': Icons.military_tech_rounded, 'color': Colors.green},
      {'name': 'SSC', 'code': 'SSC', 'icon': Icons.assignment_ind_rounded, 'color': Colors.purple},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Exam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Path',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the exam you are preparing for to see specialized questions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exam = exams[index];
                  final name = exam['name'] as String;
                  final code = exam['code'] as String;
                  final icon = exam['icon'] as IconData;
                  final color = exam['color'] as Color;

                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuestionListScreen(exam: code, examDisplayName: name),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Practice Now',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: exams.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
