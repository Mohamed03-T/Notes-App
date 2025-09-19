import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/language_manager.dart';
import '../../widgets/app_logo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import '../../repositories/notes_repository.dart';

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
      try {
        // Prefer Downloads on platforms that support it
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = null;
      }

      if (targetDir == null) {
        // On Android, use external storage directory and place into Downloads
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            // Try to find a Downloads folder
            final downloads = Directory('${extDir.parent.path}/Download');
            if (await downloads.exists()) {
              targetDir = downloads;
            } else {
              targetDir = extDir;
            }
          }
        } catch (_) {
          targetDir = await getApplicationDocumentsDirectory();
        }
      }

      // Request storage permission on Android if writing outside app dir
      try {
        if (Platform.isAndroid) {
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
      final file = File('${targetDir!.path}/$fileName');
      await file.create(recursive: true);
      await file.writeAsString(json);

      debugPrint('Backup saved to ${file.path}');
      return true;
    } catch (e) {
      debugPrint('Failed to write backup: $e');
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
              padding: const EdgeInsets.all(16),
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
                        await ThemeManager.instance.toggleTheme();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ThemeManager.instance.isDarkMode 
                                  ? l10n.darkModeEnabled
                                  : l10n.lightModeEnabled),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
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

                const SizedBox(height: 16),

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

                const SizedBox(height: 16),

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
                            content: Text(_notificationsEnabled ? 'تم تفعيل الإشعارات' : 'تم إيقاف الإشعارات'),
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
                      title: 'أصوات الإشعارات',
                      subtitle: 'الصوت الافتراضي',
                      icon: Icons.volume_up,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم إضافة خيارات الأصوات قريباً'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // قسم النسخ الاحتياطي
                _buildSectionCard(
                  title: l10n.backupAndSync,
                  icon: Icons.cloud_sync,
                  children: [
                    _buildSwitchTile(
                      title: l10n.autoBackup,
                      subtitle: _autoBackupEnabled ? 'النسخ الدوري مفعل' : l10n.autoBackupSubtitle,
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل النسخ الدوري (يعمل أثناء تشغيل التطبيق)'), behavior: SnackBarBehavior.floating));
                        } else {
                          _autoBackupTimer?.cancel();
                          _autoBackupTimer = null;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إيقاف النسخ الدوري'), behavior: SnackBarBehavior.floating));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: 'تصدير النسخة الاحتياطية',
                      subtitle: 'حفظ ملف JSON للنسخة الاحتياطية',
                      icon: Icons.download,
                      onTap: () async {
                        final repo = await NotesRepository.instance;
                        final json = await repo.exportBackupJson();
                        final saved = await _writeBackupToFile(json, promptSave: true);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'تم حفظ النسخة الاحتياطية' : 'فشل في حفظ النسخة')));
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: 'استيراد النسخة الاحتياطية',
                      subtitle: 'اختر ملف JSON لاستيراده',
                      icon: Icons.upload_file,
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
                        if (result != null && result.files.single.path != null) {
                          final file = File(result.files.single.path!);
                          final content = await file.readAsString();
                          final repo = await NotesRepository.instance;
                          final ok = await repo.importBackupJson(content);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم استيراد النسخة الاحتياطية' : 'فشل في استيراد الملف')));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: 'استعادة من المفتاح الداخلي',
                      subtitle: 'استعادة من backup_notes_v2',
                      icon: Icons.restore_from_trash,
                      onTap: () async {
                        final repo = await NotesRepository.instance;
                        final ok = await repo.restoreFromPrefsBackup();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تمت الاستعادة من المفتاح الداخلي' : 'لا توجد نسخة احتياطية داخلية')));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
                          const SnackBar(
                            content: Text('شكراً لاستخدام التطبيق! 💙'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // قسم معلومات التطبيق مع الشعار
                _buildSectionCard(
                  title: 'معلومات التطبيق',
                  icon: Icons.info_outline,
                  children: [
                    // الشعار مع معلومات التطبيق
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const AppLogo(
                            size: 80,
                            showText: true,
                            text: 'Notes App',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'تطبيق ملاحظات حديث وأنيق مع دعم المظهر الداكن والفاتح',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الإصدار 1.0.0',
                                style: Theme.of(context).textTheme.bodySmall,
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
          color: AppTheme.getBorderColor(context).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.getTextSecondary(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon, 
          color: AppTheme.getTextSecondary(context),
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
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
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: value 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : AppTheme.getTextSecondary(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon, 
          color: value 
            ? Theme.of(context).colorScheme.primary
            : AppTheme.getTextSecondary(context),
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
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
                  if (value != null) {
                    await LanguageManager.instance.changeLanguage(value);
                  }
                  Navigator.pop(context);
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                'تطبيق ملاحظات حديث وأنيق مع دعم المظهر الداكن والفاتح',
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
