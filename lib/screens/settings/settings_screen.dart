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
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database_helper.dart';
import '../../repositories/notes_repository.dart';
import '../../services/backup/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../backup_onboarding_screen.dart';
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
  bool _allowPrompt = false;
  static const MethodChannel _storageChannel = MethodChannel('noty/storage');
  String _appVersion = '';

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (e) {
      debugPrint('Failed to load package info: $e');
    }
  }

  // Refresh backup-related info shown in the UI (last backup time, chosen folder, auto-backup enabled)
  Future<void> _refreshBackupInfo() async {
    try {
      final last = await BackupService.instance.getLastBackupTime();
      final folder = await BackupService.instance.getBackupFolder();
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('auto_backup_enabled') ?? false;
      if (mounted) setState(() {
        _lastAutoBackup = last;
        _backupDirPath = folder;
        _autoBackupEnabled = enabled;
      });
    } catch (e) {
      debugPrint('Failed to refresh backup info: $e');
    }
  }

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
        targetDir = null;
      } else {
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {
          targetDir = null;
        }
      }

      if (targetDir == null) {
        try {
          final downloadsDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (downloadsDirs != null && downloadsDirs.isNotEmpty) {
            targetDir = downloadsDirs.first;
          } else {
            final extDir = await getExternalStorageDirectory();
            if (extDir != null) {
              final candidate = Directory('${extDir.path}${Platform.pathSeparator}Download');
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
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            debugPrint('Storage permission denied - falling back to app Documents folder');
            try {
              targetDir = await getApplicationDocumentsDirectory();
            } catch (e) {
              debugPrint('Failed to get application documents directory: $e');
              targetDir = Directory.systemTemp;
            }
          }
        }
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }

      final safeTimestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final folderName = 'noty';
      final fileName = 'noty_backup_$safeTimestamp.json';

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
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في: $picked'), behavior: SnackBarBehavior.floating));
            return true;
          } else {
            try {
              final tmpDir = await getTemporaryDirectory();
              final tmpFile = File('${tmpDir.path}${Platform.pathSeparator}$fileName');
              await tmpFile.create(recursive: true);
              await tmpFile.writeAsString(json);
              await Share.shareFiles([tmpFile.path], text: 'نسخة احتياطية لتطبيق Noty');
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم فتح نافذة المشاركة لحفظ أو إرسال النسخة الاحتياطية'), behavior: SnackBarBehavior.floating));
              return true;
            } catch (e) {
              debugPrint('share fallback failed: $e');
            }
          }
        } catch (e) {
          debugPrint('saveFile dialog failed: $e');
        }
      }

      if (kIsWeb) {
        final ok = await webDownloadString(fileName, json);
        if (ok) debugPrint('Backup downloaded in browser');
        return ok;
      }

      if (_backupDirPath != null && _backupDirPath!.isNotEmpty) {
        try {
          final userDir = Directory(_backupDirPath!);
          if (!await userDir.exists()) await userDir.create(recursive: true);
          final userFile = File('${userDir.path}${Platform.pathSeparator}$fileName');
          await userFile.create(recursive: true);
          await userFile.writeAsString(json);
          await _pruneOldBackups(userDir, 'noty_backup_');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في: ${userFile.path}'), behavior: SnackBarBehavior.floating));
          return true;
        } catch (e) {
          debugPrint('Failed to write to user backup dir $_backupDirPath: $e');
          // SAF fallback only on explicit promptSave
          if (!kIsWeb && Platform.isAndroid && promptSave) {
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
                  try { await _storageChannel.invokeMethod('pruneTreeBackups', {'treeUri': treeUri, 'prefix': 'noty_backup_', 'keep': 3}); } catch (_) {}
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في المجلد المختار عبر صلاحية النظام.'), behavior: SnackBarBehavior.floating));
                  return true;
                }
              }
            } catch (e2) {
              debugPrint('SAF fallback failed: $e2');
            }
          } else {
            debugPrint('Skipping automatic SAF prompt (promptSave=$promptSave, allowPrompt=$_allowPrompt)');
          }
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ في المجلد المختار، سيتم الحفظ في مجلد التطبيق بدلاً منه. خطأ: ${e.toString()}'), behavior: SnackBarBehavior.floating));
        }
      }

      final appDir = Directory('${targetDir!.path}${Platform.pathSeparator}$folderName');
      if (!await appDir.exists()) {
        try { await appDir.create(recursive: true); } catch (e) { debugPrint('Failed to create app folder $folderName: $e'); }
      }
      final file = File('${appDir.path}${Platform.pathSeparator}$fileName');
      await file.create(recursive: true);
      await file.writeAsString(json);
      await _pruneOldBackups(appDir, 'noty_backup_');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في: ${file.path}'), behavior: SnackBarBehavior.floating));
      return true;
    } catch (e) {
      debugPrint('Failed to write backup: $e (${e.runtimeType})');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في حفظ النسخة الاحتياطية: ${e.toString()}')));
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

  // Check whether we should prompt the user to choose a backup folder (only once per 24 hours)
  Future<bool> _shouldPromptForBackupFolder() async {
    // don't prompt during initial build/restore phase
    if (!_allowPrompt) return false;
    try {
      final raw = await DatabaseHelper.instance.getMetadata('last_backup_folder_prompt');
      if (raw == null || raw.isEmpty) return true;
      final last = DateTime.tryParse(raw);
      if (last == null) return true;
      return DateTime.now().difference(last) >= const Duration(hours: 24);
    } catch (e) {
      debugPrint('Error reading last prompt metadata: $e');
      return true;
    }
  }

  // Show an explanatory dialog before opening the folder picker. Returns true if the user chose to proceed now.
  Future<bool> _showFolderExplainAndAsk() async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: AppTheme.getCardColor(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(Icons.folder_open, color: Theme.of(ctx).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('تعيين مجلد النسخ الاحتياطي'),
                ],
              ),
              content: Text('لضمان حفظ نسخك الاحتياطية خارج التطبيق وللحصول على نسخة يمكنك الوصول إليها بسهولة، يُفضّل اختيار مجلد على جهازك أو منح صلاحية مجلد. هل تريد اختيار المجلد الآن؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('تذكّر لاحقاً'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('اختر الآن'),
                ),
              ],
            );
          },
        ) ?? false;
  }

  // Interactive folder picker/save flow used when auto-backup decides to prompt the user.
  // Returns true if a backup was written.
  Future<bool> _interactivePickFolderAndSave(String json) async {
    try {
      String? pickedDir;
      if (kIsWeb) {
        pickedDir = null;
      } else {
        pickedDir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'اختر مجلداً لحفظ النسخ الاحتياطية');
      }
      if (pickedDir != null && pickedDir.isNotEmpty) {
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
              // write via SAF
              try {
                final bytes = Uint8List.fromList(utf8.encode(json));
                final ok = await _storageChannel.invokeMethod<bool>('writeFileToTree', {
                  'treeUri': treeUri,
                  'fileName': 'noty_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json',
                  'bytes': bytes,
                });
                if (ok == true) {
                  try {
                    await _storageChannel.invokeMethod('pruneTreeBackups', {'treeUri': treeUri, 'prefix': 'noty_backup_', 'keep': 3});
                  } catch (_) {}
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة الاحتياطية في المجلد المختار عبر صلاحية النظام.'), behavior: SnackBarBehavior.floating));
                  return true;
                }
              } catch (e) {
                debugPrint('SAF write after pick failed: $e');
              }
            }
          }
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('المجلد المختار غير قابل للكتابة. اختر مجلداً آخر أو اسمح بالأذونات.'), behavior: SnackBarBehavior.floating));
          return false;
        }
        await DatabaseHelper.instance.setMetadata('backup_dir', pickedDir);
        if (mounted) setState(() { _backupDirPath = pickedDir; });
        // Now write using existing non-interactive writer which will target the user dir
        final ok = await _writeBackupToFile(json, promptSave: false);
        return ok;
      } else {
        // user cancelled
        return false;
      }
    } catch (e) {
      debugPrint('Interactive pick and save failed: $e');
      return false;
    } finally {
      // record that we prompted now so we don't prompt again before 24h if user cancelled or chose
      try { await DatabaseHelper.instance.setMetadata('last_backup_folder_prompt', DateTime.now().toIso8601String()); } catch (_) {}
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
                            final shouldPrompt = await _shouldPromptForBackupFolder();
                            if (shouldPrompt) {
                              final accepted = await _showFolderExplainAndAsk();
                              try { await DatabaseHelper.instance.setMetadata('last_backup_folder_prompt', DateTime.now().toIso8601String()); } catch (_) {}
                              if (!accepted) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إلغاء اختيار المجلد.'), behavior: SnackBarBehavior.floating));
                                return;
                              }
                            }
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
                            final shouldPrompt = await _shouldPromptForBackupFolder();
                            if (shouldPrompt) {
                              final accepted = await _showFolderExplainAndAsk();
                              try { await DatabaseHelper.instance.setMetadata('last_backup_folder_prompt', DateTime.now().toIso8601String()); } catch (_) {}
                              if (!accepted) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إلغاء اختيار المجلد.'), behavior: SnackBarBehavior.floating));
                                return;
                              }
                            }
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
                    _buildListTile(
                      title: 'منح صلاحية المجلد',
                      subtitle: _backupDirPath != null && _backupDirPath!.isNotEmpty ? 'المسار الحالي: ${_backupDirPath!}' : 'لم تُمنح بعد',
                      icon: Icons.lock_open,
                      onTap: () async {
                        try {
                          final shouldPrompt = await _shouldPromptForBackupFolder();
                          if (shouldPrompt) {
                            final accepted = await _showFolderExplainAndAsk();
                            try { await DatabaseHelper.instance.setMetadata('last_backup_folder_prompt', DateTime.now().toIso8601String()); } catch (_) {}
                            if (!accepted) return;
                          }
                          final treeUri = await _requestTreeAccess();
                          if (treeUri != null && treeUri.isNotEmpty) {
                            await DatabaseHelper.instance.setMetadata('backup_dir', treeUri);
                            if (mounted) setState(() { _backupDirPath = treeUri; });
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم منح صلاحية المجلد وحفظ المسار.'), behavior: SnackBarBehavior.floating));
                          } else {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لم يتم منح الإذن أو تم الإلغاء.')));
                          }
                        } catch (e) {
                          debugPrint('Grant folder permission failed: $e');
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل منح صلاحية المجلد: ${e.toString()}')));
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
                        // If enabling, show the onboarding modal once (or when not shown before)
                        if (val) {
                          final shownRaw = await DatabaseHelper.instance.getMetadata('auto_backup_onboarding_shown');
                          final alreadyShown = shownRaw != null && shownRaw == 'true';
                          String? action;
                          if (!alreadyShown && mounted) {
                            action = await Navigator.of(context).push<String?>(MaterialPageRoute(builder: (_) => const BackupOnboardingScreen(), fullscreenDialog: true));
                            // record that we've shown onboarding
                            try { await DatabaseHelper.instance.setMetadata('auto_backup_onboarding_shown', 'true'); } catch (_) {}
                          }

                          // Handle action from onboarding (pick/grant/use_app/remind)
                          // If user chose 'remind', do not enable auto-backup
                          if (action == 'remind') {
                            if (mounted) {
                              setState(() => _autoBackupEnabled = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.autoBackupPeriodicEnabledSnackOff), behavior: SnackBarBehavior.floating));
                            }
                            try { await DatabaseHelper.instance.setMetadata('auto_backup_enabled', 'false'); } catch (_) {}
                            return;
                          }

                          // Proceed to enable and perform first backup according to chosen action
                          setState(() => _autoBackupEnabled = true);
                          // Persist and schedule via BackupService
                          await BackupService.instance.setAutoBackupEnabled(true);
                          try { await DatabaseHelper.instance.setMetadata('auto_backup_enabled', 'true'); } catch (_) {}

                          final repo = await NotesRepository.instance;
                          final json = await repo.exportBackupJson();
                          if (json != null) {
                            if (action == 'pick') {
                              final ok = await _interactivePickFolderAndSave(json);
                              if (ok && mounted) setState(() { _lastAutoBackup = DateTime.now(); });
                            } else if (action == 'grant') {
                              final treeUri = await _requestTreeAccess();
                              if (treeUri != null && treeUri.isNotEmpty) {
                                await DatabaseHelper.instance.setMetadata('backup_dir', treeUri);
                                if (mounted) setState(() { _backupDirPath = treeUri; });
                                final ok = await _writeBackupToFile(json, promptSave: false);
                                if (ok && mounted) setState(() { _lastAutoBackup = DateTime.now(); });
                              }
                            } else {
                              // default: use app folder
                              final ok = await _writeBackupToFile(json, promptSave: false);
                              if (ok && mounted) setState(() { _lastAutoBackup = DateTime.now(); });
                            }
                          }

                          // start local in-memory timer for foreground behavior
                          _startAutoBackupTimer();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.autoBackupPeriodicEnabledSnackOn), behavior: SnackBarBehavior.floating));
                        } else {
                          // disabling
                          setState(() => _autoBackupEnabled = false);
                          // cancel both in-memory timer and scheduled background job
                          _autoBackupTimer?.cancel();
                          _autoBackupTimer = null;
                          await BackupService.instance.setAutoBackupEnabled(false);
                          try { await DatabaseHelper.instance.setMetadata('auto_backup_enabled', 'false'); } catch (_) {}
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.autoBackupPeriodicEnabledSnackOff), behavior: SnackBarBehavior.floating));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: 'نسخ احتياطي يدوي',
                      subtitle: _lastAutoBackup != null ? 'آخر نسخ: ${_lastAutoBackup!.toLocal()}' : 'لم يتم إنشاء نسخ بعد',
                      icon: Icons.backup,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await BackupService.instance.createManualBackup();
                        if (ok) {
                          if (mounted) setState(() { _lastAutoBackup = DateTime.now(); });
                          messenger.showSnackBar(SnackBar(content: Text('تم إنشاء نسخة احتياطية يدوياً.'), behavior: SnackBarBehavior.floating));
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text('فشل إنشاء النسخة الاحتياطية اليدوية.'), behavior: SnackBarBehavior.floating));
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
                      subtitle: _appVersion.isNotEmpty ? 'الإصدار: $_appVersion' : '',
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
                                      _appVersion.isNotEmpty ? _appVersion : l10n.version,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: Layout.bodyFont(context)),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      icon: Icon(Icons.copy, size: Layout.iconSize(context) * 0.8, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                      onPressed: () {
                                        if (_appVersion.isNotEmpty) {
                                          Clipboard.setData(ClipboardData(text: _appVersion));
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ رقم الإصدار إلى الحافظة'), behavior: SnackBarBehavior.floating));
                                        }
                                      },
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
    _loadAppVersion();
    // Load persisted backup directory first, then restore auto-backup setting and resume timer if previously enabled
    () async {
      try {
        final path = await DatabaseHelper.instance.getMetadata('backup_dir');
        if (mounted) setState(() { _backupDirPath = path; });
      } catch (e) {
        debugPrint('Failed to load backup_dir metadata: $e');
      }

      try {
        final enabled = await DatabaseHelper.instance.getMetadata('auto_backup_enabled');
        if (enabled != null && enabled.toLowerCase() == 'true') {
          // Reflect persisted preference but do NOT start timers or run backups just because
          // the Settings screen was opened. Starting/stopping the periodic job is the
          // responsibility of the user via the toggle (onChanged) or the higher-level app
          // lifecycle code.
          if (mounted) setState(() { _autoBackupEnabled = true; });
        }
      } catch (e) {
        debugPrint('Failed to load auto_backup_enabled metadata: $e');
      }
      // Refresh displayed backup info from BackupService/SharedPreferences
      await _refreshBackupInfo();
    }();
    // Allow prompting after initial UI has rendered to avoid dialogs during navigation/build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allowPrompt = true;
    });
  }

  void _startAutoBackupTimer() {
    // Cancel existing timer if any
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(const Duration(hours: 24), (_) async {
      try {
        final repo = await NotesRepository.instance;
        final json = await repo.exportBackupJson();
        if (json == null) {
          debugPrint('Auto-backup: export returned null');
          return;
        }
        final ok = await _writeBackupToFile(json, promptSave: false);
        if (ok && mounted) setState(() { _lastAutoBackup = DateTime.now(); });
      } catch (e) {
        debugPrint('Auto-backup timer job failed: $e');
      }
    });
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
                    _appVersion.isNotEmpty ? '${l10n.version}: $_appVersion' : l10n.version,
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
              const SizedBox(height: 12),
              Text(
                'ملاحظة قصيرة (بالعربية): غيّر رقم الإصدار عندما تقوم بإصدار تحديث يتضمن ميزات جديدة ملحوظة أو تغيّرات لا تتوافق مع الإصدارات السابقة. لتعديل الإصدار، افتح الملف pubspec.yaml في جذر المشروع وعدّل الحقل version ثم أعد بناء التطبيق (flutter build).',
                style: Theme.of(context).textTheme.bodySmall,
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
