import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../notes/notes_home.dart';
import '../../widgets/app_logo.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';
import 'package:note_app/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  List<Map<String, String>> _localizedPages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Provide simple fallbacks in case localization isn't ready yet
    return [
      {
        'title': l10n?.onboardingPage1Title ?? 'Create and organize',
        'description': l10n?.onboardingPage1Description ?? 'Create notes quickly and keep them organized.'
      },
      {
        'title': l10n?.onboardingPage2Title ?? 'Sync across devices',
        'description': l10n?.onboardingPage2Description ?? 'Access your notes from anywhere.'
      },
      {
        'title': l10n?.onboardingPage3Title ?? 'Attach files',
        'description': l10n?.onboardingPage3Description ?? 'Attach images and documents to your notes.'
      },
      {
        'title': l10n?.onboardingPage4Title ?? 'Search easily',
        'description': l10n?.onboardingPage4Description ?? 'Find notes with quick search.'
      },
      {
        'title': l10n?.onboardingPage5Title ?? 'Share',
        'description': l10n?.onboardingPage5Description ?? 'Share notes with your friends.'
      },
      {
        'title': l10n?.onboardingPage6Title ?? 'Customize',
        'description': l10n?.onboardingPage6Description ?? 'Use themes and colors to personalize.'
      },
      {
        'title': l10n?.onboardingPage7Title ?? 'Get started',
        'description': l10n?.onboardingPage7Description ?? 'Start creating beautiful notes.'
      },
    ];
  }

  Future<void> _finishOnboarding() async {
    await DatabaseHelper.instance.setMetadata('seenOnboarding', 'true');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NotesHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _localizedPages(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) {
                  final page = pages[index];
                  return Padding(
                    padding: EdgeInsets.all(Layout.horizontalPadding(context)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // إضافة الشعار
                        AppLogo(
                          size: Responsive.wp(context, 34),
                          showText: true,
                          text: l10n?.appTitle ?? 'Notes',
                        ),
                        SizedBox(height: Layout.sectionSpacing(context) * 1.2),
                        Text(
                          page['title']!,
                          style: TextStyle(fontSize: Responsive.sp(context, 2.8), fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Layout.smallGap(context) * 1.2),
                        Text(
                          page['description']!,
                          style: TextStyle(fontSize: Layout.bodyFont(context)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Layout.horizontalPadding(context), vertical: Layout.sectionSpacing(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _currentIndex > 0
                        ? () {
                            _controller.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          }
                        : _finishOnboarding,
                    child: Text(_currentIndex > 0 ? (l10n?.onboardingBack ?? 'Back') : (l10n?.onboardingSkip ?? 'Skip')),
                  ),
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 0.6)),
                        width: _currentIndex == index ? Responsive.wp(context, 3.2) : Responsive.wp(context, 2.4),
                        height: _currentIndex == index ? Responsive.wp(context, 3.2) : Responsive.wp(context, 2.4),
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _currentIndex < pages.length - 1
                        ? () {
                            _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          }
                        : _finishOnboarding,
                    child: Text(_currentIndex < pages.length - 1 ? (l10n?.onboardingNext ?? 'Next') : (l10n?.onboardingFinish ?? 'Finish')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
