class Question {
  final int? id;
  final int quizId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String? optionC;
  final String? optionD;
  final String correctOption;
  final DateTime? createdAt;

  Question({
    this.id,
    required this.quizId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    this.optionC,
    this.optionD,
    required this.correctOption,
    this.createdAt,
  });

  // Convert a Question object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Convert a Map into a Question object
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      quizId: map['quiz_id'],
      questionText: map['question_text'],
      optionA: map['option_a'],
      optionB: map['option_b'],
      optionC: map['option_c'],
      optionD: map['option_d'],
      correctOption: map['correct_option'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }
}
