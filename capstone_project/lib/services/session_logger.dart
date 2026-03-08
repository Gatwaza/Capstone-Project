import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/session_model.dart';

class SessionLogger {
  Database? _db;

  Future<void> initialize() async {
    final path = join(await getDatabasesPath(), 'capstone_sessions.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_seconds INTEGER NOT NULL,
            avg_bpm REAL,
            rate_score REAL NOT NULL,
            posture_score REAL NOT NULL,
            overall_score REAL NOT NULL,
            total_compressions INTEGER NOT NULL,
            language TEXT NOT NULL,
            events_json TEXT NOT NULL
          )
        ''');
      },
    );
    debugPrint('[SessionLogger] Database initialized');
  }

  Future<void> saveSession(CprSession session) async {
    if (_db == null) return;
    try {
      await _db!.insert(
        'sessions',
        {
          'id': session.id,
          'started_at': session.startedAt.toIso8601String(),
          'ended_at': session.endedAt?.toIso8601String(),
          'duration_seconds': session.durationSeconds,
          'avg_bpm': session.avgBpm,
          'rate_score': session.rateAdherenceScore,
          'posture_score': session.postureScore,
          'overall_score': session.overallScore,
          'total_compressions': session.totalCompressions,
          'language': session.language,
          'events_json': jsonEncode(session.events.map((e) => e.toJson()).toList()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[SessionLogger] Session saved: ${session.id}');
    } catch (e) {
      debugPrint('[SessionLogger] Save error: $e');
    }
  }

  Future<List<CprSession>> getAllSessions() async {
    if (_db == null) return [];
    final rows = await _db!.query('sessions', orderBy: 'started_at DESC');
    return rows.map(_rowToSession).toList();
  }

  Future<CprSession?> getSession(String id) async {
    if (_db == null) return null;
    final rows = await _db!.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToSession(rows.first);
  }

  Future<void> deleteSession(String id) async {
    await _db?.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getStats() async {
    if (_db == null) return {};
    final rows = await _db!.query('sessions');
    if (rows.isEmpty) return {'total': 0};
    final scores = rows.map((r) => r['overall_score'] as double).toList();
    final best = scores.reduce((a, b) => a > b ? a : b);
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return {
      'total': rows.length,
      'bestScore': best,
      'avgScore': avg,
      'lastSession': rows.first['started_at'],
    };
  }

  CprSession _rowToSession(Map<String, dynamic> row) {
    final eventsJson = jsonDecode(row['events_json'] as String) as List;
    return CprSession(
      id: row['id'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      endedAt: row['ended_at'] != null ? DateTime.parse(row['ended_at'] as String) : null,
      durationSeconds: row['duration_seconds'] as int,
      avgBpm: row['avg_bpm'] as double?,
      rateAdherenceScore: row['rate_score'] as double,
      postureScore: row['posture_score'] as double,
      overallScore: row['overall_score'] as double,
      totalCompressions: row['total_compressions'] as int,
      language: row['language'] as String,
      events: eventsJson.map((e) => FeedbackEvent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
