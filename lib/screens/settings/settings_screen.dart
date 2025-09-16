import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/language_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

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
                    _buildListTile(
                      title: l10n.autoBackup,
                      subtitle: l10n.autoBackupSubtitle,
                      icon: Icons.backup,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم إضافة خيارات النسخ الاحتياطي قريباً'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      title: 'استعادة البيانات',
                      subtitle: 'استرداد من نسخة احتياطية',
                      icon: Icons.restore,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم إضافة خيارات الاستعادة قريباً'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
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
                    'الإصدار: 1.0.0',
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
                    'تطوير: Mohamed03-T',
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
                'إغلاق',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
