import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pyq/core/theme/app_theme.dart';
import 'package:pyq/features/mock_test/nta_mock_test_screen.dart';

enum PyqMode { chapterWise, yearWise, mockTest }

class PyqFilterState {
  const PyqFilterState({
    required this.subject,
    required this.year,
    required this.mode,
  });

  final String subject;
  final int year;
  final PyqMode mode;

  PyqFilterState copyWith({String? subject, int? year, PyqMode? mode}) {
    return PyqFilterState(
      subject: subject ?? this.subject,
      year: year ?? this.year,
      mode: mode ?? this.mode,
    );
  }
}

class PyqFilterNotifier extends StateNotifier<PyqFilterState> {
  PyqFilterNotifier()
    : super(
        const PyqFilterState(
          subject: 'Physics',
          year: 2025,
          mode: PyqMode.chapterWise,
        ),
      );

  void setSubject(String subject) => state = state.copyWith(subject: subject);
  void setYear(int year) => state = state.copyWith(year: year);
  void setMode(PyqMode mode) => state = state.copyWith(mode: mode);
}

final pyqFilterProvider =
    StateNotifierProvider<PyqFilterNotifier, PyqFilterState>(
      (ref) => PyqFilterNotifier(),
    );

class PyqSectionScreen extends ConsumerWidget {
  const PyqSectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(pyqFilterProvider);
    final chapters = _chapterBank
        .where((chapter) => chapter.subject == filters.subject)
        .where((chapter) => chapter.years.contains(filters.year))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(color: AppColors.primary.withOpacity(0.18)),
          ),
          Positioned(
            top: 260,
            left: -120,
            child: _GlowBlob(color: AppColors.primaryLight.withOpacity(0.12)),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 20,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PYQ Practice',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select Subject / Chapter / Year',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Filter panel coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search coming soon')),
                      );
                    },
                    icon: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterStrip(filters: filters),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: filters.mode == PyqMode.chapterWise
                            ? 'Chapters'
                            : filters.mode == PyqMode.yearWise
                            ? 'Year Buckets'
                            : 'Mock Tests',
                        subtitle: filters.mode == PyqMode.chapterWise
                            ? 'Tap a card to open a focused question list.'
                            : filters.mode == PyqMode.yearWise
                            ? 'Review the most relevant year-wise sets first.'
                            : 'Use exam-like timed sets for speed and accuracy.',
                      ),
                    ],
                  ),
                ),
              ),
              if (filters.mode == PyqMode.chapterWise)
                if (chapters.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: _EmptyState(
                        title: 'No chapters found',
                        subtitle:
                            'Try a different subject or year to load the PYQ cards.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.55,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final chapter = chapters[index];
                        return _ChapterCard(
                          chapter: chapter,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PyqQuestionScreen(
                                title: chapter.title,
                                subtitle:
                                    '${filters.subject} • ${filters.year}',
                                questions: chapter.questions,
                              ),
                            ),
                          ),
                        );
                      }, childCount: chapters.length),
                    ),
                  ),
              if (filters.mode == PyqMode.yearWise)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final yearSet = _yearBank[index];
                      return _YearCard(
                        yearSet: yearSet,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PyqQuestionScreen(
                              title: 'PYQ ${yearSet.year}',
                              subtitle: '${filters.subject} • Year-wise',
                              questions: yearSet.questions,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemCount: _yearBank.length,
                  ),
                ),
              if (filters.mode == PyqMode.mockTest)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final mock = _mockTests[index];
                      return _MockTestCard(
                        test: mock,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NtaMockTestLauncherScreen(),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemCount: _mockTests.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Practice Modes',
                        subtitle:
                            'Fast entry points for solving, testing, and revision.',
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        title: 'Practice Questions',
                        description:
                            'Jump straight into the chapter list with instant feedback.',
                        icon: Icons.play_circle_fill_rounded,
                        accent: AppColors.primary,
                        onTap: () => ref
                            .read(pyqFilterProvider.notifier)
                            .setMode(PyqMode.chapterWise),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        title: 'Start Mock Test',
                        description:
                            'Timed exam flow with cleaner pacing and a single submit action.',
                        icon: Icons.timer_rounded,
                        accent: AppColors.info,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NtaMockTestLauncherScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        title: 'Quick Revision (15 min quiz)',
                        description:
                            'Short, focused sets that surface weak topics quickly.',
                        icon: Icons.bolt_rounded,
                        accent: AppColors.warning,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PyqQuestionScreen(
                              title: 'Quick Revision',
                              subtitle: '15 minute quiz',
                              questions: _quickRevisionQuestions,
                              isTimedTest: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AnalyticsSection(
                    accuracy: 0.86,
                    attempted: 1264,
                    total: 1738,
                    weakTopics: const [
                      'Electrostatics',
                      'Organic Mechanisms',
                      'Matrices',
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }
}

class PyqQuestionScreen extends StatefulWidget {
  const PyqQuestionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.questions,
    this.isTimedTest = false,
  });

  final String title;
  final String subtitle;
  final List<PyqQuestion> questions;
  final bool isTimedTest;

  @override
  State<PyqQuestionScreen> createState() => _PyqQuestionScreenState();
}

class _PyqQuestionScreenState extends State<PyqQuestionScreen> {
  late final PageController _pageController;
  late final List<int?> _selections;
  late final List<bool> _submitted;
  late final List<bool> _showSolution;
  late final Set<int> _bookmarked;
  late final DateTime _startedAt;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selections = List<int?>.filled(widget.questions.length, null);
    _submitted = List<bool>.filled(widget.questions.length, false);
    _showSolution = List<bool>.filled(widget.questions.length, false);
    _bookmarked = <int>{};
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Question ${_currentIndex + 1} of ${widget.questions.length}'),
            const SizedBox(height: 2),
            Text(widget.title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          if (widget.isTimedTest)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _TimerPill(startedAt: _startedAt),
            ),
          IconButton(
            onPressed: () => setState(() {
              if (_bookmarked.contains(_currentIndex)) {
                _bookmarked.remove(_currentIndex);
              } else {
                _bookmarked.add(_currentIndex);
              }
            }),
            icon: Icon(
              _bookmarked.contains(_currentIndex)
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final item = widget.questions[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _QuestionMetaRow(question: item),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          item.text,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(item.options.length, (optionIndex) {
                        final isSelected = _selections[index] == optionIndex;
                        final isCorrect = item.correctIndex == optionIndex;
                        final submitted = _submitted[index];
                        final shouldHighlight =
                            submitted && (isSelected || isCorrect);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: submitted
                                ? null
                                : () => setState(
                                    () => _selections[index] = optionIndex,
                                  ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: shouldHighlight
                                    ? (isCorrect
                                          ? AppColors.success.withOpacity(0.12)
                                          : AppColors.error.withOpacity(0.12))
                                    : isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: shouldHighlight
                                      ? (isCorrect
                                            ? AppColors.success
                                            : AppColors.error)
                                      : isSelected
                                      ? AppColors.primary
                                      : Theme.of(context).dividerColor,
                                  width: shouldHighlight || isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: shouldHighlight
                                            ? (isCorrect
                                                  ? AppColors.success
                                                  : AppColors.error)
                                            : isSelected
                                            ? AppColors.primary
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + optionIndex),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium?.color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.options[optionIndex],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(height: 1.4),
                                    ),
                                  ),
                                  if (submitted && isCorrect)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                    ),
                                  if (submitted && isSelected && !isCorrect)
                                    const Icon(
                                      Icons.cancel_rounded,
                                      color: AppColors.error,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _submitted[index]
                            ? Container(
                                key: ValueKey<bool>(_showSolution[index]),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Answer submitted',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                    if (_showSolution[index]) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Solution',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.explanation,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (_submitted[_currentIndex])
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _showSolution[_currentIndex] =
                              !_showSolution[_currentIndex];
                        }),
                        icon: Icon(
                          _showSolution[_currentIndex]
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        label: Text(
                          _showSolution[_currentIndex]
                              ? 'Hide Solution'
                              : 'Show Solution',
                        ),
                      ),
                    ),
                  if (_submitted[_currentIndex]) const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitted[_currentIndex]
                              ? null
                              : _selections[_currentIndex] == null
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pick an option first.'),
                                    ),
                                  );
                                }
                              : () {
                                  setState(() {
                                    _submitted[_currentIndex] = true;
                                    _showSolution[_currentIndex] = true;
                                  });
                                },
                          child: Text(
                            _submitted[_currentIndex] ? 'Submitted' : 'Submit',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _currentIndex == widget.questions.length - 1
                              ? () => Navigator.of(context).maybePop()
                              : () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                          ),
                          child: Text(
                            _currentIndex == widget.questions.length - 1
                                ? 'Finish'
                                : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip({required this.filters});

  final PyqFilterState filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pyqFilterProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Filters',
          subtitle: 'Adjust subject, year, and practice mode.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SegmentGroup<String>(
                items: const ['Physics', 'Chemistry', 'Math'],
                selected: filters.subject,
                onChanged: notifier.setSubject,
              ),
              const SizedBox(width: 12),
              _SegmentGroup<int>(
                items: const [2025, 2024, 2023, 2022, 2021],
                selected: filters.year,
                onChanged: notifier.setYear,
              ),
              const SizedBox(width: 12),
              _SegmentGroup<PyqMode>(
                items: const [
                  PyqMode.chapterWise,
                  PyqMode.yearWise,
                  PyqMode.mockTest,
                ],
                selected: filters.mode,
                onChanged: notifier.setMode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentGroup<T> extends StatelessWidget {
  const _SegmentGroup({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<T> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;
        return InkWell(
          onTap: () => onChanged(item),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    )
                  : null,
              color: isSelected ? null : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Theme.of(context).dividerColor,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Text(
              _labelFor(item),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _labelFor(T item) {
    if (item is PyqMode) {
      switch (item) {
        case PyqMode.chapterWise:
          return 'Chapter-wise';
        case PyqMode.yearWise:
          return 'Year-wise';
        case PyqMode.mockTest:
          return 'Mock Test';
      }
    }
    return item.toString();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.onTap});

  final PyqChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              chapter.accent.withOpacity(0.16),
              Theme.of(context).cardTheme.color ?? Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chapter.accent.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: chapter.accent.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chapter.accent.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(chapter.icon, color: chapter.accent),
                ),
                const Spacer(),
                _DifficultyTag(level: chapter.difficulty),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              chapter.title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${chapter.totalQuestions} questions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(chapter.progress * 100).toStringAsFixed(0)}% solved',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  chapter.latestYearLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: chapter.progress,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).dividerColor.withOpacity(0.35),
                color: chapter.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearCard extends StatelessWidget {
  const _YearCard({required this.yearSet, required this.onTap});

  final PyqYearSet yearSet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '${yearSet.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    yearSet.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${yearSet.questionCount} questions • ${yearSet.accuracyLabel} accuracy',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: yearSet.accuracy,
                    minHeight: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.35),
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _MockTestCard extends StatelessWidget {
  const _MockTestCard({required this.test, required this.onTap});

  final PyqMockTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              test.accent.withOpacity(0.14),
              Theme.of(context).cardTheme.color ?? Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: test.accent.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: test.accent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(test.icon, color: test.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    test.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniStat(label: '${test.questionCount} Qs'),
                      const SizedBox(width: 10),
                      _MiniStat(label: '${test.durationMinutes} min'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.18), accent.withOpacity(0.06)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.accuracy,
    required this.attempted,
    required this.total,
    required this.weakTopics,
  });

  final double accuracy;
  final int attempted;
  final int total;
  final List<String> weakTopics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Analytics',
            subtitle: 'Clear signal on accuracy, coverage, and weak areas.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Accuracy',
                  value: '${(accuracy * 100).toStringAsFixed(1)}%',
                  accent: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Attempted',
                  value: '$attempted',
                  accent: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total',
                  value: '$total',
                  accent: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Coverage',
                  value: '${(attempted / total * 100).toStringAsFixed(0)}%',
                  accent: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: accuracy,
              minHeight: 10,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.35),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Weak topics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weakTopics
                .map(
                  (topic) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      topic,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
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

class _QuestionMetaRow extends StatelessWidget {
  const _QuestionMetaRow({required this.question});

  final PyqQuestion question;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetaChip(label: question.subject),
        const SizedBox(width: 8),
        _MetaChip(label: question.chapter),
        const SizedBox(width: 8),
        _MetaChip(label: '${question.year}'),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TimerPill extends StatefulWidget {
  const _TimerPill({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_TimerPill> createState() => _TimerPillState();
}

class _TimerPillState extends State<_TimerPill> {
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final elapsed = DateTime.now().difference(widget.startedAt);
        final mins = elapsed.inMinutes.toString().padLeft(2, '0');
        final secs = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_rounded,
                size: 14,
                color: AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                '$mins:$secs',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.warning),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _DifficultyTag extends StatelessWidget {
  const _DifficultyTag({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level.toLowerCase()) {
      'easy' => AppColors.success,
      'medium' => AppColors.warning,
      _ => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class PyqChapter {
  const PyqChapter({
    required this.title,
    required this.subject,
    required this.totalQuestions,
    required this.difficulty,
    required this.progress,
    required this.years,
    required this.accent,
    required this.icon,
    required this.questions,
  });

  final String title;
  final String subject;
  final int totalQuestions;
  final String difficulty;
  final double progress;
  final List<int> years;
  final Color accent;
  final IconData icon;
  final List<PyqQuestion> questions;

  String get latestYearLabel => 'Updated ${years.first}';
}

class PyqYearSet {
  const PyqYearSet({
    required this.year,
    required this.label,
    required this.questionCount,
    required this.accuracy,
    required this.questions,
  });

  final int year;
  final String label;
  final int questionCount;
  final double accuracy;
  final List<PyqQuestion> questions;

  String get accuracyLabel => '${(accuracy * 100).toStringAsFixed(0)}%';
}

class PyqMockTest {
  const PyqMockTest({
    required this.title,
    required this.subtitle,
    required this.questionCount,
    required this.durationMinutes,
    required this.icon,
    required this.accent,
    required this.questions,
  });

  final String title;
  final String subtitle;
  final int questionCount;
  final int durationMinutes;
  final IconData icon;
  final Color accent;
  final List<PyqQuestion> questions;
}

class PyqQuestion {
  const PyqQuestion({
    required this.subject,
    required this.chapter,
    required this.year,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String subject;
  final String chapter;
  final int year;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

const _physicsQuestions = [
  PyqQuestion(
    subject: 'Physics',
    chapter: 'Thermodynamics',
    year: 2025,
    text:
        'For an ideal gas, which process keeps the internal energy unchanged while temperature remains constant?',
    options: [
      'Isothermal process',
      'Adiabatic process',
      'Isochoric process',
      'Isobaric process',
    ],
    correctIndex: 0,
    explanation:
        'For an ideal gas, internal energy depends only on temperature. If temperature is constant, internal energy stays unchanged.',
  ),
  PyqQuestion(
    subject: 'Physics',
    chapter: 'Electrostatics',
    year: 2024,
    text:
        'The electric field inside a conductor in electrostatic equilibrium is:',
    options: [
      'Maximum at the surface',
      'Zero everywhere',
      'Finite and uniform',
      'Depends on charge density',
    ],
    correctIndex: 1,
    explanation:
        'Charges redistribute until the net electric field inside the conductor becomes zero.',
  ),
  PyqQuestion(
    subject: 'Physics',
    chapter: 'Current Electricity',
    year: 2023,
    text: 'The SI unit of resistivity is:',
    options: ['Ohm', 'Ohm-meter', 'Siemens', 'Volt-meter'],
    correctIndex: 1,
    explanation: 'Resistivity has unit ohm-meter (Ω·m).',
  ),
];

const _chemistryQuestions = [
  PyqQuestion(
    subject: 'Chemistry',
    chapter: 'Chemical Bonding',
    year: 2025,
    text: 'The shape of ammonia molecule is best described as:',
    options: ['Linear', 'Trigonal planar', 'Tetrahedral', 'Trigonal pyramidal'],
    correctIndex: 3,
    explanation:
        'Due to one lone pair on nitrogen, NH3 has trigonal pyramidal geometry.',
  ),
  PyqQuestion(
    subject: 'Chemistry',
    chapter: 'Organic Mechanisms',
    year: 2024,
    text: 'Which reagent commonly converts alcohols to alkyl halides?',
    options: ['NaOH', 'SOCl2', 'H2SO4', 'KMnO4'],
    correctIndex: 1,
    explanation:
        'Thionyl chloride is widely used to convert alcohols to alkyl chlorides.',
  ),
  PyqQuestion(
    subject: 'Chemistry',
    chapter: 'Solutions',
    year: 2023,
    text: 'Raoult’s law applies most directly to:',
    options: [
      'Non-volatile ideal solutions',
      'Solids only',
      'Gases only',
      'Electrolytes only',
    ],
    correctIndex: 0,
    explanation:
        'Raoult’s law is used for ideal liquid solutions, especially with non-volatile components.',
  ),
];

const _mathQuestions = [
  PyqQuestion(
    subject: 'Math',
    chapter: 'Matrices',
    year: 2025,
    text: 'If a matrix has determinant zero, it is:',
    options: ['Diagonal', 'Singular', 'Orthogonal', 'Identity'],
    correctIndex: 1,
    explanation:
        'A zero determinant means the matrix is singular and not invertible.',
  ),
  PyqQuestion(
    subject: 'Math',
    chapter: 'Calculus',
    year: 2024,
    text: 'The derivative of sin x is:',
    options: ['cos x', '-cos x', 'sin x', '-sin x'],
    correctIndex: 0,
    explanation: 'd/dx(sin x) = cos x.',
  ),
  PyqQuestion(
    subject: 'Math',
    chapter: 'Probability',
    year: 2023,
    text: 'For two independent events A and B, P(A and B) equals:',
    options: ['P(A) + P(B)', 'P(A)P(B)', 'P(A)/P(B)', 'P(A) - P(B)'],
    correctIndex: 1,
    explanation: 'Independent events satisfy P(A ∩ B) = P(A) × P(B).',
  ),
];

final List<PyqChapter> _chapterBank = [
  PyqChapter(
    title: 'Thermodynamics',
    subject: 'Physics',
    totalQuestions: 118,
    difficulty: 'Medium',
    progress: 0.72,
    years: [2025, 2024, 2023],
    accent: const Color(0xFF2563EB),
    icon: Icons.local_fire_department_rounded,
    questions: _physicsQuestions,
  ),
  PyqChapter(
    title: 'Electrostatics',
    subject: 'Physics',
    totalQuestions: 96,
    difficulty: 'Hard',
    progress: 0.49,
    years: [2025, 2024, 2023],
    accent: const Color(0xFF7C3AED),
    icon: Icons.bolt_rounded,
    questions: _physicsQuestions,
  ),
  PyqChapter(
    title: 'Chemical Bonding',
    subject: 'Chemistry',
    totalQuestions: 104,
    difficulty: 'Easy',
    progress: 0.81,
    years: [2025, 2024, 2022],
    accent: const Color(0xFF0EA5E9),
    icon: Icons.science_rounded,
    questions: _chemistryQuestions,
  ),
  PyqChapter(
    title: 'Organic Mechanisms',
    subject: 'Chemistry',
    totalQuestions: 87,
    difficulty: 'Hard',
    progress: 0.37,
    years: [2025, 2024, 2023],
    accent: const Color(0xFFEF4444),
    icon: Icons.biotech_rounded,
    questions: _chemistryQuestions,
  ),
  PyqChapter(
    title: 'Matrices',
    subject: 'Math',
    totalQuestions: 112,
    difficulty: 'Medium',
    progress: 0.63,
    years: [2025, 2024, 2023],
    accent: const Color(0xFF8B5CF6),
    icon: Icons.grid_4x4_rounded,
    questions: _mathQuestions,
  ),
  PyqChapter(
    title: 'Calculus',
    subject: 'Math',
    totalQuestions: 149,
    difficulty: 'Hard',
    progress: 0.44,
    years: [2025, 2024, 2021],
    accent: const Color(0xFF14B8A6),
    icon: Icons.functions_rounded,
    questions: _mathQuestions,
  ),
];

final List<PyqYearSet> _yearBank = [
  PyqYearSet(
    year: 2025,
    label: 'Latest exam set',
    questionCount: 72,
    accuracy: 0.84,
    questions: _physicsQuestions + _chemistryQuestions + _mathQuestions,
  ),
  PyqYearSet(
    year: 2024,
    label: 'High-frequency questions',
    questionCount: 68,
    accuracy: 0.78,
    questions: _physicsQuestions + _chemistryQuestions,
  ),
  PyqYearSet(
    year: 2023,
    label: 'Revision set',
    questionCount: 64,
    accuracy: 0.73,
    questions: _chemistryQuestions + _mathQuestions,
  ),
];

final List<PyqMockTest> _mockTests = [
  PyqMockTest(
    title: 'Full Syllabus Mock',
    subtitle: '180 questions • exam pace',
    questionCount: 180,
    durationMinutes: 180,
    icon: Icons.workspace_premium_rounded,
    accent: AppColors.primary,
    questions: _physicsQuestions + _chemistryQuestions + _mathQuestions,
  ),
  PyqMockTest(
    title: 'Mixed Subject Sprint',
    subtitle: 'Balanced practice across all subjects',
    questionCount: 60,
    durationMinutes: 60,
    icon: Icons.shuffle_rounded,
    accent: AppColors.info,
    questions: _physicsQuestions + _chemistryQuestions,
  ),
];

final List<PyqQuestion> _quickRevisionQuestions = [
  _physicsQuestions.first,
  _chemistryQuestions.first,
  _mathQuestions.first,
];
