class ForecastEvent {
  final String stepTitle;
  final DateTime startDate;
  final DateTime endDate;
  final String effort;
  final bool isMilestone;

  ForecastEvent({
    required this.stepTitle,
    required this.startDate,
    required this.endDate,
    required this.effort,
    required this.isMilestone,
  });

  factory ForecastEvent.fromJson(Map<String, dynamic> json) {
    return ForecastEvent(
      stepTitle: json['step_title'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      effort: json['effort'],
      isMilestone: json['is_milestone'],
    );
  }
}