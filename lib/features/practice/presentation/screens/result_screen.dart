import 'package:flutter/material.dart';
import 'package:pyq/features/questions/question_models.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.question,
    required this.selectedAnswer,
  });

  final Map<String, dynamic> result;
  final Question question;
  final String selectedAnswer;

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = result['is_correct'] ?? false;
    final String correctAnswer = result['correct_answer'] ?? 'Unknown';
    final String explanation = result['explanation'] ?? 'No explanation provided.';

    final options = question.options.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isCorrect ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 80,
                    color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isCorrect ? 'Outstanding!' : 'Keep Learning',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isCorrect
                    ? 'You correctly solved this problem. Below is a detailed breakdown.'
                    : 'Take a close look at the analysis below to understand where you went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              const Text(
                'Question',
                style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                question.question,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Options Breakdown',
                style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = selectedAnswer == opt.key;
                final isActualCorrect = correctAnswer == opt.key;

                Color borderColor = Theme.of(context).dividerColor;
                Color bgColor = Theme.of(context).cardTheme.color ?? Colors.grey.shade900;
                IconData? icon;
                Color iconColor = Colors.transparent;

                if (isActualCorrect) {
                  borderColor = Colors.greenAccent;
                  bgColor = Colors.greenAccent.withOpacity(0.1);
                  icon = Icons.check_circle_rounded;
                  iconColor = Colors.greenAccent;
                } else if (isSelected && !isCorrect) {
                  borderColor = Colors.redAccent;
                  bgColor = Colors.redAccent.withOpacity(0.1);
                  icon = Icons.cancel_rounded;
                  iconColor = Colors.redAccent;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: isActualCorrect || (isSelected && !isCorrect) ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            opt.key,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          opt.value,
                          style: TextStyle(
                            fontSize: 16,
                            color: isActualCorrect ? Colors.greenAccent : (isSelected && !isCorrect ? Colors.redAccent : Colors.grey.shade300),
                          ),
                        ),
                      ),
                      if (icon != null)
                        Icon(icon, color: iconColor),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 12),
                        Text('Explanation', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      explanation,
                      style: const TextStyle(height: 1.6, fontSize: 15, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Questions'),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
