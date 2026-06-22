// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Mobile session persistence via SQLite (sqflite).
// Schema v3: adds CNN-BiLSTM research metrics columns
// (accuracy, precision, recall, f1, auc per task).

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'sqflite_compat.dart';
import 'path_provider_compat.dart';
import '../models/session_model.dart';

class SessionLogger {
  SessionLogger();

  static const _dbName = 'novice_sessions.db';
  static const _schemaVersion = 3;
  static const _table = 'sessions';

  Database? _db;
  final _log = Logger();

  Future<void> init() async {
    if (kIsWeb) return;
    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(path, version: _schemaVersion,
        onCreate: _createSchema, onUpgrade: _migrate);
    _log.i('SessionLogger: opened at $path');
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id                TEXT PRIMARY KEY,
        participant_id    TEXT NOT NULL DEFAULT '',
        started_at        TEXT NOT NULL,
        ended_at          TEXT NOT NULL,
        compressions      INTEGER NOT NULL,
        mean_bpm          REAL NOT NULL,
        mean_depth_cm     REAL NOT NULL,
        cpr_fraction      REAL NOT NULL,
        quality_score     INTEGER NOT NULL,
        error_rates       TEXT NOT NULL,
        language          TEXT NOT NULL DEFAULT 'en',
        model_used        INTEGER NOT NULL DEFAULT 0,
        device_model      TEXT,
        rate_accuracy     REAL NOT NULL DEFAULT 0,
        depth_accuracy    REAL NOT NULL DEFAULT 0,
        recoil_accuracy   REAL NOT NULL DEFAULT 0,
        rate_precision    REAL NOT NULL DEFAULT 0,
        depth_precision   REAL NOT NULL DEFAULT 0,
        recoil_precision  REAL NOT NULL DEFAULT 0,
        rate_recall       REAL NOT NULL DEFAULT 0,
        depth_recall      REAL NOT NULL DEFAULT 0,
        recoil_recall     REAL NOT NULL DEFAULT 0,
        rate_f1           REAL NOT NULL DEFAULT 0,
        depth_f1          REAL NOT NULL DEFAULT 0,
        recoil_f1         REAL NOT NULL DEFAULT 0,
        rate_auc          REAL NOT NULL DEFAULT 0,
        depth_auc         REAL NOT NULL DEFAULT 0,
        recoil_auc        REAL NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $_table ADD COLUMN participant_id TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 3) {
      // Add CNN-BiLSTM research metric columns
      for (final col in [
        'rate_accuracy', 'depth_accuracy', 'recoil_accuracy',
        'rate_precision', 'depth_precision', 'recoil_precision',
        'rate_recall', 'depth_recall', 'recoil_recall',
        'rate_f1', 'depth_f1', 'recoil_f1',
        'rate_auc', 'depth_auc', 'recoil_auc',
      ]) {
        await db.execute(
          'ALTER TABLE $_table ADD COLUMN $col REAL NOT NULL DEFAULT 0',
        );
      }
    }
  }

  Future<void> saveSession(SessionModel s) async {
    if (kIsWeb) return;
    await _db?.insert(_table, {
      'id': s.id,
      'participant_id': s.participantId,
      'started_at': s.startedAt.toIso8601String(),
      'ended_at': s.endedAt.toIso8601String(),
      'compressions': s.totalCompressions,
      'mean_bpm': s.meanBpm,
      'mean_depth_cm': s.meanDepthCm,
      'cpr_fraction': s.cprFraction,
      'quality_score': s.qualityScore,
      'error_rates': jsonEncode(s.errorRates),
      'language': s.language,
      'model_used': s.modelWasAvailable ? 1 : 0,
      'device_model': s.deviceModel,
      // Research metrics
      'rate_accuracy':    s.rateAccuracy,
      'depth_accuracy':   s.depthAccuracy,
      'recoil_accuracy':  s.recoilAccuracy,
      'rate_precision':   s.ratePrecision,
      'depth_precision':  s.depthPrecision,
      'recoil_precision': s.recoilPrecision,
      'rate_recall':      s.rateRecall,
      'depth_recall':     s.depthRecall,
      'recoil_recall':    s.recoilRecall,
      'rate_f1':          s.rateF1,
      'depth_f1':         s.depthF1,
      'recoil_f1':        s.recoilF1,
      'rate_auc':         s.rateAuc,
      'depth_auc':        s.depthAuc,
      'recoil_auc':       s.recoilAuc,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SessionModel>> loadAllSessions() async {
    if (kIsWeb) return [];
    final rows = await _db?.query(_table, orderBy: 'started_at DESC') ?? [];
    return rows.map(_row).toList();
  }

  Future<SessionModel?> loadSession(String id) async {
    if (kIsWeb) return null;
    final rows = await _db?.query(_table, where: 'id=?', whereArgs: [id], limit: 1) ?? [];
    return rows.isEmpty ? null : _row(rows.first);
  }

  Future<void> deleteSession(String id) async {
    await _db?.delete(_table, where: 'id=?', whereArgs: [id]);
  }

  Future<String> exportJson() async {
    final sessions = await loadAllSessions();
    return jsonEncode(sessions.map((s) => s.toJson()).toList());
  }

  SessionModel _row(Map<String, dynamic> r) => SessionModel(
    id: r['id'] as String,
    participantId: r['participant_id'] as String? ?? '',
    startedAt: DateTime.parse(r['started_at'] as String),
    endedAt: DateTime.parse(r['ended_at'] as String),
    totalCompressions: r['compressions'] as int,
    meanBpm: (r['mean_bpm'] as num).toDouble(),
    meanDepthCm: (r['mean_depth_cm'] as num).toDouble(),
    cprFraction: (r['cpr_fraction'] as num).toDouble(),
    qualityScore: r['quality_score'] as int,
    errorRates: Map<String, double>.from(jsonDecode(r['error_rates'] as String) as Map),
    language: r['language'] as String? ?? 'en',
    modelWasAvailable: (r['model_used'] as int) == 1,
    deviceModel: r['device_model'] as String?,
    rateAccuracy:    (r['rate_accuracy']    as num?)?.toDouble() ?? 0.0,
    depthAccuracy:   (r['depth_accuracy']   as num?)?.toDouble() ?? 0.0,
    recoilAccuracy:  (r['recoil_accuracy']  as num?)?.toDouble() ?? 0.0,
    ratePrecision:   (r['rate_precision']   as num?)?.toDouble() ?? 0.0,
    depthPrecision:  (r['depth_precision']  as num?)?.toDouble() ?? 0.0,
    recoilPrecision: (r['recoil_precision'] as num?)?.toDouble() ?? 0.0,
    rateRecall:      (r['rate_recall']      as num?)?.toDouble() ?? 0.0,
    depthRecall:     (r['depth_recall']     as num?)?.toDouble() ?? 0.0,
    recoilRecall:    (r['recoil_recall']    as num?)?.toDouble() ?? 0.0,
    rateF1:          (r['rate_f1']          as num?)?.toDouble() ?? 0.0,
    depthF1:         (r['depth_f1']         as num?)?.toDouble() ?? 0.0,
    recoilF1:        (r['recoil_f1']        as num?)?.toDouble() ?? 0.0,
    rateAuc:         (r['rate_auc']         as num?)?.toDouble() ?? 0.0,
    depthAuc:        (r['depth_auc']        as num?)?.toDouble() ?? 0.0,
    recoilAuc:       (r['recoil_auc']       as num?)?.toDouble() ?? 0.0,
  );

  Future<void> dispose() async => _db?.close();
}
