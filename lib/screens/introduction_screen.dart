import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/razor_logo.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/onboarding_page_data.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _logoAnimationController;
  late Animation<double> _logoAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  void _onNextOrGetStarted() {
    if (_currentPage == onboardingPages.length - 1) {
      // Navigate to Login screen
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.backgroundStart,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Section (Logo & Titles)
                  _buildTopSection(),
                  
                  // Middle Section (Page View)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: onboardingPages.length,
                      itemBuilder: (context, index) {
                        return _buildPageContent(onboardingPages[index]);
                      },
                    ),
                  ),
                  
                  // Bottom Section (Indicators & Buttons)
                  _buildBottomSection(),
                ],
              ),
              Positioned(
                top: 16,
                right: 16,
                child: TextButton(
                  onPressed: () {
                    // Navigate to Login screen directly
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _logoAnimation.value),
                child: child,
              );
            },
            child: const RazorLogo(
              iconSize: 32,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Smart Salon Management',
            style: GoogleFonts.inter(
              color: AppColors.accentPurple,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your salon business smarter and faster',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingPageData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      data.imagePath,
                      height: constraints.maxHeight * 0.45,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: constraints.maxHeight * 0.45,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.textSecondary,
                            size: 80,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
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
      },
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: onboardingPages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.accentPurple,
              dotColor: AppColors.textSecondary.withValues(alpha: 0.2),
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
            ),
          ),
          const SizedBox(height: 32),
          GradientButton(
            text: _currentPage == onboardingPages.length - 1
                ? 'Get Started'
                : 'Next',
            onPressed: _onNextOrGetStarted,
          ),
        ],
      ),
    );
  }
}
