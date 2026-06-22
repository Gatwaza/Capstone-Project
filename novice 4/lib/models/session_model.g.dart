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
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 2,
      rateAccuracy: (json['rateAccuracy'] as num?)?.toDouble() ?? 0.0,
      depthAccuracy: (json['depthAccuracy'] as num?)?.toDouble() ?? 0.0,
      recoilAccuracy: (json['recoilAccuracy'] as num?)?.toDouble() ?? 0.0,
      ratePrecision: (json['ratePrecision'] as num?)?.toDouble() ?? 0.0,
      depthPrecision: (json['depthPrecision'] as num?)?.toDouble() ?? 0.0,
      recoilPrecision: (json['recoilPrecision'] as num?)?.toDouble() ?? 0.0,
      rateRecall: (json['rateRecall'] as num?)?.toDouble() ?? 0.0,
      depthRecall: (json['depthRecall'] as num?)?.toDouble() ?? 0.0,
      recoilRecall: (json['recoilRecall'] as num?)?.toDouble() ?? 0.0,
      rateF1: (json['rateF1'] as num?)?.toDouble() ?? 0.0,
      depthF1: (json['depthF1'] as num?)?.toDouble() ?? 0.0,
      recoilF1: (json['recoilF1'] as num?)?.toDouble() ?? 0.0,
      rateAuc: (json['rateAuc'] as num?)?.toDouble() ?? 0.0,
      depthAuc: (json['depthAuc'] as num?)?.toDouble() ?? 0.0,
      recoilAuc: (json['recoilAuc'] as num?)?.toDouble() ?? 0.0,
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
      'schemaVersion': instance.schemaVersion,
      'rateAccuracy': instance.rateAccuracy,
      'depthAccuracy': instance.depthAccuracy,
      'recoilAccuracy': instance.recoilAccuracy,
      'ratePrecision': instance.ratePrecision,
      'depthPrecision': instance.depthPrecision,
      'recoilPrecision': instance.recoilPrecision,
      'rateRecall': instance.rateRecall,
      'depthRecall': instance.depthRecall,
      'recoilRecall': instance.recoilRecall,
      'rateF1': instance.rateF1,
      'depthF1': instance.depthF1,
      'recoilF1': instance.recoilF1,
      'rateAuc': instance.rateAuc,
      'depthAuc': instance.depthAuc,
      'recoilAuc': instance.recoilAuc,
      'taskConfidences': instance.taskConfidences,
      'language': instance.language,
      'modelWasAvailable': instance.modelWasAvailable,
      'deviceModel': instance.deviceModel,
      'reviewLabel': instance.reviewLabel,
      'reviewNote': instance.reviewNote,
    };
