import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pyq/features/questions/question_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Performance Analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Main Dash'),
              Tab(text: 'By Subject'),
              Tab(text: 'By Chapter'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: ref.read(questionRepositoryProvider).fetchPerformance(),
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.orangeAccent),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No data found. Start practicing!'));
            }

            final data = snapshot.data!;
            final topics = List<Map<String, dynamic>>.from(data['topic_stats'] as List? ?? []);
            final subjects = List<Map<String, dynamic>>.from(data['subject_stats'] as List? ?? []);
            
            final overallAccuracy = (data['overall_accuracy'] as num?)?.toDouble() ?? 0.0;
            final avgTime = (data['avg_time_per_question'] as num?)?.toDouble() ?? 0.0;
            final streak = (data['streak'] as int?) ?? 0;
            final totalAttempts = (data['total_attempts'] as int?) ?? 0;

            return TabBarView(
              children: [
                _buildMainDash(context, overallAccuracy, avgTime, streak, totalAttempts),
                _buildStatsList(context, subjects, 'subject'),
                _buildStatsList(context, topics, 'topic'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainDash(BuildContext context, double accuracy, double time, int streak, int total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Daily Streak',
                  value: '$streak Days',
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatTile(
                  label: 'Questions Solved',
                  value: '$total',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Overall Accuracy',
                  value: '${(accuracy * 100).toStringAsFixed(1)}%',
                  icon: Icons.track_changes_rounded,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatTile(
                  label: 'Avg Time/Q',
                  value: '${time.toStringAsFixed(1)}s',
                  icon: Icons.timer_outlined,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Icon(Icons.query_stats_rounded, size: 80, color: Colors.indigo.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Keep up the great work!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList(BuildContext context, List<Map<String, dynamic>> items, String titleKey) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No $titleKey data available yet.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final t = items[index];
        final accuracy = (t['accuracy'] as num?)?.toDouble() ?? 0.0;
        final title = t[titleKey] as String? ?? (t['topic'] as String?) ?? 'Unknown';
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: accuracy,
                  backgroundColor: Colors.white10,
                  color: _getConsistencyColor(accuracy),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(accuracy * 100).toStringAsFixed(1)}% Accuracy', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${(t['attempts'] ?? 0)} Attempts', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getConsistencyColor(double acc) {
    if (acc >= 0.8) return Colors.greenAccent;
    if (acc >= 0.5) return Colors.amberAccent;
    return Colors.redAccent;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color, required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
