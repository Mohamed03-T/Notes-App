import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_contract.dart';
import 'package:flutter/services.dart';
import '../../core/database/database_helper.dart';

/// BackupService
/// Provides automatic and manual backup capabilities for the app's SQLite database.
/// - Uses SharedPreferences to persist `backup_folder` (string) and `last_backup_time` (ISO string).
/// - Uses workmanager to schedule periodic background backups every 24 hours.
/// - Copies the SQLite database file found via `getDatabasesPath()` and `kDatabaseName`.
/// Notes:
/// - On Android devices where the user selected a SAF treeUri, that URI is stored as the `backup_folder` value
///   in SharedPreferences. This service will attempt to write to the path directly when it's a normal file system
///   path. If the path is a treeUri (starts with 'content://' or contains 'tree:'), the platform code must
///   perform the actual SAF write (the app already contains platform channel helpers elsewhere in the repo).
/// - All I/O is guarded with try/catch and logged via debugPrint to avoid crashing the app.

const String _kBackupFolderKey = 'backup_folder';
const String _kLastBackupTimeKey = 'last_backup_time';
const String _kAutoBackupEnabledKey = 'auto_backup_enabled';

const String _kWorkManagerTaskName = 'noty_auto_backup_task_v1';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  SharedPreferences? _prefs;
  final MethodChannel _storageChannel = const MethodChannel('noty/storage');

  /// Initialize SharedPreferences and Workmanager scheduler (if on supported platform)
  /// Call this early from main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> initBackupScheduler() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Initialize Workmanager only on Android/iOS (not on web/desktop)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Workmanager requires initialize with a callbackDispatcher
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: false,
        );

        // If user enabled auto-backup, ensure a periodic work is registered
        final enabled = _prefs?.getBool(_kAutoBackupEnabledKey) ?? false;
        if (enabled) {
          await _ensurePeriodicTaskRegistered();
        }
      }
    } catch (e, st) {
      debugPrint('BackupService.initBackupScheduler failed: $e\n$st');
    }
  }

  /// Register periodic work every 24 hours if not already registered.
  Future<void> _ensurePeriodicTaskRegistered() async {
    try {
      // Cancel any existing named tasks to avoid duplicates, then register fresh.
      await Workmanager().cancelByUniqueName(_kWorkManagerTaskName);

      await Workmanager().registerPeriodicTask(
        _kWorkManagerTaskName,
        _kWorkManagerTaskName,
        // frequency must be at least 15 minutes on Android; we request 24 hours here
        frequency: const Duration(hours: 24),
        initialDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
      );

      debugPrint('BackupService: periodic work registered');
    } catch (e, st) {
      debugPrint('BackupService._ensurePeriodicTaskRegistered failed: $e\n$st');
    }
  }

  /// Perform the actual backup operation: copy the SQLite DB file to the user-selected folder
  /// with the filename pattern: backup_YYYYMMDD_HHMM.db
  /// Returns true on success, false on failure.
  /// performBackup
  /// If [dbPathOverride] is provided it will be used instead of the app database path.
  Future<bool> performBackup({bool isManual = false, String? dbPathOverride}) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

  // Resolve database file path (allow override for tests)
  final dbPath = dbPathOverride ?? p.join(await getDatabasesPath(), kDatabaseName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        debugPrint('BackupService.performBackup: database file does not exist at $dbPath');
        return false;
      }

      // Read backup folder preference (prefer metadata in DB, fallback to SharedPreferences)
      final backupFolder = await getBackupFolder();

      String targetDirPath;

      if (backupFolder == null || backupFolder.isEmpty) {
        // No user folder set; fall back to application documents directory
        final appDoc = await getApplicationDocumentsDirectory();
  targetDirPath = appDoc.path;
      } else {
        targetDirPath = backupFolder;
      }

      // If folder looks like an Android treeUri (SAF), we cannot write directly from Dart/IO.
      // The app already contains platform channel helpers (noty/storage) to handle SAF writes.
      final looksLikeTree = targetDirPath.startsWith('content://') || targetDirPath.contains('tree:') || targetDirPath.startsWith('file_picker');

      final now = DateTime.now();
      final formatted = _formatTimestampForFile(now);
      final backupFileName = 'backup_${formatted}.db';

      if (looksLikeTree) {
        // Write via platform channel if available. We'll prepare a temp file and ask the
        // Android platform implementation to write it into the persisted treeUri.
        debugPrint('BackupService.performBackup: target is a SAF/treeUri, using platform write: $targetDirPath');
        final tmp = await getTemporaryDirectory();
        final tmpFile = File(p.join(tmp.path, backupFileName));
        await tmpFile.create(recursive: true);
        await dbFile.copy(tmpFile.path);

        try {
          final bytes = await tmpFile.readAsBytes();
          final ok = await _storageChannel.invokeMethod<bool>('writeFileToTree', {
            'treeUri': targetDirPath,
            'fileName': backupFileName,
            'bytes': bytes,
          });
          if (ok == true) {
            // prune via platform if available
            try { await _storageChannel.invokeMethod('pruneTreeBackups', {'treeUri': targetDirPath, 'prefix': 'backup_', 'keep': 6}); } catch (_) {}
            // remove tmp file
            try { await tmpFile.delete(); } catch (_) {}
            await _prefs?.setString(_kLastBackupTimeKey, now.toIso8601String());
            debugPrint('BackupService.performBackup: SAF write succeeded via platform for $targetDirPath');
            return true;
          } else {
            debugPrint('BackupService.performBackup: platform writeFileToTree returned false');
            return false;
          }
        } catch (e, st) {
          debugPrint('BackupService.performBackup: platform SAF write failed: $e\n$st');
          return false;
        }
      }

      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) {
        try {
          await targetDir.create(recursive: true);
        } catch (e) {
          debugPrint('BackupService.performBackup: failed to create targetDir $targetDirPath: $e');
          // fallback to app docs
          final appDoc = await getApplicationDocumentsDirectory();
          targetDirPath = appDoc.path;
        }
      }

      final destPath = p.join(targetDirPath, backupFileName);

      // Copy database file (perform an atomic copy by copying to temp then renaming)
      final tmpFile = File('${destPath}.tmp');
      await tmpFile.create(recursive: true);
      await dbFile.copy(tmpFile.path);
      // Rename temp to final file
      final finalFile = File(destPath);
      if (await finalFile.exists()) {
        // preserve old files - we will keep them; alternatively could overwrite
        final backupOld = File('${destPath}_${DateTime.now().millisecondsSinceEpoch}.old');
        await finalFile.rename(backupOld.path);
      }
      await tmpFile.rename(finalFile.path);

      // Record last backup time
      await _prefs?.setString(_kLastBackupTimeKey, now.toIso8601String());

      debugPrint('BackupService.performBackup: backup completed to ${finalFile.path}');

      return true;
    } catch (e, st) {
      debugPrint('BackupService.performBackup failed: $e\n$st');
      // Optionally write error to a file inside app dir
      try {
        final appDoc = await getApplicationDocumentsDirectory();
        final logFile = File(p.join(appDoc.path, 'backup_errors.log'));
        final msg = '${DateTime.now().toIso8601String()} - Backup error: $e\n';
        await logFile.writeAsString(msg, mode: FileMode.append);
      } catch (_) {}
      return false;
    }
  }

  /// Manual backup entrypoint callable from UI
  Future<bool> createManualBackup() async {
    try {
      return await performBackup(isManual: true);
    } catch (e, st) {
      debugPrint('BackupService.createManualBackup failed: $e\n$st');
      return false;
    }
  }

  /// Helper to format timestamp for file names: YYYYMMDD_HHMM
  String _formatTimestampForFile(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '${y}${m}${d}_${hh}${mm}';
  }

  /// Public helper for tests and callers
  static String formatTimestampForFile(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '${y}${m}${d}_${hh}${mm}';
  }

  /// Read last backup time from SharedPreferences
  Future<DateTime?> getLastBackupTime() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_kLastBackupTimeKey);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (e) {
      debugPrint('BackupService.getLastBackupTime failed: $e');
      return null;
    }
  }

  /// Save or update the user-selected backup folder.
  Future<void> setBackupFolder(String path) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      // Save to metadata (DB) as single source of truth and to SharedPreferences for backward compatibility
      try { await DatabaseHelper.instance.setMetadata('backup_dir', path); } catch (e) { debugPrint('Failed to write backup_dir to metadata: $e'); }
      await _prefs?.setString(_kBackupFolderKey, path);
    } catch (e) {
      debugPrint('BackupService.setBackupFolder failed: $e');
    }
  }

  /// Get stored backup folder (may be file system path or SAF treeUri)
  Future<String?> getBackupFolder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Prefer SharedPreferences first (safer in tests and for legacy users)
      final sp = prefs.getString(_kBackupFolderKey);
      if (sp != null && sp.isNotEmpty) return sp;
      // Fallback to metadata in DB if available
      try {
        final meta = await DatabaseHelper.instance.getMetadata('backup_dir');
        if (meta != null && meta.isNotEmpty) return meta;
      } catch (_) {}
      return null;
    } catch (e) {
      debugPrint('BackupService.getBackupFolder failed: $e');
      return null;
    }
  }

  /// Remove older local backup files by prefix, keep newest [keep] files.
  Future<void> pruneLocalBackups(String dirPath, String prefix, {int keep = 6}) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      final files = await dir.list().where((e) => e is File && p.basename(e.path).startsWith(prefix)).cast<File>().toList();
      if (files.length <= keep) return;
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final toDelete = files.skip(keep);
      for (final f in toDelete) {
        try { await f.delete(); } catch (_) {}
      }
    } catch (e) {
      debugPrint('pruneLocalBackups failed: $e');
    }
  }

  /// Enable or disable auto backup. When enabling, schedule the periodic task.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setBool(_kAutoBackupEnabledKey, enabled);
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (enabled) {
          await _ensurePeriodicTaskRegistered();
        } else {
          await Workmanager().cancelByUniqueName(_kWorkManagerTaskName);
        }
      }
    } catch (e) {
      debugPrint('BackupService.setAutoBackupEnabled failed: $e');
    }
  }

}

/// Top-level callbackDispatcher required by workmanager. Delegates to BackupService.
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Workmanager: executeTask -> $task');
    try {
      final svc = BackupService.instance;
      svc._prefs ??= await SharedPreferences.getInstance();
      final success = await svc.performBackup(isManual: false);
      debugPrint('Workmanager: backup success=$success');
      return Future.value(success);
    } catch (e, st) {
      debugPrint('Workmanager: backup failed in callback: $e\n$st');
      return Future.value(false);
    }
  });
}
