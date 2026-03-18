// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// Conditional path_provider import.
// path_provider DOES support web in recent versions, but getApplicationDocumentsDirectory
// is meaningless on web. All callers guard with kIsWeb. This compat file
// ensures clean compilation on all targets.

export 'package:path_provider/path_provider.dart';
