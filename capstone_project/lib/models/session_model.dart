import 'package:equatable/equatable.dart';

class CprSession extends Equatable {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final double? avgBpm;
  final double rateAdherenceScore; // 0.0–1.0
  final double postureScore;        // 0.0–1.0
  final double overallScore;        // 0.0–1.0
  final int totalCompressions;
  final String language;
  final List<FeedbackEvent> events;

  const CprSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    this.avgBpm,
    required this.rateAdherenceScore,
    required this.postureScore,
    required this.overallScore,
    required this.totalCompressions,
    required this.language,
    required this.events,
  });

  bool get isComplete => endedAt != null;

  String get scoreGrade {
    if (overallScore >= 0.85) return 'Excellent';
    if (overallScore >= 0.70) return 'Good';
    if (overallScore >= 0.50) return 'Fair';
    return 'Needs Practice';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'durationSeconds': durationSeconds,
    'avgBpm': avgBpm,
    'rateAdherenceScore': rateAdherenceScore,
    'postureScore': postureScore,
    'overallScore': overallScore,
    'totalCompressions': totalCompressions,
    'language': language,
    'events': events.map((e) => e.toJson()).toList(),
  };

  factory CprSession.fromJson(Map<String, dynamic> j) => CprSession(
    id: j['id'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    endedAt: j['endedAt'] != null ? DateTime.parse(j['endedAt'] as String) : null,
    durationSeconds: j['durationSeconds'] as int,
    avgBpm: (j['avgBpm'] as num?)?.toDouble(),
    rateAdherenceScore: (j['rateAdherenceScore'] as num).toDouble(),
    postureScore: (j['postureScore'] as num).toDouble(),
    overallScore: (j['overallScore'] as num).toDouble(),
    totalCompressions: j['totalCompressions'] as int,
    language: j['language'] as String,
    events: (j['events'] as List)
        .map((e) => FeedbackEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  List<Object?> get props => [id];
}

class FeedbackEvent extends Equatable {
  final int frameIndex;
  final String promptKey;
  final int priority;
  final double? bpmAtEvent;
  final String label; // classifier label at this moment

  const FeedbackEvent({
    required this.frameIndex,
    required this.promptKey,
    required this.priority,
    this.bpmAtEvent,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'frameIndex': frameIndex,
    'promptKey': promptKey,
    'priority': priority,
    'bpmAtEvent': bpmAtEvent,
    'label': label,
  };

  factory FeedbackEvent.fromJson(Map<String, dynamic> j) => FeedbackEvent(
    frameIndex: j['frameIndex'] as int,
    promptKey: j['promptKey'] as String,
    priority: j['priority'] as int,
    bpmAtEvent: (j['bpmAtEvent'] as num?)?.toDouble(),
    label: j['label'] as String,
  );

  @override
  List<Object?> get props => [frameIndex, promptKey];
}
