// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Stub for permission_handler on web.
// permission_handler is a mobile-only plugin; web uses browser permission dialogs.
// This stub is imported on web via the conditional import in training_screen.dart:
//   import 'package:permission_handler/permission_handler.dart'
//       if (dart.library.html) '../../core/utils/permission_stub.dart';

/// No-op permission status — web always grants permissions via browser dialog.
class Permission {
  static final camera = _WebPermission();
}

class _WebPermission {
  Future<PermissionStatus> request() async => PermissionStatus.granted;
  Future<PermissionStatus> get status async => PermissionStatus.granted;
}

class PermissionStatus {
  const PermissionStatus._(this._value);
  final int _value;

  static const granted = PermissionStatus._(1);
  static const denied  = PermissionStatus._(0);

  bool get isGranted => _value == 1;
}

/// No-op on web — mobile-only.
Future<void> openAppSettings() async {}
