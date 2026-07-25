// Required for web. `flutter test -d chrome` only works for mobile/desktop
// integration tests — web still goes through the older `flutter drive` path,
// which needs this driver file as the bridge between the browser and the
// test runner. Don't add test logic here; it just wires the two together.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
