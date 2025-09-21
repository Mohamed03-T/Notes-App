import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// 'package:flutter/services.dart' not needed; removed
import '../core/utils/app_assets.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;
  final String? text;

  const AppLogo({
    super.key,
    this.size = 80,
    this.color,
    this.showText = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: _buildLogoWidget(context),
        ),

        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            text ?? 'Notes App',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoWidget(BuildContext context) {
    // محاولة تحميل صورتك أولاً
    return Image.asset(
      AppAssets.logoPng,
      width: size,
      height: size,
      fit: BoxFit.contain, // تحسين ليحافظ على النسب
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) {
          if (kDebugMode) debugPrint('✅ تم تحميل الشعار بنجاح من ${AppAssets.logoPng}');
        }
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
  if (kDebugMode) debugPrint('🖼️ فشل في تحميل الشعار من ${AppAssets.logoPng}: $error');
  if (kDebugMode) debugPrint('📋 استخدام الشعار الافتراضي البسيط كبديل');
        
        // شعار افتراضي بسيط ونظيف
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8), // زوايا مدورة بسيطة
          ),
          child: Icon(
            Icons.note_add_outlined,
            size: size * 0.6,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

// Widget مصغر للشعار في الهيدر
class AppLogoSmall extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const AppLogoSmall({
    super.key,
    this.size = 40, // زيادة الحجم من 32 إلى 40
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = AppLogo(
      size: size,
      color: Theme.of(context).primaryColor,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: logo,
      );
    }

    return logo;
  }
}
