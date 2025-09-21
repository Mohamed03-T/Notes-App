import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return [
      {'title': l10n.onboardingPage1Title, 'description': l10n.onboardingPage1Description},
      {'title': l10n.onboardingPage2Title, 'description': l10n.onboardingPage2Description},
      {'title': l10n.onboardingPage3Title, 'description': l10n.onboardingPage3Description},
      {'title': l10n.onboardingPage4Title, 'description': l10n.onboardingPage4Description},
      {'title': l10n.onboardingPage5Title, 'description': l10n.onboardingPage5Description},
      {'title': l10n.onboardingPage6Title, 'description': l10n.onboardingPage6Description},
      {'title': l10n.onboardingPage7Title, 'description': l10n.onboardingPage7Description},
    ];
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NotesHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _localizedPages(context).length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) {
                  return Padding(
                    padding: EdgeInsets.all(Layout.horizontalPadding(context)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // إضافة الشعار
                        AppLogo(
                          size: Responsive.wp(context, 34),
                          showText: true,
                          text: AppLocalizations.of(context)!.appTitle,
                        ),
                        SizedBox(height: Layout.sectionSpacing(context) * 1.2),
                        Text(
                          _localizedPages(context)[index]['title']!,
                          style: TextStyle(fontSize: Responsive.sp(context, 2.8), fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Layout.smallGap(context) * 1.2),
                        Text(
                          _localizedPages(context)[index]['description']!,
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
                    child: Text(_currentIndex > 0 ? AppLocalizations.of(context)!.onboardingBack : AppLocalizations.of(context)!.onboardingSkip),
                  ),
                  Row(
                    children: List.generate(
                      _localizedPages(context).length,
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
                    onPressed: _currentIndex < _localizedPages(context).length - 1
                        ? () {
                            _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          }
                        : _finishOnboarding,
                    child: Text(_currentIndex < _localizedPages(context).length - 1 ? AppLocalizations.of(context)!.onboardingNext : AppLocalizations.of(context)!.onboardingFinish),
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
