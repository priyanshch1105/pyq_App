import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pyq/core/theme/app_theme.dart';
import 'package:pyq/core/widgets/stat_card.dart';
import 'package:pyq/core/widgets/custom_app_bar.dart';

import 'package:pyq/features/practice/exam_selection_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Dashboard',
        backgroundColor: AppColors.bgDark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
              _buildHeroCard(context),
              const SizedBox(height: AppSpacing.xxl),

              // Stats Grid
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildStatsGrid(context),
              const SizedBox(height: AppSpacing.xxl),

              // Performance Section
              Text(
                'Performance Metrics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPerformanceMetrics(context),
              const SizedBox(height: AppSpacing.xxl),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back! 👋',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You are in top 5% today',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(context, '42', 'Questions', Colors.white),
              _buildMiniStat(context, '88%', 'Accuracy', Colors.white),
              _buildMiniStat(context, '7', 'Streak', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          label: 'Total Questions',
          value: '2,847',
          icon: Icons.assignment_outlined,
          textColor: AppColors.success,
        ),
        StatCard(
          label: 'This Week',
          value: '156',
          icon: Icons.calendar_today_outlined,
          textColor: AppColors.info,
        ),
        StatCard(
          label: 'Avg Time',
          value: '1.2m',
          icon: Icons.timer_outlined,
          textColor: AppColors.warning,
        ),
        StatCard(
          label: 'Current Goal',
          value: '75%',
          icon: Icons.flag_outlined,
          isHighlighted: true,
          textColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context) {
    return Column(
      children: [
        _buildMetricItem(context, 'Physics', '92%', 0.92, AppColors.info),
        const SizedBox(height: AppSpacing.lg),
        _buildMetricItem(context, 'Chemistry', '85%', 0.85, AppColors.warning),
        const SizedBox(height: AppSpacing.lg),
        _buildMetricItem(
          context,
          'Mathematics',
          '78%',
          0.78,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String subject,
    String percentage,
    double progress,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: Theme.of(context).textTheme.titleMedium),
              Text(
                percentage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExamSelectionScreen()),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Practice'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Detailed Analytics'),
          ),
        ),
      ],
    );
  }
}
