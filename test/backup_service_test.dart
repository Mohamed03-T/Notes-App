import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:note_app/services/backup/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('formatTimestampForFile produces expected pattern', () {
      final dt = DateTime(2025, 10, 19, 14, 5);
      final s = BackupService.formatTimestampForFile(dt);
      expect(s, '20251019_1405');
    });

    test('performBackup copies file to target folder and sets last_backup_time', () async {
      // create temp directories and file
      final tmp = await Directory.systemTemp.createTemp('noty_test');
      final dbFile = File(p.join(tmp.path, 'testdb.db'));
      await dbFile.writeAsString('hello');

      // prepare target backup folder
      final target = await Directory.systemTemp.createTemp('noty_backups');

      // set SharedPreferences backup_folder to the target path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_folder', target.path);

      // call performBackup with dbPathOverride pointing to our temp db
      final ok = await BackupService.instance.performBackup(isManual: true, dbPathOverride: dbFile.path);
      expect(ok, isTrue);

      // check last_backup_time is set
      final last = prefs.getString('last_backup_time');
      expect(last, isNotNull);

      // check a backup file exists in target dir
      final files = await target.list().where((e) => e is File && p.basename(e.path).startsWith('backup_')).toList();
      expect(files.isNotEmpty, true);

      // cleanup
      try { await tmp.delete(recursive: true); } catch (_) {}
      try { await target.delete(recursive: true); } catch (_) {}
    });

    test('performBackup with fake SAF uri should fail gracefully', () async {
      final tmp = await Directory.systemTemp.createTemp('noty_test_saf');
      final dbFile = File(p.join(tmp.path, 'testdb.db'));
      await dbFile.writeAsString('hello');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_folder', 'content://com.example.invalid/tree/primary:Backup');

      // Mock the platform MethodChannel to return false for writeFileToTree
      const channel = MethodChannel('noty/storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'writeFileToTree') return false;
        return null;
      });

      final ok = await BackupService.instance.performBackup(isManual: true, dbPathOverride: dbFile.path);
      // With mocked platform returning false, expect performBackup to return false for SAF
      expect(ok, isFalse);

      // Clear mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);

      try { await tmp.delete(recursive: true); } catch (_) {}
    });

    test('pruneLocalBackups keeps newest files only', () async {
      final dir = await Directory.systemTemp.createTemp('noty_prune');
      // create 6 files with prefix
      for (int i = 0; i < 8; i++) {
        final f = File(p.join(dir.path, 'backup_20251019_12${i}.db'));
        await f.writeAsString('x');
        // modify timestamp so sorting deterministic
        final mod = DateTime.now().subtract(Duration(minutes: i));
        await f.setLastModified(mod);
      }
      await BackupService.instance.pruneLocalBackups(dir.path, 'backup_', keep: 3);
      final remaining = await dir.list().where((e) => e is File && p.basename(e.path).startsWith('backup_')).toList();
      expect(remaining.length, 3);
      try { await dir.delete(recursive: true); } catch (_) {}
    });
  });
}
