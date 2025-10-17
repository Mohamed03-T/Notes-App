import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/language_manager.dart';
import '../../utils/responsive.dart';
import '../../core/layout/layout_helpers.dart';
import '../../widgets/app_logo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database_helper.dart';
import '../../repositories/notes_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// conditional import for web download helper
import '../../utils/web_file_utils_stub.dart'
  if (dart.library.html) '../../utils/web_file_utils_web.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoBackupEnabled = false;
  DateTime? _lastAutoBackup;
  Timer? _autoBackupTimer;
  String? _backupDirPath;
  static const MethodChannel _storageChannel = MethodChannel('noty/storage');

  Future<String?> _requestTreeAccess() async {
    try {
      final res = await _storageChannel.invokeMethod<String>('requestTreeAccess');
      return res;
    } catch (e) {
      debugPrint('requestTreeAccess failed: $e');
      return null;
    }
  }

  Future<bool> _writeBackupToFile(String json, {bool promptSave = false}) async {
    try {
      Directory? targetDir;
      if (kIsWeb) {
        // On web we won't use path_provider; handled later by webDownloadString
        targetDir = null;
      } else {
        try {
          // Prefer Downloads on platforms that support it
          targetDir = await getDownloadsDirectory();
        } catch (_) {
          // This can throw MissingPluginException if native plugin isn't registered
          targetDir = null;
        }
      }

      if (targetDir == null) {
        // On Android, try using external storage Downloads directory
        try {
          final downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (downloadsDirs != null && downloadsDirs.isNotEmpty) {
            targetDir = downloadsDirs.first;
          } else {
            final extDir = await getExternalStorageDirectory();
            if (extDir != null) {
              // Try to find a Downloads folder relative to extDir
              final candidate = Directory('${extDir.path}/Download');
              if (await candidate.exists()) {
                targetDir = candidate;
              } else {
                targetDir = extDir;
              }
            }
          }
        } catch (e, st) {
          debugPrint('Error resolving storage directory: $e (${e.runtimeType})');
          debugPrint('$st');
          if (e is MissingPluginException) {
            // path_provider not registered — fallback
            targetDir = Directory.systemTemp;
          } else {
            try {
              targetDir = await getApplicationDocumentsDirectory();
            } catch (e2, st2) {
              debugPrint('Fallback application docs failed: $e2 (${e2.runtimeType})');
              debugPrint('$st2');
              targetDir = Directory.systemTemp;
            }
          }
        }
      }

      // Request storage permission on Android if writing outside app dir
      try {
        if (!kIsWeb && Platform.isAndroid) {
          // Request standard storage permission
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            debugPrint('Storage permission denied - falling back to app Documents folder');
            // Do not fail; fall back to app-specific documents directory which does not require storage permission
            try {
              targetDir = await getApplicationDocumentsDirectory();
            } catch (e) {
              debugPrint('Failed to get application documents directory: $e');
              // final fallback
              targetDir = Directory.systemTemp;
            }
          }
        }
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }

      // Use app-specific folder 'noty' and consistent backup file naming
      final safeTimestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final folderName = 'noty';
      final fileName = 'noty_backup_$safeTimestamp.json';
      // If the user explicitly requested a prompt save (Export action), try asking
      // the platform to pick a location (this lets the user save to Downloads or
      // another public folder). If that fails or the user cancels, fall back to
      // the app-specific 'noty' folder.
      if (promptSave && !kIsWeb) {
        try {
          final picked = await FilePicker.platform.saveFile(
            dialogTitle: 'حفظ النسخة الاحتياطية',
            fileName: fileName,
            bytes: Uint8List.fromList(utf8.encode(json)),
          );
          if (picked != null && picked.isNotEmpty) {
            final outFile = File(picked);
            await outFile.create(recursive: true);
            await outFile.writeAsString(json);
            debugPrint('Backup saved to $picked (user chosen)');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('تم حفظ النسخة الاحتياطية في: $picked'),
                behavior: SnackBarBehavior.floating,
              ));
            }
            return true;
          } else {
            // The save dialog may not be supported on all devices/OS versions or the user cancelled.
            // Fallback: create a temporary file and open the system share sheet so the user
            // can save/send the backup (works reliably across platforms).
            try {
              final tmpDir = await getTemporaryDirectory();
              final tmpFile = File('${tmpDir.path}/$fileName');
              await tmpFile.create(recursive: true);
              await tmpFile.writeAsString(json);
              await Share.shareFiles([tmpFile.path], text: 'نسخة احتياطية لتطبيق Noty');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم فتح نافذة المشاركة لحفظ أو إرسال النسخة الاحتياطية'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
              return true;
            } catch (e) {
              debugPrint('share fallback failed: $e');
            }
          }
        } catch (e) {
          debugPrint('saveFile dialog failed: $e');
          // Continue to fallback below
        }
      }
      if (kIsWeb) {
        final ok = await webDownloadString(fileName, json);
        if (ok) {
          debugPrint('Backup downloaded in browser');
        }
        return ok;
      }

      // If user selected a persistent backup directory, try it first
      if (_backupDirPath != null && _backupDirPath!.isNotEmpty) {
        try {
          debugPrint('Attempting to write backup to user-selected dir: ${_backupDirPath}');
          final userDir = Directory(_backupDirPath!);
          debugPrint('userDir.exists(): ${await userDir.exists()}');
          if (!await userDir.exists()) {
            debugPrint('userDir does not exist, trying to create it');
            await userDir.create(recursive: true);
          }
          final userFile = File('${userDir.path}/$fileName');
          debugPrint('Creating file at ${userFile.path}');
          await userFile.create(recursive: true);
          await userFile.writeAsString(json);
          // prune older backups in this folder
          await _pruneOldBackups(userDir, 'noty_backup_');
          debugPrint('Backup saved to ${userFile.path} (user folder)');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في: ${userFile.path}'), behavior: SnackBarBehavior.floating));
          return true;
        } catch (e) {
          debugPrint('Failed to write to user backup dir $_backupDirPath: $e');
          debugPrint(StackTrace.current.toString());
          // If on Android, attempt SAF flow automatically (request tree access and write inside it)
          if (!kIsWeb && Platform.isAndroid) {
            try {
              final treeUri = await _requestTreeAccess();
              if (treeUri != null && treeUri.isNotEmpty) {
                final bytes = Uint8List.fromList(utf8.encode(json));
                final ok = await _storageChannel.invokeMethod<bool>('writeFileToTree', {
                  'treeUri': treeUri,
                  'fileName': fileName,
                  'bytes': bytes,
                });
                if (ok == true) {
                  try {
                    await _storageChannel.invokeMethod('pruneTreeBackups', {'treeUri': treeUri, 'prefix': 'noty_backup_', 'keep': 3});
                  } catch (_) {}
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في المجلد المختار عبر صلاحية النظام.'), behavior: SnackBarBehavior.floating));
                  return true;
                }
              }
            } catch (e2) {
              debugPrint('SAF fallback failed: $e2');
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ في المجلد المختار، سيتم الحفظ في مجلد التطبيق بدلاً منه. خطأ: ${e.toString()}'), behavior: SnackBarBehavior.floating));
          }
          // Continue to fallback behavior
        }
      }

      // Ensure the app-specific folder exists inside the chosen targetDir
      final appDir = Directory('${targetDir!.path}/$folderName');
      if (!await appDir.exists()) {
        try {
          await appDir.create(recursive: true);
        } catch (e) {
          // Fallback to targetDir if creation fails
          debugPrint('Failed to create app folder $folderName: $e');
        }
      }

      final file = File('${appDir.path}/$fileName');
      await file.create(recursive: true);
      await file.writeAsString(json);

      // prune older backups in appDir as well
      await _pruneOldBackups(appDir, 'noty_backup_');

      debugPrint('Backup saved to ${file.path}');
      if (mounted) {
        final visiblePath = file.path;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم حفظ النسخة الاحتياطية في: $visiblePath'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return true;
    } catch (e) {
      debugPrint('Failed to write backup: $e (${e.runtimeType})');
      debugPrint(StackTrace.current.toString());
      if (mounted) {
        final msg = e is MissingPluginException
            ? 'المكوّنات الأصلية غير مسجلة. أعد تشغيل التطبيق (full restart) ثم حاول مرة أخرى.'
            : 'فشل في حفظ النسخة الاحتياطية: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return false;
    }
  }

  // Remove older backup files in [dir] that match [prefix], keep only the newest 3
  Future<void> _pruneOldBackups(Directory dir, String prefix) async {
    try {
      if (!await dir.exists()) return;
      final files = await dir.list().where((e) => e is File && e.path.split('/').last.startsWith(prefix)).cast<File>().toList();
      if (files.length <= 3) return;
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final toDelete = files.skip(3);
      for (final f in toDelete) {
        try {
          await f.delete();
          debugPrint('Pruned old backup: ${f.path}');
        } catch (e) {
          debugPrint('Failed to delete old backup ${f.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Prune old backups failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.instance, LanguageManager.instance]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings),
            backgroundColor: AppTheme.getCardColor(context),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.getDividerColor(context),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              padding: EdgeInsets.all(Layout.horizontalPadding(context)),
              children: [
                // قسم المظهر
                _buildSectionCard(
                  title: l10n.appearanceAndDisplay,
                  icon: Icons.palette,
                  children: [
                    _buildSwitchTile(
                      title: l10n.darkMode,
                      subtitle: l10n.darkModeSubtitle,
                      icon: Icons.dark_mode,
                      value: ThemeManager.instance.isDarkMode,
                      onChanged: (value) async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ThemeManager.instance.toggleTheme();
                        if (!mounted) return;
                        final message = ThemeManager.instance.isDarkMode ? l10n.darkModeEnabled : l10n.lightModeEnabled;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: 'اختيار مجلد النسخ الاحتياطي',
                      subtitle: _backupDirPath ?? 'لم يتم التعيين',
                      icon: Icons.folder_open,
                      onTap: () async {
                        try {
                          String? pickedDir;
                          if (kIsWeb) {
                            // Not supported on web: fallback to null
                            pickedDir = null;
                          } else {
                            pickedDir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'اختر مجلداً لحفظ النسخ الاحتياطية');
                          }
                          if (pickedDir != null && pickedDir.isNotEmpty) {
                            // Test write permission by creating and deleting a small temp file
                            try {
                              final testFile = File('$pickedDir${Platform.pathSeparator}.noty_write_test');
                              await testFile.create(recursive: true);
                              await testFile.writeAsString('test');
                              await testFile.delete();
                            } catch (e) {
                              debugPrint('Selected directory not writable: $e');
                              // Try SAF flow on Android
                              if (!kIsWeb && Platform.isAndroid) {
                                final treeUri = await _requestTreeAccess();
                                if (treeUri != null && treeUri.isNotEmpty) {
                                  await DatabaseHelper.instance.setMetadata('backup_dir', treeUri);
                                  if (mounted) setState(() { _backupDirPath = treeUri; });
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم منح الإذن وحفظ مسار النسخ الاحتياطي.'), behavior: SnackBarBehavior.floating));
                                  return;
                                }
                              }
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('المجلد المختار غير قابل للكتابة. اختر مجلداً آخر أو اسمح بالأذونات.'), behavior: SnackBarBehavior.floating));
                              return;
                            }
                            await DatabaseHelper.instance.setMetadata('backup_dir', pickedDir);
                            if (mounted) setState(() { _backupDirPath = pickedDir; });
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعيين مجلد النسخ الاحتياطي: $pickedDir'), behavior: SnackBarBehavior.floating));
                          } else {
                            // user cancelled or not supported
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لم يتم اختيار مجلد.')));
                          }
                        } catch (e) {
                          debugPrint('Directory pick failed: $e');
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل اختيار المجلد: ${e.toString()}')));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.fontSize,
                      subtitle: l10n.fontSizeSubtitle,
                      icon: Icons.text_fields,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.fontSizeComingSoon),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: Layout.sectionSpacing(context)),

                // قسم اللغة
                _buildSectionCard(
                  title: l10n.languageAndRegion,
                  icon: Icons.language,
                  children: [
                    _buildListTile(
                      title: l10n.language,
                      subtitle: LanguageManager.instance.currentLanguageName,
                      icon: Icons.language,
                      onTap: () => _showLanguageDialog(),
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.timezone,
                      subtitle: l10n.timezoneSubtitle,
                      icon: Icons.schedule,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.timezoneComingSoon),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: Layout.sectionSpacing(context)),

                // قسم الإشعارات
                _buildSectionCard(
                  title: l10n.notifications,
                  icon: Icons.notifications,
                  children: [
                    _buildSwitchTile(
                      title: l10n.enableNotifications,
                      subtitle: l10n.enableNotificationsSubtitle,
                      icon: Icons.notifications_active,
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_notificationsEnabled ? l10n.notificationsEnabledOn : l10n.notificationsEnabledOff),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.notificationSounds,
                      subtitle: l10n.notificationSoundsSubtitle,
                      icon: Icons.volume_up,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.notificationSoundsComingSoon),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: Layout.sectionSpacing(context)),

                // قسم النسخ الاحتياطي
                _buildSectionCard(
                  title: l10n.backupAndSync,
                  icon: Icons.cloud_sync,
                  children: [
                    _buildListTile(
                      title: 'اختيار مجلد النسخ الاحتياطي',
                      subtitle: _backupDirPath ?? 'لم يتم التعيين',
                      icon: Icons.folder_open,
                      onTap: () async {
                        try {
                          String? pickedDir;
                          if (kIsWeb) {
                            pickedDir = null;
                          } else {
                            pickedDir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'اختر مجلداً لحفظ النسخ الاحتياطية');
                          }
                          if (pickedDir != null && pickedDir.isNotEmpty) {
                            await DatabaseHelper.instance.setMetadata('backup_dir', pickedDir);
                            if (mounted) setState(() { _backupDirPath = pickedDir; });
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعيين مجلد النسخ الاحتياطي: $pickedDir'), behavior: SnackBarBehavior.floating));
                          } else {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لم يتم اختيار مجلد.')));
                          }
                        } catch (e) {
                          debugPrint('Directory pick failed: $e');
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل اختيار المجلد: ${e.toString()}')));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: l10n.autoBackup,
            subtitle: _autoBackupEnabled
              ? (_lastAutoBackup != null ? l10n.autoBackupLast(_lastAutoBackup!.toLocal().toString()) : l10n.autoBackupPeriodicEnabled)
              : l10n.autoBackupSubtitle,
                      icon: Icons.backup,
                      value: _autoBackupEnabled,
                      onChanged: (val) async {
                        setState(() => _autoBackupEnabled = val);
                          if (val) {
                          // Start a simple periodic timer (runs while app is in memory)
                          _autoBackupTimer = Timer.periodic(const Duration(hours: 24), (_) async {
                            final repo = await NotesRepository.instance;
                            final json = await repo.exportBackupJson();
                            if (json == null) {
                              debugPrint('Auto-backup: export returned null');
                              return;
                            }
                            await _writeBackupToFile(json);
                            setState(() { _lastAutoBackup = DateTime.now(); });
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.autoBackupPeriodicEnabledSnackOn), behavior: SnackBarBehavior.floating));
                        } else {
                          _autoBackupTimer?.cancel();
                          _autoBackupTimer = null;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.autoBackupPeriodicEnabledSnackOff), behavior: SnackBarBehavior.floating));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.exportBackupTitle,
                      subtitle: l10n.exportBackupSubtitle,
                      icon: Icons.download,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final repo = await NotesRepository.instance;
                        final json = await repo.exportBackupJson();
                        if (json == null) {
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text(l10n.exportBackupFailed)));
                          return;
                        }
                        // Only prompt the save dialog when the user hasn't selected a backup folder.
                        final shouldPrompt = _backupDirPath == null;
                        final saved = await _writeBackupToFile(json, promptSave: shouldPrompt);
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(saved ? l10n.exportBackupSaved : l10n.exportBackupFailed)));
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.importBackupTitle,
                      subtitle: l10n.importBackupSubtitle,
                      icon: Icons.upload_file,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
                        if (result != null && result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final content = await file.readAsString();
                          final repo = await NotesRepository.instance;
                          final ok = await repo.importBackupJson(content);
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text(ok ? l10n.importBackupSuccess : l10n.importBackupFailed)));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.restoreFromKeyTitle,
                      subtitle: l10n.restoreFromKeySubtitle,
                      icon: Icons.restore_from_trash,
                      onTap: () async {
                        // Prompt user to paste backup JSON and restore via SQLite-backed importer
                        final repo = await NotesRepository.instance;
                        final TextEditingController controller = TextEditingController();
                        await showDialog<void>(
                          context: context,
                          builder: (BuildContext ctx) {
                            return AlertDialog(
                              backgroundColor: AppTheme.getCardColor(ctx),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Row(
                                children: [
                                  Icon(Icons.restore, color: Theme.of(ctx).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(l10n.restoreFromKeyTitle, style: Theme.of(ctx).textTheme.titleMedium),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l10n.restoreFromKeySubtitle, style: Theme.of(ctx).textTheme.bodyMedium),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: controller,
                                    maxLines: 8,
                                    decoration: InputDecoration(
                                      hintText: l10n.importBackupSubtitle,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(l10n.cancel),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(elevation: 0),
                                  onPressed: () async {
                                    final content = controller.text.trim();
                                    if (content.isEmpty) {
                                      // keep dialog open and show a temporary message
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreFromKeyNotFound)));
                                      return;
                                    }
                                    Navigator.of(ctx).pop();
                                    final ok = await repo.importBackupJson(content);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? l10n.restoreFromKeySuccess : l10n.importBackupFailed)));
                                  },
                                  child: Text(l10n.importBackupTitle),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: Layout.sectionSpacing(context)),

                // قسم حول التطبيق
                _buildSectionCard(
                  title: l10n.aboutApp,
                  icon: Icons.info,
                  children: [
                    _buildListTile(
                      title: l10n.version,
                      subtitle: '',
                      icon: Icons.verified,
                      onTap: () {
                        _showAboutDialog();
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: l10n.developer,
                      subtitle: '',
                      icon: Icons.person,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.thankYouMessage),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: Responsive.hp(context, 2)),

                // قسم معلومات التطبيق مع الشعار
                _buildSectionCard(
                  title: l10n.appInfoTitle,
                  icon: Icons.info_outline,
                  children: [
                    // الشعار مع معلومات التطبيق
                    Container(
                          padding: EdgeInsets.all(Layout.horizontalPadding(context)),
                          child: Column(
                            children: [
                              AppLogo(
                                size: Responsive.wp(context, 18),
                                showText: true,
                                text: l10n.appTitle,
                              ),
                              SizedBox(height: Layout.sectionSpacing(context)),
                              Text(
                                l10n.appDescription,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Color.fromRGBO(
                    ((Theme.of(context).textTheme.bodyMedium?.color?.r ?? 0) * 255).round(),
                    ((Theme.of(context).textTheme.bodyMedium?.color?.g ?? 0) * 255).round(),
                    ((Theme.of(context).textTheme.bodyMedium?.color?.b ?? 0) * 255).round(),
                    0.7),
                                  fontSize: Responsive.sp(context, 1.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.hp(context, 1.5)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Theme.of(context).primaryColor,
                                    size: Layout.iconSize(context),
                                    ),
                                    SizedBox(width: Layout.smallGap(context)),
                                    Text(
                                      l10n.version,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: Layout.bodyFont(context)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Load persisted backup directory (if set by user)
    () async {
      try {
        final path = await DatabaseHelper.instance.getMetadata('backup_dir');
        if (mounted) setState(() { _backupDirPath = path; });
      } catch (e) {
        debugPrint('Failed to load backup_dir metadata: $e');
      }
    }();
  }

  @override
  void dispose() {
    _autoBackupTimer?.cancel();
    super.dispose();
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.getCardShadow(context),
        border: Border.all(
          color: Color.fromRGBO((AppTheme.getBorderColor(context).r * 255).round(), (AppTheme.getBorderColor(context).g * 255).round(), (AppTheme.getBorderColor(context).b * 255).round(), 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Layout.horizontalPadding(context)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.wp(context, 1.2)),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: Responsive.sp(context, 1.8)),
                ),
                SizedBox(width: Layout.smallGap(context)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(context, 2.2),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.4),
      leading: Container(
        padding: EdgeInsets.all(Responsive.wp(context, 1)),
        decoration: BoxDecoration(
          color: Color.fromRGBO((AppTheme.getTextSecondary(context).r * 255).round(), (AppTheme.getTextSecondary(context).g * 255).round(), (AppTheme.getTextSecondary(context).b * 255).round(), 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
          child: Icon(
          icon, 
          color: AppTheme.getTextSecondary(context),
          size: Layout.iconSize(context),
        ),
      ),
      title: Text(
        title,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: Layout.titleFont(context)),
      ),
      subtitle: Text(
        subtitle,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: Layout.bodyFont(context)),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: Responsive.sp(context, 1.4),
        color: AppTheme.getTextSecondary(context),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context) * 0.4),
      leading: Container(
        padding: EdgeInsets.all(Responsive.wp(context, 1)),
        decoration: BoxDecoration(
          color: value
            ? Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.1)
            : Color.fromRGBO((AppTheme.getTextSecondary(context).r * 255).round(), (AppTheme.getTextSecondary(context).g * 255).round(), (AppTheme.getTextSecondary(context).b * 255).round(), 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
          child: Icon(
          icon, 
          color: value 
            ? Theme.of(context).colorScheme.primary
            : AppTheme.getTextSecondary(context),
          size: Layout.iconSize(context),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: Layout.titleFont(context)),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: Layout.bodyFont(context)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.selectLanguage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
                children: LanguageManager.instance.supportedLanguages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang['name']!, style: Theme.of(context).textTheme.bodyLarge),
                value: lang['code']!,
                groupValue: LanguageManager.instance.currentLocale.languageCode,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) async {
                  final nav = Navigator.of(context);
                  if (value != null) {
                    await LanguageManager.instance.changeLanguage(value);
                  }
                  if (!mounted) return;
                  nav.pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                l10n.cancel,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color.fromRGBO((Theme.of(context).colorScheme.primary.r * 255).round(), (Theme.of(context).colorScheme.primary.g * 255).round(), (Theme.of(context).colorScheme.primary.b * 255).round(), 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notes,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.version,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.developer,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                l10n.close,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
