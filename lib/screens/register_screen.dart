import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/razor_logo.dart';
import '../widgets/fade_slide_transition.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Selected Role: SALON_OWNER
  final String _selectedRole = 'SALON_OWNER';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService().register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (_selectedRole == 'SALON_OWNER') {
          // Redirect to Salon Onboarding screen with route arguments
          Navigator.pushReplacementNamed(
            context,
            '/salon-onboarding',
            arguments: {
              'ownerName': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
            },
          );
        } else {
          // Non-salon owners just show verification message and redirect to Login
          _showSuccessDialog();
        }
      } else {
        _showErrorSnackBar(result['error'] ?? 'Registration failed. Please try again.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Registration Successful!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account has been created. A verification link has been sent to ${_emailController.text.trim()}. Please verify your email before logging in.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'BACK TO LOGIN',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Grid background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
            
            // Soft Glowing Backdrop Blobs
            Positioned(
              top: -150,
              right: -150,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 120.0, sigmaY: 120.0),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 120.0, sigmaY: 120.0),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: mediaQuery.size.height * 0.4,
              right: -200,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 140.0, sigmaY: 140.0),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 460),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              
                              const SizedBox(height: 32),
                              
                              _buildMainCard(isTablet),
                              
                              const SizedBox(height: 32),
                              
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const FadeSlideTransition(
      delay: Duration(milliseconds: 100),
      child: Center(
        child: RazorLogo(
          iconSize: 32,
          fontSize: 26,
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isTablet) {
    final formWidget = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Headings
          FadeSlideTransition(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.accentPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PARTNER PORTAL',
                        style: GoogleFonts.inter(
                          color: AppColors.accentPurple,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Create Account',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentPurple,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join GlowDew Partner and experience smart salon booking',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Name Input
          FadeSlideTransition(
            delay: const Duration(milliseconds: 320),
            child: CustomTextField(
              controller: _nameController,
              hintText: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              borderRadius: 16,
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter name' : null,
            ),
          ),

          const SizedBox(height: 16),

          // Email Input
          FadeSlideTransition(
            delay: const Duration(milliseconds: 400),
            child: CustomTextField(
              controller: _emailController,
              hintText: 'Email Address',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              borderRadius: 16,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter email';
                final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegExp.hasMatch(val.trim())) return 'Please enter a valid email address';
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Phone Input
          FadeSlideTransition(
            delay: const Duration(milliseconds: 480),
            child: CustomTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              borderRadius: 16,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(val.trim())) return 'Enter a valid 10-15 digit phone number';
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Password Input
          FadeSlideTransition(
            delay: const Duration(milliseconds: 560),
            child: CustomTextField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              borderRadius: 16,
              textInputAction: TextInputAction.done,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter password';
                if (val.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
          ),

          const SizedBox(height: 28),

          // Register Button
          FadeSlideTransition(
            delay: const Duration(milliseconds: 640),
            child: _isLoading
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.2)),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                        ),
                      ),
                    ),
                  )
                : GradientButton(
                    text: _selectedRole == 'SALON_OWNER' 
                        ? 'PROCEED TO ONBOARDING' 
                        : 'CREATE ACCOUNT',
                    borderRadius: 16,
                    onPressed: _handleRegister,
                  ),
          ),
        ],
      ),
    );

    final cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.015),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 36.0 : 24.0),
            child: formWidget,
          ),
        ),
      ),
    );

    return FadeSlideTransition(
      delay: const Duration(milliseconds: 150),
      child: cardContent,
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeSlideTransition(
          delay: const Duration(milliseconds: 720),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Text(
                    'Login',
                    style: GoogleFonts.inter(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        FadeSlideTransition(
          delay: const Duration(milliseconds: 800),
          child: Text(
            '© 2026 GlowDew Partner. All rights reserved.',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }


}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;

    const double spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
