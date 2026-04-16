import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pyq/core/theme/app_theme.dart';
import 'package:pyq/features/questions/question_models.dart';
import 'package:pyq/features/questions/question_repository.dart';

enum MockExamType { jeeMain, neet, nda, upsc }

class MockExamConfig {
  const MockExamConfig({
    required this.type,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.positiveMark,
    required this.negativeMark,
    required this.accent,
    required this.icon,
    required this.instructions,
  });

  final MockExamType type;
  final String code;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final int totalQuestions;
  final double positiveMark;
  final double negativeMark;
  final Color accent;
  final IconData icon;
  final List<String> instructions;
}

const mockExamConfigs = <MockExamConfig>[
  MockExamConfig(
    type: MockExamType.jeeMain,
    code: 'JEE_MAIN',
    title: 'JEE Main Mock Test',
    subtitle: '75 questions | 180 minutes | CBT discipline',
    durationMinutes: 180,
    totalQuestions: 75,
    positiveMark: 4,
    negativeMark: 1,
    accent: Color(0xFF2563EB),
    icon: Icons.engineering_rounded,
    instructions: [
      'Use Save & Next to lock a response and move on.',
      'Mark for Review keeps the question in the purple bucket.',
      'Clear Response removes the selected option from the current question.',
      'Do not switch apps. Leave warnings can be triggered during the test.',
    ],
  ),
  MockExamConfig(
    type: MockExamType.neet,
    code: 'NEET',
    title: 'NEET Mock Test',
    subtitle: '180 questions | 200 minutes | pressure simulation',
    durationMinutes: 200,
    totalQuestions: 180,
    positiveMark: 4,
    negativeMark: 1,
    accent: Color(0xFFDC2626),
    icon: Icons.medical_services_rounded,
    instructions: [
      'Stay within the time limit; the timer auto-submits when it reaches zero.',
      'Every attempted question is tracked instantly in the palette.',
      'Mark questions for review only when you want to revisit them later.',
      'Answer order does not matter. You can jump freely between questions.',
    ],
  ),
  MockExamConfig(
    type: MockExamType.nda,
    code: 'NDA',
    title: 'NDA Mock Test',
    subtitle: '120 questions | 150 minutes | exam-room feel',
    durationMinutes: 150,
    totalQuestions: 120,
    positiveMark: 4,
    negativeMark: 1,
    accent: Color(0xFF0F766E),
    icon: Icons.shield_rounded,
    instructions: [
      'The question palette shows not visited, not answered, answered, and marked states.',
      'Save your answer before moving if you want the cell to turn green.',
      'Back navigation is blocked during the test.',
      'Final submission requires confirmation from the summary screen.',
    ],
  ),
  MockExamConfig(
    type: MockExamType.upsc,
    code: 'UPSC',
    title: 'UPSC Mock Test',
    subtitle: '100 questions | 120 minutes | serious practice',
    durationMinutes: 120,
    totalQuestions: 100,
    positiveMark: 2,
    negativeMark: 0.66,
    accent: Color(0xFF334155),
    icon: Icons.account_balance_rounded,
    instructions: [
      'Maintain exam pace. Time pressure is part of the simulation.',
      'Use the palette to navigate non-linearly without losing answer state.',
      'Review the summary before final submission.',
      'The analysis screen highlights weak subjects and the cost of negative marking.',
    ],
  ),
];

class NtaMockTestLauncherScreen extends StatelessWidget {
  const NtaMockTestLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Test Simulator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NTA CBT Simulator',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an exam and enter a strict CBT flow with a timer, question palette, mark-for-review states, and a final analysis report.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockExamConfigs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final config = mockExamConfigs[index];
              return _ExamCard(
                config: config,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MockTestInstructionsScreen(config: config),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MockTestInstructionsScreen extends ConsumerStatefulWidget {
  const MockTestInstructionsScreen({super.key, required this.config});

  final MockExamConfig config;

  @override
  ConsumerState<MockTestInstructionsScreen> createState() =>
      _MockTestInstructionsScreenState();
}

class _MockTestInstructionsScreenState
    extends ConsumerState<MockTestInstructionsScreen> {
  late final Future<List<Question>> _questionsFuture;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = ref
        .read(questionRepositoryProvider)
        .fetchQuestions(
          exam: widget.config.code,
          limit: widget.config.totalQuestions,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }
          final questions = snapshot.data ?? const <Question>[];
          if (questions.isEmpty) {
            return _ErrorState(
              message:
                  'No questions were returned for ${widget.config.title}. The backend needs seeded PYQs for this exam.',
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.config.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InstructionBanner(config: widget.config),
                        const SizedBox(height: 16),
                        _KeyStats(
                          config: widget.config,
                          totalLoaded: questions.length,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Before you begin',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...widget.config.instructions.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InstructionItem(text: item),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exam load',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${questions.length} questions are ready. The session will start immediately after you confirm the instructions.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _accepted,
                          onChanged: (value) =>
                              setState(() => _accepted = value ?? false),
                          title: const Text('I have read all instructions'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _accepted
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => NtaMockTestScreen(
                                          config: widget.config,
                                          questions: questions,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: const Text('Start Test'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NtaMockTestScreen extends StatefulWidget {
  const NtaMockTestScreen({
    super.key,
    required this.config,
    required this.questions,
  });

  final MockExamConfig config;
  final List<Question> questions;

  @override
  State<NtaMockTestScreen> createState() => _NtaMockTestScreenState();
}

class _NtaMockTestScreenState extends State<NtaMockTestScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late final Map<int, String?> _selectedAnswers;
  late final Set<int> _visited;
  late final Set<int> _marked;
  late final Map<int, DateTime> _openedAt;
  late final Map<int, Duration> _timeSpent;
  late final DateTime _startedAt;
  late final Timer _timer;
  int _currentIndex = 0;
  bool _submitting = false;
  bool _warningShown = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _selectedAnswers = <int, String?>{};
    _visited = <int>{0};
    _marked = <int>{};
    _openedAt = <int, DateTime>{0: DateTime.now()};
    _timeSpent = <int, Duration>{};
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      if (_remaining.inSeconds <= 0) {
        _autoSubmit();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !_warningShown &&
        mounted &&
        !_finished) {
      _warningShown = true;
      _showLeaveWarning();
    }
  }

  Duration get _remaining {
    final total = Duration(minutes: widget.config.durationMinutes);
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = total - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _recordTimeForIndex(int index) {
    final openedAt = _openedAt[index];
    if (openedAt == null) return;
    final spent = DateTime.now().difference(openedAt);
    _timeSpent[index] = (_timeSpent[index] ?? Duration.zero) + spent;
    _openedAt[index] = DateTime.now();
  }

  void _setCurrentQuestion(int index) {
    if (index == _currentIndex) return;
    _recordTimeForIndex(_currentIndex);
    setState(() {
      _currentIndex = index;
      _visited.add(index);
      _openedAt[index] = DateTime.now();
    });
  }

  void _goToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _saveAndNext() {
    setState(() {
      _visited.add(_currentIndex);
      if (_selectedAnswers[_currentIndex] != null) {
        _marked.remove(_currentIndex);
      }
    });
    if (_currentIndex < widget.questions.length - 1) {
      _goToQuestion(_currentIndex + 1);
    }
  }

  void _markForReviewAndNext() {
    setState(() {
      _visited.add(_currentIndex);
      _marked.add(_currentIndex);
    });
    if (_currentIndex < widget.questions.length - 1) {
      _goToQuestion(_currentIndex + 1);
    }
  }

  void _clearResponse() {
    setState(() {
      _selectedAnswers.remove(_currentIndex);
      _marked.remove(_currentIndex);
      _visited.add(_currentIndex);
    });
  }

  ExamQuestionState _stateForIndex(int index) {
    if (_marked.contains(index)) return ExamQuestionState.markedForReview;
    if (_selectedAnswers[index] != null) return ExamQuestionState.answered;
    if (_visited.contains(index)) return ExamQuestionState.notAnswered;
    return ExamQuestionState.notVisited;
  }

  int get _answeredCount => _selectedAnswers.entries
      .where((entry) => entry.value != null && !_marked.contains(entry.key))
      .length;
  int get _markedCount => _marked.length;
  int get _notAnsweredCount =>
      widget.questions.length - _answeredCount - _markedCount;

  Future<void> _showLeaveWarning() async {
    if (!mounted || _finished) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text('If you leave, your test may be submitted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _warningShown = false;
              },
              child: const Text('Return to test'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSubmitSummary({bool autoSubmit = false}) async {
    if (_finished || _submitting) return;
    _recordTimeForIndex(_currentIndex);
    setState(() => _submitting = true);

    final unanswered = _notAnsweredCount;
    final summary = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(autoSubmit ? 'Time is up' : 'Submit Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Answered: $_answeredCount'),
              const SizedBox(height: 4),
              Text('Not Answered: $unanswered'),
              const SizedBox(height: 4),
              Text('Marked for Review: $_markedCount'),
              const SizedBox(height: 12),
              Text(
                'Once you submit, the session will end and analysis will open immediately.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Review more'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Final Submit'),
            ),
          ],
        );
      },
    );

    if (summary != true) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    _finishTest();
  }

  void _autoSubmit() {
    if (_finished) return;
    _openSubmitSummary(autoSubmit: true);
  }

  void _finishTest() {
    if (!mounted || _finished) return;
    _finished = true;
    _timer.cancel();
    _recordTimeForIndex(_currentIndex);
    final report = _buildReport();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            MockTestResultScreen(config: widget.config, report: report),
      ),
    );
  }

  MockTestReport _buildReport() {
    final attemptedQuestions = <int>{};
    for (final entry in _selectedAnswers.entries) {
      if (entry.value != null) attemptedQuestions.add(entry.key);
    }

    int correct = 0;
    int wrong = 0;
    final subjectStats = <String, _SubjectStats>{};
    final chapterStats = <String, _ChapterStats>{};

    for (var index = 0; index < widget.questions.length; index++) {
      final question = widget.questions[index];
      final selected = _selectedAnswers[index];
      final correctAnswer = question.correctAnswer ?? '';
      if (selected != null) {
        final isCorrect = selected == correctAnswer;
        if (isCorrect) {
          correct += 1;
        } else {
          wrong += 1;
        }
      }

      final subjectEntry = subjectStats.putIfAbsent(
        question.subject,
        () => _SubjectStats(subject: question.subject),
      );
      subjectEntry.total += 1;
      if (selected != null) subjectEntry.attempted += 1;
      if (selected != null && selected == correctAnswer) {
        subjectEntry.correct += 1;
      } else if (selected != null) {
        subjectEntry.wrong += 1;
      }

      final chapterEntry = chapterStats.putIfAbsent(
        question.topic,
        () => _ChapterStats(chapter: question.topic),
      );
      chapterEntry.total += 1;
      if (selected != null) chapterEntry.attempted += 1;
      if (selected != null && selected == correctAnswer) {
        chapterEntry.correct += 1;
      } else if (selected != null) {
        chapterEntry.wrong += 1;
      }
    }

    final attempted = attemptedQuestions.length;
    final totalTime = _timeSpent.values.fold<Duration>(
      Duration.zero,
      (previousValue, element) => previousValue + element,
    );
    final totalSeconds = totalTime.inSeconds == 0
        ? DateTime.now().difference(_startedAt).inSeconds
        : totalTime.inSeconds;
    final accuracy = attempted == 0 ? 0.0 : correct / attempted;
    final score =
        (correct * widget.config.positiveMark) -
        (wrong * widget.config.negativeMark);

    final weakSubjects =
        subjectStats.values.where((stat) => stat.attempted > 0).toList()
          ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final weakChapters =
        chapterStats.values.where((stat) => stat.attempted > 0).toList()
          ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return MockTestReport(
      totalQuestions: widget.questions.length,
      attempted: attempted,
      answered: _answeredCount,
      marked: _markedCount,
      correct: correct,
      wrong: wrong,
      score: score,
      accuracy: accuracy,
      timeSpent: Duration(seconds: totalSeconds),
      subjectStats: subjectStats.values.toList()
        ..sort((a, b) => a.subject.compareTo(b.subject)),
      chapterStats: chapterStats.values.toList()
        ..sort((a, b) => a.chapter.compareTo(b.chapter)),
      negativeMarkingImpact: wrong * widget.config.negativeMark,
      insights: _buildInsights(
        weakSubjects,
        weakChapters,
        totalSeconds,
        wrong,
        attempted,
      ),
    );
  }

  List<String> _buildInsights(
    List<_SubjectStats> weakSubjects,
    List<_ChapterStats> weakChapters,
    int totalSeconds,
    int wrong,
    int attempted,
  ) {
    final insights = <String>[];
    if (weakSubjects.isNotEmpty) {
      insights.add('You are weak in ${weakSubjects.first.subject}.');
    }
    if (wrong >= 3 || (attempted > 0 && wrong / attempted >= 0.35)) {
      insights.add('Too many incorrect guesses.');
    }
    final avgSeconds = totalSeconds / widget.questions.length;
    if (avgSeconds > 90) {
      insights.add(
        'Time management issue in ${weakSubjects.isNotEmpty ? weakSubjects.first.subject : 'the test'}.',
      );
    }
    if (weakChapters.isNotEmpty) {
      insights.add(
        'Revise ${weakChapters.first.chapter} before your next mock test.',
      );
    }
    if (insights.isEmpty) {
      insights.add('Good pacing. Keep maintaining accuracy and discipline.');
    }
    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final isCritical = remaining.inMinutes < 15;

    return WillPopScope(
      onWillPop: () async {
        await _showLeaveWarning();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.config.title),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _CountdownChip(remaining: remaining, critical: isCritical),
            ),
            TextButton(
              onPressed: () => _openSubmitSummary(),
              child: const Text('Submit Test'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final questionPane = _QuestionPane(
              config: widget.config,
              questions: widget.questions,
              currentIndex: _currentIndex,
              selectedAnswers: _selectedAnswers,
              pageController: _pageController,
              onPageChanged: _setCurrentQuestion,
              onSelectOption: (index, answer) {
                setState(() {
                  _visited.add(index);
                  _selectedAnswers[index] = answer;
                });
              },
              onSaveAndNext: _saveAndNext,
              onMarkForReviewAndNext: _markForReviewAndNext,
              onClearResponse: _clearResponse,
            );

            final palette = _QuestionPalette(
              questions: widget.questions,
              currentIndex: _currentIndex,
              stateForIndex: _stateForIndex,
              onTap: _goToQuestion,
            );

            return Container(
              color: const Color(0xFFF8FAFC),
              child: wide
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: questionPane),
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: palette,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: questionPane),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: palette,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionPane extends StatelessWidget {
  const _QuestionPane({
    required this.config,
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.pageController,
    required this.onPageChanged,
    required this.onSelectOption,
    required this.onSaveAndNext,
    required this.onMarkForReviewAndNext,
    required this.onClearResponse,
  });

  final MockExamConfig config;
  final List<Question> questions;
  final int currentIndex;
  final Map<int, String?> selectedAnswers;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final void Function(int index, String answer) onSelectOption;
  final VoidCallback onSaveAndNext;
  final VoidCallback onMarkForReviewAndNext;
  final VoidCallback onClearResponse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: config.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Question ${currentIndex + 1} of ${questions.length}',
                  style: TextStyle(
                    color: config.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _LegendItem(color: Colors.grey.shade500, label: 'Not Visited'),
              const SizedBox(width: 12),
              _LegendItem(color: Colors.redAccent, label: 'Not Answered'),
              const SizedBox(width: 12),
              _LegendItem(color: Colors.green, label: 'Answered'),
              const SizedBox(width: 12),
              _LegendItem(color: Colors.purple, label: 'Marked'),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: questions.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final question = questions[index];
              final optionEntries = question.options.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              final selected = selectedAnswers[index];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _MetaBadge(text: question.subject),
                        const SizedBox(width: 8),
                        _MetaBadge(text: question.topic),
                        const SizedBox(width: 8),
                        _MetaBadge(text: '${question.year}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...optionEntries.asMap().entries.map((entry) {
                      final optionIndex = entry.key;
                      final option = entry.value;
                      final isSelected = selected == option.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onSelectOption(index, option.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? config.accent.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? config.accent
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? config.accent
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? config.accent
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      option.key,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.value.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Option ${optionIndex + 1}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      'Answer persists when you move between questions.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClearResponse,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: Colors.grey.shade400),
                        foregroundColor: Colors.grey.shade800,
                      ),
                      child: const Text('Clear Response'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMarkForReviewAndNext,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Colors.purple),
                        foregroundColor: Colors.purple,
                      ),
                      child: const Text('Mark for Review & Next'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSaveAndNext,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save & Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionPalette extends StatelessWidget {
  const _QuestionPalette({
    required this.questions,
    required this.currentIndex,
    required this.stateForIndex,
    required this.onTap,
  });

  final List<Question> questions;
  final int currentIndex;
  final ExamQuestionState Function(int index) stateForIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Palette',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _LegendPill(color: Colors.grey, label: 'Not Visited'),
                  _LegendPill(color: Colors.redAccent, label: 'Not Answered'),
                  _LegendPill(color: Colors.green, label: 'Answered'),
                  _LegendPill(color: Colors.purple, label: 'Marked'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final state = stateForIndex(index);
              final isCurrent = index == currentIndex;
              final background = switch (state) {
                ExamQuestionState.notVisited => Colors.grey.shade300,
                ExamQuestionState.notAnswered => Colors.redAccent,
                ExamQuestionState.answered => Colors.green,
                ExamQuestionState.markedForReview => Colors.purple,
              };

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: state == ExamQuestionState.notVisited
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MockTestResultScreen extends StatelessWidget {
  const MockTestResultScreen({
    super.key,
    required this.config,
    required this.report,
  });

  final MockExamConfig config;
  final MockTestReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [config.accent, config.accent.withOpacity(0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Score ${report.score.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(report.accuracy * 100).toStringAsFixed(1)}% accuracy',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  label: 'Attempted',
                  value: '${report.attempted}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResultMetric(
                  label: 'Correct',
                  value: '${report.correct}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(label: 'Wrong', value: '${report.wrong}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResultMetric(
                  label: 'Time / Q',
                  value:
                      '${(report.timeSpent.inMinutes / report.totalQuestions).toStringAsFixed(1)}m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResultMetric(
            label: 'Negative marking impact',
            value: '-${report.negativeMarkingImpact.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 18),
          _AnalysisCard(
            title: 'Subject-wise breakdown',
            child: Column(
              children: report.subjectStats
                  .map(
                    (stat) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProgressRow(
                        label: stat.subject,
                        value: stat.accuracy,
                        trailing:
                            '${(stat.accuracy * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _AnalysisCard(
            title: 'Chapter-wise performance',
            child: Column(
              children: report.chapterStats
                  .map(
                    (stat) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProgressRow(
                        label: stat.chapter,
                        value: stat.accuracy,
                        trailing:
                            '${(stat.accuracy * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _AnalysisCard(
            title: 'AI feedback',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: report.insights
                  .map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(insight)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _AnalysisCard(
            title: 'Recommendations',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecommendationChip(label: 'Revise weak topics'),
                _RecommendationChip(label: 'Suggested PYQs'),
                _RecommendationChip(label: 'Daily target: 50 questions'),
                _RecommendationChip(label: 'Take one timed mock tomorrow'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.config, required this.onTap});

  final MockExamConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: config.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(config.icon, color: config.accent),
            ),
            const SizedBox(height: 12),
            Text(config.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(config.subtitle, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            TextButton(
              onPressed: onTap,
              child: const Text('Open instructions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.config});

  final MockExamConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: config.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.accent.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.accent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'This test uses an NTA-style layout with a live countdown, answer palette, review states, and forced final submission.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyStats extends StatelessWidget {
  const _KeyStats({required this.config, required this.totalLoaded});

  final MockExamConfig config;
  final int totalLoaded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: 'Duration',
            value: '${config.durationMinutes} min',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniCard(label: 'Questions', value: '$totalLoaded'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniCard(
            label: 'Marking',
            value: '+${config.positiveMark}/-${config.negativeMark}',
          ),
        ),
      ],
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.remaining, required this.critical});

  final Duration remaining;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = remaining.inSeconds.clamp(0, 99 * 3600 + 59 * 60 + 59);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final color = critical ? Colors.redAccent : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final double value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Text(trailing),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  const _RecommendationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _SubjectStats {
  _SubjectStats({required this.subject});

  final String subject;
  int total = 0;
  int attempted = 0;
  int correct = 0;
  int wrong = 0;

  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

class _ChapterStats {
  _ChapterStats({required this.chapter});

  final String chapter;
  int total = 0;
  int attempted = 0;
  int correct = 0;
  int wrong = 0;

  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

class MockTestReport {
  const MockTestReport({
    required this.totalQuestions,
    required this.attempted,
    required this.answered,
    required this.marked,
    required this.correct,
    required this.wrong,
    required this.score,
    required this.accuracy,
    required this.timeSpent,
    required this.subjectStats,
    required this.chapterStats,
    required this.negativeMarkingImpact,
    required this.insights,
  });

  final int totalQuestions;
  final int attempted;
  final int answered;
  final int marked;
  final int correct;
  final int wrong;
  final double score;
  final double accuracy;
  final Duration timeSpent;
  final List<_SubjectStats> subjectStats;
  final List<_ChapterStats> chapterStats;
  final double negativeMarkingImpact;
  final List<String> insights;
}

enum ExamQuestionState { notVisited, notAnswered, answered, markedForReview }
