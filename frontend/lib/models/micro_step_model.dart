class MicroStep {
  final String title;
  final String explanation;
  final String example;

  MicroStep({
    required this.title,
    required this.explanation,
    required this.example,
  });

  factory MicroStep.fromJson(Map<String, dynamic> json) {
    return MicroStep(
      title: json['title'] ?? 'Untitled Micro-Step',
      explanation: json['explanation'] ?? 'No explanation available.',
      example: json['example'] ?? 'No example available.',
    );
  }
}