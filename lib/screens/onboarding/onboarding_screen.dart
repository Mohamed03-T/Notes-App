import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notes/notes_home.dart';
import '../../widgets/app_logo.dart';
import '../../core/layout/layout_helpers.dart';
import '../../utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'تحكم كامل',
      'description': 'قم بإنشاء وتنظيم ملاحظاتك بكل سهولة داخل صفحات ومجلدات.'
    },
    {
      'title': 'واجهة بسيطة',
      'description': 'استمتع بواجهة مستخدم نظيفة وسهلة الاستخدام.'
    },
    {
      'title': 'تخصيص المظهر',
      'description': 'اختر بين الوضع الفاتح والداكن حسب رغبتك.'
    },
    {
      'title': 'عمل دون إنترنت',
      'description': 'التطبيق يعمل دون اتصال بالإنترنت ويخزن ملاحظاتك محلياً لضمان خصوصية عالية.'
    },
    {
      'title': 'اللغات المتوفرة',
      'description': 'العربية، الفرنسية، والإنجليزية لتجربة أكثر سهولة ومرونة.'
    },
    {
      'title': 'النسخ والاستعادة',
      'description': 'تتوفر تحديثات مستقبلية لنسخ البيانات واستعادتها، وإذا حُذف التطبيق دون نسخ احتياطي ستُفقد الملاحظات.'
    },
    {
      'title': 'حماية المجلدات',
      'description': 'يمكنك تعيين رمز للمجلدات لحفظ أسرارك وحمايتها.'
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
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
                itemCount: _pages.length,
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
                          text: 'Notes App',
                        ),
                        SizedBox(height: Layout.sectionSpacing(context) * 1.2),
                        Text(
                          _pages[index]['title']!,
                          style: TextStyle(fontSize: Responsive.sp(context, 2.8), fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Layout.smallGap(context) * 1.2),
                        Text(
                          _pages[index]['description']!,
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
                    child: Text(_currentIndex > 0 ? 'عودة' : 'تخطي'),
                  ),
                  Row(
                    children: List.generate(
                      _pages.length,
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
                    onPressed: _currentIndex < _pages.length - 1
                        ? () {
                            _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease);
                          }
                        : _finishOnboarding,
                    child: Text(_currentIndex < _pages.length - 1 ? 'التالي' : 'إنهاء'),
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
