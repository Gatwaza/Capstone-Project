// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Mobile session persistence via SQLite (sqflite).
// Only instantiated on iOS/Android — guarded by kIsWeb in injection.dart.
// File compiles on web via conditional package imports (stubs).

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'sqflite_compat.dart';          // conditional: sqflite on mobile, stub on web
import 'path_provider_compat.dart';    // conditional: path_provider on mobile, stub on web
import '../models/session_model.dart';

class SessionLogger {
  SessionLogger();

  static const _dbName = 'novice_sessions.db';
  static const _schemaVersion = 1;
  static const _table = 'sessions';

  Database? _db;
  final _log = Logger();

  Future<void> init() async {
    if (kIsWeb) return;  // no-op on web; storage handled by StorageService
    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(path, version: _schemaVersion,
        onCreate: _createSchema, onUpgrade: _migrate);
    _log.i('SessionLogger: opened at $path');
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id            TEXT PRIMARY KEY,
        started_at    TEXT NOT NULL, ended_at TEXT NOT NULL,
        compressions  INTEGER NOT NULL, mean_bpm REAL NOT NULL,
        mean_depth_cm REAL NOT NULL,   cpr_fraction REAL NOT NULL,
        quality_score INTEGER NOT NULL, error_rates TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        model_used INTEGER NOT NULL DEFAULT 0, device_model TEXT
      )
    ''');
  }

  Future<void> _migrate(Database db, int o, int n) async {}

  Future<void> saveSession(SessionModel s) async {
    if (kIsWeb) return;
    await _db?.insert(_table, {
      'id': s.id, 'started_at': s.startedAt.toIso8601String(),
      'ended_at': s.endedAt.toIso8601String(),
      'compressions': s.totalCompressions, 'mean_bpm': s.meanBpm,
      'mean_depth_cm': s.meanDepthCm, 'cpr_fraction': s.cprFraction,
      'quality_score': s.qualityScore, 'error_rates': jsonEncode(s.errorRates),
      'language': s.language, 'model_used': s.modelWasAvailable ? 1 : 0,
      'device_model': s.deviceModel,
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
  );

  Future<void> dispose() async => _db?.close();
}
