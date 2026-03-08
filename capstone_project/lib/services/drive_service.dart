import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/session_model.dart';

class DriveService {
  final GoogleSignIn _signIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
  GoogleSignInAccount? _account;
  bool get isSignedIn => _account != null;

  Future<bool> signIn() async {
    try {
      _account = await _signIn.signIn();
      return _account != null;
    } catch (e) {
      debugPrint('[DriveService] Sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
  }

  /// Upload a session as JSON to Google Drive under the capstone folder.
  Future<String?> uploadSession(CprSession session) async {
    if (_account == null) {
      final ok = await signIn();
      if (!ok) return null;
    }

    try {
      final authHeaders = await _account!.authHeaders;
      final client = _AuthenticatedClient(http.Client(), authHeaders);
      final driveApi = drive.DriveApi(client);

      // Ensure the capstone folder exists
      final folderId = await _ensureFolder(driveApi);

      final jsonStr = jsonEncode(session.toJson());
      final bytes = utf8.encode(jsonStr);
      final filename = '${AppConstants.exportFilePrefix}${session.id}.json';

      final media = drive.Media(Stream.fromIterable([bytes]), bytes.length,
          contentType: 'application/json');

      final fileMetadata = drive.File()
        ..name = filename
        ..parents = [folderId];

      final result = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      debugPrint('[DriveService] Uploaded: $filename (id=${result.id})');
      client.close();
      return result.id;
    } catch (e) {
      debugPrint('[DriveService] Upload error: $e');
      return null;
    }
  }

  Future<String> _ensureFolder(drive.DriveApi api) async {
    // Check if folder already exists
    final query =
        "mimeType='application/vnd.google-apps.folder' and name='${AppConstants.driveFolderName}' and trashed=false";
    final list = await api.files.list(q: query, spaces: 'drive');
    if (list.files != null && list.files!.isNotEmpty) {
      return list.files!.first.id!;
    }

    // Create folder
    final folder = drive.File()
      ..name = AppConstants.driveFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }
}

/// HTTP client that attaches Google auth headers to every request
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;
  _AuthenticatedClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _headers.forEach((k, v) => request.headers[k] = v);
    return _inner.send(request);
  }
}
