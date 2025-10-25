import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/layout/layout_helpers.dart';
import '../utils/responsive.dart';

/// Full-screen onboarding modal for automatic backup setup.
/// Returns one of: 'pick', 'grant', 'use_app', 'remind'
class BackupOnboardingScreen extends StatelessWidget {
  const BackupOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تهيئة النسخ الاحتياطي'),
        backgroundColor: AppTheme.getCardColor(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop('remind'),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(Layout.horizontalPadding(context)),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: Responsive.hp(context, 2)),
            Icon(Icons.backup, size: Responsive.wp(context, 22), color: Theme.of(context).colorScheme.primary),
            SizedBox(height: Responsive.hp(context, 3)),
            Text(
              'النسخ الاحتياطي التلقائي',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.hp(context, 2)),
            Text(
              'يمكن للتطبيق حفظ نسخة احتياطية من ملاحظاتك تلقائياً. اختر أين تريد حفظ النسخ — في مجلد على جهازك (مستحسَن)، أو منح صلاحية لحفظ المجلد عبر نظام Android (SAF)، أو استخدام مجلد التطبيق الداخلي.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.hp(context, 4)),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('اختر مجلداً'),
              onPressed: () => Navigator.of(context).pop('pick'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open),
              label: const Text('منح صلاحية المجلد (Android)'),
              onPressed: () => Navigator.of(context).pop('grant'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder),
              label: const Text('استخدم مجلد التطبيق (محلي)'),
              onPressed: () => Navigator.of(context).pop('use_app'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop('remind'),
              child: const Text('تذكّر لاحقاً'),
            ),
            SizedBox(height: Responsive.hp(context, 2)),
          ],
        ),
      ),
    );
  }
}
