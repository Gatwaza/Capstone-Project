// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'research_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      userId: json['userId'] as String,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      studyGroup: $enumDecode(_$StudyGroupEnumMap, json['studyGroup']),
      ageRange: $enumDecode(_$AgeRangeEnumMap, json['ageRange']),
      priorCprTraining:
          $enumDecode(_$PriorCprTrainingEnumMap, json['priorCprTraining']),
      languagePreference: json['languagePreference'] as String? ?? 'en',
      consentGiven: json['consentGiven'] as bool? ?? false,
      consentTimestamp: json['consentTimestamp'] == null
          ? null
          : DateTime.parse(json['consentTimestamp'] as String),
      deviceModel: json['deviceModel'] as String?,
      osVersion: json['osVersion'] as String?,
      researcherNotes: json['researcherNotes'] as String?,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'enrolledAt': instance.enrolledAt.toIso8601String(),
      'studyGroup': _$StudyGroupEnumMap[instance.studyGroup]!,
      'ageRange': _$AgeRangeEnumMap[instance.ageRange]!,
      'priorCprTraining': _$PriorCprTrainingEnumMap[instance.priorCprTraining]!,
      'languagePreference': instance.languagePreference,
      'consentGiven': instance.consentGiven,
      'consentTimestamp': instance.consentTimestamp?.toIso8601String(),
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
      'researcherNotes': instance.researcherNotes,
    };

const _$StudyGroupEnumMap = {
  StudyGroup.groupA: 'groupA',
  StudyGroup.groupB: 'groupB',
};

const _$AgeRangeEnumMap = {
  AgeRange.under18: 'under18',
  AgeRange.age18to24: 'age18to24',
  AgeRange.age25to34: 'age25to34',
  AgeRange.age35to44: 'age35to44',
  AgeRange.age45plus: 'age45plus',
};

const _$PriorCprTrainingEnumMap = {
  PriorCprTraining.none: 'none',
  PriorCprTraining.watched: 'watched',
  PriorCprTraining.basic: 'basic',
  PriorCprTraining.recent: 'recent',
  PriorCprTraining.certified: 'certified',
};

_$ResearchSessionImpl _$$ResearchSessionImplFromJson(
        Map<String, dynamic> json) =>
    _$ResearchSessionImpl(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      deviceModel: json['deviceModel'] as String,
      osVersion: json['osVersion'] as String,
      studyGroup: $enumDecode(_$StudyGroupEnumMap, json['studyGroup']),
      modelWasActive: json['modelWasActive'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      totalCompressions: (json['totalCompressions'] as num?)?.toInt() ?? 0,
      meanBpm: (json['meanBpm'] as num?)?.toDouble() ?? 0.0,
      bpmStdDev: (json['bpmStdDev'] as num?)?.toDouble() ?? 0.0,
      meanDepthCm: (json['meanDepthCm'] as num?)?.toDouble() ?? 0.0,
      handPlacementAccuracyPct:
          (json['handPlacementAccuracyPct'] as num?)?.toDouble() ?? 0.0,
      elbowCompliancePct:
          (json['elbowCompliancePct'] as num?)?.toDouble() ?? 0.0,
      timeToFirstCompressionSec:
          (json['timeToFirstCompressionSec'] as num?)?.toDouble() ?? 0.0,
      cprFraction: (json['cprFraction'] as num?)?.toDouble() ?? 0.0,
      qualityScore: (json['qualityScore'] as num?)?.toInt() ?? 0,
      errorRates: (json['errorRates'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      susScore: (json['susScore'] as num?)?.toDouble(),
      nasaTlxScore: (json['nasaTlxScore'] as num?)?.toDouble(),
      nasaTlxSubscales:
          (json['nasaTlxSubscales'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toDouble()),
              ) ??
              const {},
      selfEfficacyPre: (json['selfEfficacyPre'] as num?)?.toDouble(),
      selfEfficacyPost: (json['selfEfficacyPost'] as num?)?.toDouble(),
      susItemResponses: (json['susItemResponses'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ResearchSessionImplToJson(
        _$ResearchSessionImpl instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'userId': instance.userId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
      'studyGroup': _$StudyGroupEnumMap[instance.studyGroup]!,
      'modelWasActive': instance.modelWasActive,
      'language': instance.language,
      'totalCompressions': instance.totalCompressions,
      'meanBpm': instance.meanBpm,
      'bpmStdDev': instance.bpmStdDev,
      'meanDepthCm': instance.meanDepthCm,
      'handPlacementAccuracyPct': instance.handPlacementAccuracyPct,
      'elbowCompliancePct': instance.elbowCompliancePct,
      'timeToFirstCompressionSec': instance.timeToFirstCompressionSec,
      'cprFraction': instance.cprFraction,
      'qualityScore': instance.qualityScore,
      'errorRates': instance.errorRates,
      'susScore': instance.susScore,
      'nasaTlxScore': instance.nasaTlxScore,
      'nasaTlxSubscales': instance.nasaTlxSubscales,
      'selfEfficacyPre': instance.selfEfficacyPre,
      'selfEfficacyPost': instance.selfEfficacyPost,
      'susItemResponses': instance.susItemResponses,
    };

_$FrameRecordImpl _$$FrameRecordImplFromJson(Map<String, dynamic> json) =>
    _$FrameRecordImpl(
      frameId: json['frameId'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      errorClass: json['errorClass'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      bpmEstimate: (json['bpmEstimate'] as num).toDouble(),
      wristDepthProxy: (json['wristDepthProxy'] as num).toDouble(),
      elbowAngleMean: (json['elbowAngleMean'] as num).toDouble(),
      spineVerticalityDeg: (json['spineVerticalityDeg'] as num).toDouble(),
      allLandmarksVisible: json['allLandmarksVisible'] as bool? ?? false,
      fromModel: json['fromModel'] as bool? ?? false,
    );

Map<String, dynamic> _$$FrameRecordImplToJson(_$FrameRecordImpl instance) =>
    <String, dynamic>{
      'frameId': instance.frameId,
      'sessionId': instance.sessionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'errorClass': instance.errorClass,
      'confidenceScore': instance.confidenceScore,
      'bpmEstimate': instance.bpmEstimate,
      'wristDepthProxy': instance.wristDepthProxy,
      'elbowAngleMean': instance.elbowAngleMean,
      'spineVerticalityDeg': instance.spineVerticalityDeg,
      'allLandmarksVisible': instance.allLandmarksVisible,
      'fromModel': instance.fromModel,
    };

_$FeedbackEventImpl _$$FeedbackEventImplFromJson(Map<String, dynamic> json) =>
    _$FeedbackEventImpl(
      eventId: json['eventId'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      promptKey: json['promptKey'] as String,
      language: json['language'] as String,
      triggeredByClass: json['triggeredByClass'] as String,
      severity: json['severity'] as String,
      wasSpoken: json['wasSpoken'] as bool? ?? false,
    );

Map<String, dynamic> _$$FeedbackEventImplToJson(_$FeedbackEventImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sessionId': instance.sessionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'promptKey': instance.promptKey,
      'language': instance.language,
      'triggeredByClass': instance.triggeredByClass,
      'severity': instance.severity,
      'wasSpoken': instance.wasSpoken,
    };

_$SusSurveyImpl _$$SusSurveyImplFromJson(Map<String, dynamic> json) =>
    _$SusSurveyImpl(
      sessionId: json['sessionId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      responses: (json['responses'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$SusSurveyImplToJson(_$SusSurveyImpl instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'completedAt': instance.completedAt.toIso8601String(),
      'responses': instance.responses,
    };

_$NasaTlxSurveyImpl _$$NasaTlxSurveyImplFromJson(Map<String, dynamic> json) =>
    _$NasaTlxSurveyImpl(
      sessionId: json['sessionId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      mentalDemand: (json['mentalDemand'] as num).toDouble(),
      physicalDemand: (json['physicalDemand'] as num).toDouble(),
      temporalDemand: (json['temporalDemand'] as num).toDouble(),
      performance: (json['performance'] as num).toDouble(),
      effort: (json['effort'] as num).toDouble(),
      frustration: (json['frustration'] as num).toDouble(),
    );

Map<String, dynamic> _$$NasaTlxSurveyImplToJson(_$NasaTlxSurveyImpl instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'completedAt': instance.completedAt.toIso8601String(),
      'mentalDemand': instance.mentalDemand,
      'physicalDemand': instance.physicalDemand,
      'temporalDemand': instance.temporalDemand,
      'performance': instance.performance,
      'effort': instance.effort,
      'frustration': instance.frustration,
    };

_$SelfEfficacySurveyImpl _$$SelfEfficacySurveyImplFromJson(
        Map<String, dynamic> json) =>
    _$SelfEfficacySurveyImpl(
      sessionId: json['sessionId'] as String,
      isPostSession: json['isPostSession'] as bool,
      confidence: (json['confidence'] as num).toInt(),
      rateConfidence: (json['rateConfidence'] as num).toInt(),
      depthConfidence: (json['depthConfidence'] as num).toInt(),
      willingnessToAct: (json['willingnessToAct'] as num).toInt(),
    );

Map<String, dynamic> _$$SelfEfficacySurveyImplToJson(
        _$SelfEfficacySurveyImpl instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'isPostSession': instance.isPostSession,
      'confidence': instance.confidence,
      'rateConfidence': instance.rateConfidence,
      'depthConfidence': instance.depthConfidence,
      'willingnessToAct': instance.willingnessToAct,
    };
