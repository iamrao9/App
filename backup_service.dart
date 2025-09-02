
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  // Create an OAuth 2.0 Client ID (Android) in Google Cloud Console and configure SHA-1.
  final GoogleSignIn _gsi = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  Future<String> getDatabasesPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _dbFile() async {
    final dbDir = await getDatabasesPath();
    return File(p.join(dbDir, 'maharaja.db'));
  }

  Future<void> backupToDrive(BuildContext ctx) async {
    try {
      final account = await _gsi.signIn();
      if (account == null) return;
      final authHeaders = await account.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      final api = drive.DriveApi(client);

      final file = await _dbFile();
      if (!await file.exists()) {
        _snack(ctx, 'Database empty.');
        return;
      }
      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File()
        ..name = 'maharaja_backup.db'
        ..mimeType = 'application/octet-stream';

      final list = await api.files.list(q: "name='maharaja_backup.db' and trashed=false", $fields: 'files(id,name)');
      if (list.files != null && list.files!.isNotEmpty) {
        final id = list.files!.first.id!;
        await api.files.update(driveFile, id, uploadMedia: media);
      } else {
        await api.files.create(driveFile, uploadMedia: media);
      }
      _snack(ctx, 'Backup completed to Google Drive.');
    } catch (e) {
      _snack(ctx, 'Backup failed: $e');
    }
  }

  Future<void> restoreFromDrive(BuildContext ctx) async {
    try {
      final account = await _gsi.signIn();
      if (account == null) return;
      final authHeaders = await account.authHeaders;
      final client = _GoogleAuthClient(authHeaders);
      final api = drive.DriveApi(client);

      final list = await api.files.list(q: "name='maharaja_backup.db' and trashed=false", $fields: 'files(id,name)');
      if (list.files == null || list.files!.isEmpty) {
        _snack(ctx, 'No backup found.');
        return;
      }
      final id = list.files!.first.id!;
      final media = await api.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      final file = await _dbFile();
      await file.writeAsBytes(bytes, flush: true);
      _snack(ctx, 'Restore completed. Restart app.');
    } catch (e) {
      _snack(ctx, 'Restore failed: $e');
    }
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = IOClient();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
