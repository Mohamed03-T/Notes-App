import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../widgets/app_logo.dart';
import '../core/layout/layout_helpers.dart';
import '../utils/responsive.dart';
import 'package:note_app/l10n/app_localizations.dart';
import 'notes/notes_home.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // بدء الأنيميشن
    _animationController.forward();

    // الانتقال إلى الشاشة التالية بعد 3 ثوانٍ
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;

  // التحقق من حالة onboarding (مخزنة في DB metadata)
  final seenStr = await DatabaseHelper.instance.getMetadata('seenOnboarding');
  final seenOnboarding = seenStr == 'true';

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              seenOnboarding ? const NotesHome() : const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(primary.red, primary.green, primary.blue, 0.1),
              Theme.of(context).scaffoldBackgroundColor,
              Color.fromRGBO(primary.red, primary.green, primary.blue, 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // المساحة العلوية
              const Spacer(flex: 2),
              
              // الشعار مع الأنيميشن (استخدم ScaleTransition بدلاً من قراءة .value مباشرة)
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AppLogo(
                    size: Responsive.wp(context, 34),
                    showText: true,
                    text: l10n?.appTitle ?? 'Notes',
                  ),
                ),
              ),
              SizedBox(height: Layout.sectionSpacing(context)),
              
              // نص ترحيبي مع أنيميشن
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                      child: Text(
                      l10n?.splashWelcomeTitle ?? 'Welcome',
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 3.0),
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // وصف قصير
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                      child: Text(
                      l10n?.splashTagline ?? 'Organize your notes quickly and easily.',
                      style: TextStyle(
                        fontSize: Layout.bodyFont(context),
                        color: Color.fromRGBO(bodyColor.red, bodyColor.green, bodyColor.blue, 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              
              // المساحة السفلية
              const Spacer(flex: 2),
              
              // مؤشر التحميل
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: Responsive.hp(context, 6)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: Responsive.wp(context, 6),
                            height: Responsive.wp(context, 6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(primary.red, primary.green, primary.blue, 0.6),
                              ),
                            ),
                          ),
                          SizedBox(height: Layout.smallGap(context) * 0.6),
                          Text(l10n?.splashLoading ?? 'Loading', style: TextStyle(fontSize: Layout.bodyFont(context))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
