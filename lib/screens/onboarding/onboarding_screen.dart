import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notes/notes_home.dart';

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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _pages[index]['title']!,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['description']!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 12 : 8,
                        height: _currentIndex == index ? 12 : 8,
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
