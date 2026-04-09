import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_screen.dart';
import '../practice/practice_screen.dart';
import '../subscription/subscription_screen.dart';
import 'question_models.dart';
import 'question_repository.dart';
import 'recommendations_screen.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({
    super.key,
    required this.exam,
    this.examDisplayName,
    this.subjectFilter,
    this.topicFilter,
  });
  final String exam;
  final String? examDisplayName;
  final String? subjectFilter;
  final String? topicFilter;

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  @override
  Widget build(BuildContext context) {
    final titleText = widget.examDisplayName ?? widget.exam;
    final isFiltered = widget.subjectFilter != null || widget.topicFilter != null;

    final future = ref.read(questionRepositoryProvider).fetchQuestions(
          exam: widget.exam,
          subject: widget.subjectFilter,
          topic: widget.topicFilter,
          limit: 100,
        );

    final appBarActions = [
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
      )
    ];

    if (isFiltered) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.topicFilter ?? widget.subjectFilter} Test'),
          actions: appBarActions,
        ),
        body: FutureBuilder<List<Question>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No questions found.'));
            return _buildQuestionList(snapshot.data!);
          },
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$titleText Preparation'),
          actions: appBarActions,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All Questions'),
              Tab(text: 'By Subject'),
              Tab(text: 'By Chapter'),
            ],
          ),
        ),
        body: FutureBuilder<List<Question>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No questions found.'));
            
            final questions = snapshot.data!;
            return TabBarView(
              children: [
                _buildQuestionList(questions),
                _buildSubjectList(questions),
                _buildChapterList(questions),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionList(List<Question> questions) {
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
                  _Badge(text: q.topic, color: Colors.indigo),
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
  }

  Widget _buildSubjectList(List<Question> questions) {
    final subjectCount = <String, int>{};
    for (var q in questions) {
      if (q.subject.trim().isNotEmpty) {
        subjectCount[q.subject] = (subjectCount[q.subject] ?? 0) + 1;
      }
    }
    final subjects = subjectCount.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final sub = subjects[index];
        final count = subjectCount[sub]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.1),
              child: const Icon(Icons.book, color: Colors.indigo),
            ),
            title: Text(sub, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$count questions available'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuestionListScreen(
                  exam: widget.exam,
                  examDisplayName: widget.examDisplayName,
                  subjectFilter: sub,
                ),
              ));
            },
          ),
        );
      },
    );
  }

  Widget _buildChapterList(List<Question> questions) {
    final topicCount = <String, int>{};
    for (var q in questions) {
      if (q.topic.trim().isNotEmpty) {
        topicCount[q.topic] = (topicCount[q.topic] ?? 0) + 1;
      }
    }
    final topics = topicCount.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final top = topics[index];
        final count = topicCount[top]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey.withOpacity(0.1),
              child: const Icon(Icons.library_books, color: Colors.blueGrey),
            ),
            title: Text(top, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$count questions available'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuestionListScreen(
                  exam: widget.exam,
                  examDisplayName: widget.examDisplayName,
                  topicFilter: top,
                ),
              ));
            },
          ),
        );
      },
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
