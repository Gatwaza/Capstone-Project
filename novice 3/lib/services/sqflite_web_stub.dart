// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// Web stub for sqflite. Provides just enough types to compile.
// These are NEVER called on web — injection.dart guards all SQLite
// paths with !kIsWeb. This stub exists only for the Dart compiler.

class Database {
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    int? limit,
    String? orderBy,
  }) async => [];

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    dynamic conflictAlgorithm,
  }) async => 0;

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async => 0;

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async => 0;

  Future<void> execute(String sql) async {}
  Future<void> close() async {}
}

Future<Database> openDatabase(
  String path, {
  int? version,
  dynamic onCreate,
  dynamic onUpgrade,
}) async => Database();

class ConflictAlgorithm {
  const ConflictAlgorithm._(this._value);
  final int _value;
  static const replace = ConflictAlgorithm._(5);
  static const ignore  = ConflictAlgorithm._(4);
}
