// Test-only overrides for services `configureDependencies()` (injection.dart)
// registers as real, network/browser-backed singletons.
//
// Deliberately NOT touching injection.dart. main() still runs unmodified —
// call these AFTER app.main() to swap specific GetIt registrations before
// pumping a fresh screen that reads from them.
//
// Honest scope: TtsService and TelemetryService are concrete classes with
// no interface, so "override" here means re-registering a lightweight real
// instance where possible, not a mock. ParticipantService talks to Supabase
// directly via the `http` package with no injected client, so it CANNOT be
// faked without either (a) adding an `http.Client` constructor parameter to
// ParticipantService, or (b) leaving Env unconfigured in the test build and
// asserting on the resulting "not configured" UI path — which is what
// participant_gate_flow_test.dart and consent_flow_test.dart do below.
// If you want registerParticipant() to succeed in a test, the real fix is
// (a): inject an http.Client into ParticipantService's constructor so tests
// can pass a MockClient. Flag this to Ron before writing a "happy path"
// enrolment test — it doesn't exist yet.

import 'package:get_it/get_it.dart';
import 'package:novice/core/di/injection.dart';
import 'package:novice/services/platform/telemetry_service.dart';

/// Replaces the TelemetryService singleton with a no-op so tests don't
/// write real rows to Supabase on every run.
class NoopTelemetryService implements TelemetryService {
  final List<String> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString());
    return null;
  }
}

void overrideTelemetryForTesting() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<TelemetryService>()) {
    getIt.unregister<TelemetryService>();
  }
  getIt.registerSingleton<TelemetryService>(NoopTelemetryService());
}