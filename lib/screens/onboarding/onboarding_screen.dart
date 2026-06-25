import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPageData(
      icon: Icons.favorite,
      title: 'Welcome to LoveSync',
      subtitle: 'The ultimate app for couples to connect, share, and grow together.',
      color: Color(0xFFE91E63),
    ),
    _OnboardingPageData(
      icon: Icons.chat_bubble_outline,
      title: 'Private Chat',
      subtitle: 'Chat privately with your partner. Share messages, voice notes, and images.',
      color: Color(0xFF9C27B0),
    ),
    _OnboardingPageData(
      icon: Icons.photo_album_outlined,
      title: 'Memories Together',
      subtitle: 'Create beautiful albums and cherish your favorite moments together.',
      color: Color(0xFF3F51B5),
    ),
    _OnboardingPageData(
      icon: Icons.emoji_events_outlined,
      title: 'Goals & Games',
      subtitle: 'Set couple goals, play fun games, and grow your relationship.',
      color: Color(0xFFFF4081),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await StorageService.setOnboardingCompleted();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? ThemeConstants.primaryColor
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.2),
              border: Border.all(
                color: page.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(page.icon, size: 64, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
