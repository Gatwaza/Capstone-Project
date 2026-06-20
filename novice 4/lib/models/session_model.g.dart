// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SessionModelImpl _$$SessionModelImplFromJson(Map<String, dynamic> json) =>
    _$SessionModelImpl(
      id: json['id'] as String,
      participantId: json['participantId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      totalCompressions: (json['totalCompressions'] as num).toInt(),
      meanBpm: (json['meanBpm'] as num).toDouble(),
      meanDepthCm: (json['meanDepthCm'] as num).toDouble(),
      cprFraction: (json['cprFraction'] as num).toDouble(),
      qualityScore: (json['qualityScore'] as num).toInt(),
      errorRates: (json['errorRates'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      taskAccuracies: (json['taskAccuracies'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      taskConfidences: (json['taskConfidences'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      language: json['language'] as String? ?? 'en',
      modelWasAvailable: json['modelWasAvailable'] as bool? ?? false,
      deviceModel: json['deviceModel'] as String?,
      reviewLabel: json['reviewLabel'] as String?,
      reviewNote: json['reviewNote'] as String?,
    );

Map<String, dynamic> _$$SessionModelImplToJson(_$SessionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participantId': instance.participantId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt.toIso8601String(),
      'totalCompressions': instance.totalCompressions,
      'meanBpm': instance.meanBpm,
      'meanDepthCm': instance.meanDepthCm,
      'cprFraction': instance.cprFraction,
      'qualityScore': instance.qualityScore,
      'errorRates': instance.errorRates,
      'taskAccuracies': instance.taskAccuracies,
      'taskConfidences': instance.taskConfidences,
      'language': instance.language,
      'modelWasAvailable': instance.modelWasAvailable,
      'deviceModel': instance.deviceModel,
      'reviewLabel': instance.reviewLabel,
      'reviewNote': instance.reviewNote,
    };
