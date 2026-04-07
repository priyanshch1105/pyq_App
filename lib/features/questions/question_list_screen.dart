import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_screen.dart';
import '../practice/practice_screen.dart';
import '../subscription/subscription_screen.dart';
import 'question_models.dart';
import 'question_repository.dart';
import 'recommendations_screen.dart';

class QuestionListScreen extends ConsumerWidget {
  const QuestionListScreen({
    super.key,
    required this.exam,
    this.examDisplayName,
  });
  final String exam;
  final String? examDisplayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleText = examDisplayName ?? exam;
    return Scaffold(
      appBar: AppBar(
        title: Text('$titleText Preparation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Analytics',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Recommendations',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded),
            tooltip: 'Subscription',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Question>>(
        future: ref.read(questionRepositoryProvider).fetchQuestions(exam: exam),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No questions found for $titleText.', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          final questions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    q.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        _Badge(text: q.subject, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        _Badge(text: q.year.toString(), color: Colors.indigo),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(q.difficulty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lvl ${q.difficulty}',
                      style: TextStyle(
                        color: _getDifficultyColor(q.difficulty),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PracticeScreen(question: q)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getDifficultyColor(int level) {
    if (level <= 1) return Colors.greenAccent;
    if (level <= 2) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
