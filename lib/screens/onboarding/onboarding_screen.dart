import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class _OnboardingPage {
  final String icon;
  final String title;
  final String subtitle;
  final Color bg;

  const _OnboardingPage(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.bg});
}

const _pages = [
  _OnboardingPage(
    icon: '🏘️',
    title: 'Find Your\nDream Property',
    subtitle:
        'Browse thousands of verified properties for rent, sale, and lease across Uganda.',
    bg: Color(0xFFEFF6FF),
  ),
  _OnboardingPage(
    icon: '✅',
    title: 'Verified &\nFraud-Free Listings',
    subtitle:
        'Every listing goes through verification. No fake properties, no broker scams.',
    bg: Color(0xFFF0FDF4),
  ),
  _OnboardingPage(
    icon: '🔓',
    title: 'Unlock Full\nProperty Details',
    subtitle:
        'Browse for free. Pay a small fee to unlock exact location, owner contacts & documents.',
    bg: Color(0xFFFFF7ED),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  if (_current < _pages.length - 1)
                    TextButton(
                      onPressed: () => _goToHome(),
                      child: Text('Skip',
                          style: GoogleFonts.urbanist(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.accent,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_current < _pages.length - 1)
                    GradientButton(label: 'Next', onTap: _next)
                  else ...[
                    GradientButton(
                        label: 'Get Started', onTap: _goToHome),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: GoogleFonts.urbanist(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        GestureDetector(
                          onTap: _goToLogin,
                          child: Text('Sign In',
                              style: GoogleFonts.urbanist(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.bg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(page.icon, style: const TextStyle(fontSize: 80)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    context.read<AuthCubit>().completeOnboarding();
    context.go('/home');
  }

  void _goToLogin() {
    context.read<AuthCubit>().completeOnboarding();
    context.go('/home');
  }
}
