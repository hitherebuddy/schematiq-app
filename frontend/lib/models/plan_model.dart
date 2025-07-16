import 'package:flutter/material.dart';

/// Helper function to safely parse a value into an integer.
int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  if (value is double) {
    return value.toInt();
  }
  return 0;
}

class ToolInfo {
  final String name;
  final String description;
  final String link;
  final String cost;

  ToolInfo({
    required this.name,
    required this.description,
    required this.link,
    required this.cost,
  });

  factory ToolInfo.fromJson(Map<String, dynamic> json) {
    return ToolInfo(
      name: json['name'] ?? 'Unknown Tool',
      description: json['description'] ?? 'No description available.',
      link: json['link'] ?? '',
      cost: json['cost'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'link': link,
      'cost': cost,
    };
  }
}

class TimeEstimate {
  final int min;
  final int max;
  final String unit;

  TimeEstimate({required this.min, required this.max, required this.unit});

  factory TimeEstimate.fromJson(Map<String, dynamic> json) {
    return TimeEstimate(
      min: _parseInt(json['min']),
      max: _parseInt(json['max']),
      unit: json['unit'] ?? 'days',
    );
  }

  String get displayString {
    String unitLabel = unit;
    if (unit == 'minutes' && (min > 1 || max > 1)) unitLabel = 'mins';

    if ((min == 1 && max == 1) || (min == 0 && max == 1)) {
      if (unit.endsWith('s')) {
        unitLabel = unit.substring(0, unit.length - 1);
      }
    }

    if (min == max) {
      return '$min $unitLabel Est.';
    }
    return '$min-$max $unitLabel Est.';
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'unit': unit,
    };
  }
}

class Plan {
  final String id;
  final String title;
  final String mode;
  final List<PlanStep> steps;
  final String? estimatedDuration;
  final String? budgetLevel;
  final List<String> tags;

  Plan({
    required this.id,
    required this.title,
    required this.mode,
    required this.steps,
    this.estimatedDuration,
    this.budgetLevel,
    this.tags = const [],
  });

  bool get isPowerMode => mode == 'paid';

  double get progress {
    if (steps.isEmpty) return 0.0;
    final completedSteps = steps.where((step) => step.isComplete).length;
    return completedSteps / steps.length;
  }

  IconData get icon {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('clean')) return Icons.cleaning_services_rounded;
    if (lowerTitle.contains('launch') || lowerTitle.contains('product')) return Icons.rocket_launch_rounded;
    if (lowerTitle.contains('youtube') || lowerTitle.contains('brand')) return Icons.lightbulb_outline_rounded;
    if (lowerTitle.contains('travel') || lowerTitle.contains('trip')) return Icons.flight_takeoff_rounded;
    if (lowerTitle.contains('workout') || lowerTitle.contains('gym')) return Icons.fitness_center_rounded;
    return Icons.task_alt_rounded;
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    List<dynamic>? stepsList;
    Map<String, dynamic> metadataRoot = json;

    // --- DEFENSIVE PARSING LOGIC ---
    // This checks if the AI has incorrectly nested the plan data.
    if (json['steps'] is Map) {
      // If it's a map, the real 'steps' list is inside it.
      stepsList = json['steps']['steps'];
      // And the metadata is also inside that malformed object.
      metadataRoot = json['steps'];
    } else if (json['steps'] is List) {
      // If it's a list, the format is correct.
      stepsList = json['steps'];
    }

    List<PlanStep> parsedSteps = stepsList?.map((i) => PlanStep.fromJson(i as Map<String, dynamic>)).toList() ?? [];

    return Plan(
      id: json['id']?.toString() ?? metadataRoot['id']?.toString() ?? 'no-id',
      title: json['title'] ?? metadataRoot['title'] ?? 'Untitled Plan',
      mode: json['mode'] ?? metadataRoot['mode'] ?? 'free',
      steps: parsedSteps,
      estimatedDuration: metadataRoot['estimated_duration'],
      budgetLevel: metadataRoot['budget_level'],
      tags: metadataRoot['tags'] != null ? List<String>.from(metadataRoot['tags']) : [],
    );
  }

  Plan copyWith({
    String? id,
    String? title,
    String? mode,
    List<PlanStep>? steps,
    String? estimatedDuration,
    String? budgetLevel,
    List<String>? tags,
  }) {
    return Plan(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      steps: steps ?? this.steps,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'mode': mode,
      'estimated_duration': estimatedDuration,
      'budget_level': budgetLevel,
      'tags': tags,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

class PlanStep {
  final String id;
  final String title;
  final List<String> subtasks;
  final TimeEstimate timeEstimate;
  final String category;
  final bool isComplete;
  final List<ToolInfo>? powerTools;
  final String? potentialPitfall;
  final String? effort;
  final bool? isMilestone;

  PlanStep({
    required this.id,
    required this.title,
    required this.subtasks,
    required this.timeEstimate,
    required this.category,
    this.isComplete = false,
    this.powerTools,
    this.potentialPitfall,
    this.effort,
    this.isMilestone,
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    List<ToolInfo>? tools;
    if (json['power_tools'] != null && json['power_tools'] is List) {
      var toolList = json['power_tools'] as List;
      tools = toolList.map((i) => ToolInfo.fromJson(i as Map<String, dynamic>)).toList();
    }
    
    return PlanStep(
      id: json['id']?.toString() ?? 'default_id_${UniqueKey().toString()}',
      title: json['title'] ?? 'Untitled Step',
      subtasks: json['subtasks'] != null ? List<String>.from(json['subtasks']) : [],
      timeEstimate: json['time_estimate'] != null
          ? TimeEstimate.fromJson(json['time_estimate'])
          : TimeEstimate(min: 1, max: 1, unit: 'days'),
      category: json['category'] ?? 'General',
      isComplete: json['is_complete'] ?? false,
      powerTools: tools,
      potentialPitfall: json['potential_pitfall'],
      effort: json['effort'],
      isMilestone: json['is_milestone'],
    );
  }

  PlanStep copyWith({
    String? id,
    String? title,
    List<String>? subtasks,
    TimeEstimate? timeEstimate,
    String? category,
    bool? isComplete,
    List<ToolInfo>? powerTools,
    String? potentialPitfall,
    String? effort,
    bool? isMilestone,
  }) {
    return PlanStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtasks: subtasks ?? this.subtasks,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      category: category ?? this.category,
      isComplete: isComplete ?? this.isComplete,
      powerTools: powerTools ?? this.powerTools,
      potentialPitfall: potentialPitfall ?? this.potentialPitfall,
      effort: effort ?? this.effort,
      isMilestone: isMilestone ?? this.isMilestone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtasks': subtasks,
      'time_estimate': timeEstimate.toJson(),
      'category': category,
      'is_complete': isComplete,
      'power_tools': powerTools?.map((tool) => tool.toJson()).toList(),
      'potential_pitfall': potentialPitfall,
      'effort': effort,
      'is_milestone': isMilestone,
    };
  }
}