// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// Conditional sqflite import.
// On mobile: real sqflite package.
// On web: stub (sqflite does not support web).
// All code that imports this file can use Database, openDatabase, ConflictAlgorithm
// on both platforms — calls are guarded by kIsWeb at runtime.

export 'package:sqflite/sqflite.dart'
    if (dart.library.html) 'sqflite_web_stub.dart';
