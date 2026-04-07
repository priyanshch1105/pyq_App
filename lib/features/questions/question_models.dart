class Question {
  Question({
    required this.id,
    required this.exam,
    required this.subject,
    required this.topic,
    required this.year,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.explanation,
  });

  final String id;
  final String exam;
  final String subject;
  final String topic;
  final int year;
  final int difficulty;
  final String question;
  final Map<String, dynamic> options;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      exam: json['exam'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      year: json['year'] as int,
      difficulty: json['difficulty'] as int,
      question: json['question'] as String,
      options: Map<String, dynamic>.from(json['options'] as Map),
      explanation: (json['explanation'] ?? '') as String,
    );
  }
}
