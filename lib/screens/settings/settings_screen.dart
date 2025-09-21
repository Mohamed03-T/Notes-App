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
import 'package:permission_handler/permission_handler.dart';
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
            debugPrint('Storage permission denied');
            return false;
          }
        }
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }

      final fileName = 'notes_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      if (kIsWeb) {
        final ok = await webDownloadString(fileName, json);
        if (ok) {
          debugPrint('Backup downloaded in browser');
        }
        return ok;
      }

      final file = File('${targetDir!.path}/$fileName');
      await file.create(recursive: true);
      await file.writeAsString(json);

      debugPrint('Backup saved to ${file.path}');
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
                        final saved = await _writeBackupToFile(json, promptSave: true);
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
                        final messenger = ScaffoldMessenger.of(context);
                        final repo = await NotesRepository.instance;
                        final ok = await repo.restoreFromPrefsBackup();
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(content: Text(ok ? l10n.restoreFromKeySuccess : l10n.restoreFromKeyNotFound)));
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
    // Could load persisted auto-backup setting in future
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
