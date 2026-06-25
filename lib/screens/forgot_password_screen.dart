import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/razor_logo.dart';
import '../widgets/fade_slide_transition.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;
  bool _isResending = false;
  
  // Resend Timer
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _showSnackBar({required String message, required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSuccess ? AppColors.accentPurple : Colors.redAccent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isSuccess ? AppColors.accentPurple : Colors.redAccent).withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: Duration(seconds: isSuccess ? 3 : 4),
      ),
    );
  }

  void _handleSendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar(message: 'Please enter your email address.', isSuccess: false);
      return;
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text.trim())) {
      _showSnackBar(message: 'Please enter a valid email address.', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService().forgotPassword(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
        });
        _startTimer();
        _showSnackBar(
          message: 'An OTP has been sent to ${_emailController.text.trim()}.',
          isSuccess: true,
        );
      } else {
        _showSnackBar(
          message: result['error'] ?? 'Failed to send OTP. Please try again.',
          isSuccess: false,
        );
      }
    }
  }

  void _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    final result = await ApiService().resendPasswordResetOtp(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      if (result['success'] == true) {
        _startTimer();
        _showSnackBar(
          message: 'A new OTP has been sent successfully.',
          isSuccess: true,
        );
      } else {
        _showSnackBar(
          message: result['error'] ?? 'Failed to resend OTP. Please try again.',
          isSuccess: false,
        );
      }
    }
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService().resetPasswordWithOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          _showSnackBar(
            message: 'Password reset successful! Please log in with your new password.',
            isSuccess: true,
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          _showSnackBar(
            message: result['error'] ?? 'Failed to reset password. Please try again.',
            isSuccess: false,
          );
        }
      }
    }
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
          // Back Link
          FadeSlideTransition(
            delay: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  if (_otpSent) {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                      _timer?.cancel();
                      _secondsRemaining = 0;
                    });
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: AppColors.accentPurple,
                ),
                label: Text(
                  _otpSent ? 'Change Email' : 'Back to Login',
                  style: GoogleFonts.inter(
                    color: AppColors.accentPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Headings
          FadeSlideTransition(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otpSent ? 'Reset Password' : 'Forgot Password?',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentPurple,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _otpSent
                      ? 'Please enter the OTP sent to your email along with your new password details.'
                      : "Enter your email address and we'll send you an OTP to reset your password.",
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

          // Conditional UI Forms based on state
          if (!_otpSent) ...[
            // Email Input State
            FadeSlideTransition(
              delay: const Duration(milliseconds: 300),
              child: CustomTextField(
                hintText: 'Enter your email address',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                borderRadius: 16,
                textInputAction: TextInputAction.done,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegExp.hasMatch(val)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 28),
            // Send OTP Button
            FadeSlideTransition(
              delay: const Duration(milliseconds: 400),
              child: _isLoading
                  ? _buildLoader()
                  : GradientButton(
                      text: 'Send OTP',
                      borderRadius: 16,
                      onPressed: _handleSendOtp,
                    ),
            ),
          ] else ...[
            // Email (Read-Only Preview with edit icon)
            FadeSlideTransition(
              delay: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderLight.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderLight.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _emailController.text.trim(),
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.accentPurple, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          _timer?.cancel();
                          _secondsRemaining = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OTP Input Field
            FadeSlideTransition(
              delay: const Duration(milliseconds: 300),
              child: CustomTextField(
                hintText: 'Enter 6-Digit OTP',
                prefixIcon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                controller: _otpController,
                borderRadius: 16,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the OTP';
                  }
                  if (val.trim().length != 6) {
                    return 'OTP must be exactly 6 digits';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // New Password Input Field
            FadeSlideTransition(
              delay: const Duration(milliseconds: 350),
              child: CustomTextField(
                hintText: 'New Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                controller: _newPasswordController,
                borderRadius: 16,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your new password';
                  }
                  if (val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Input Field
            FadeSlideTransition(
              delay: const Duration(milliseconds: 400),
              child: CustomTextField(
                hintText: 'Confirm New Password',
                prefixIcon: Icons.lock_reset_rounded,
                isPassword: true,
                controller: _confirmPasswordController,
                borderRadius: 16,
                textInputAction: TextInputAction.done,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Resend Timer Row
            FadeSlideTransition(
              delay: const Duration(milliseconds: 450),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _secondsRemaining > 0
                        ? 'Resend OTP in ${_secondsRemaining}s'
                        : 'Did not receive OTP?',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                          ),
                        )
                      : TextButton(
                          onPressed: _secondsRemaining > 0 ? null : _handleResendOtp,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Resend OTP',
                            style: GoogleFonts.inter(
                              color: _secondsRemaining > 0
                                  ? AppColors.textLight
                                  : AppColors.accentPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Reset Password Button
            FadeSlideTransition(
              delay: const Duration(milliseconds: 500),
              child: _isLoading
                  ? _buildLoader()
                  : GradientButton(
                      text: 'Reset Password',
                      borderRadius: 16,
                      onPressed: _handleResetPassword,
                    ),
            ),
          ],
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

  Widget _buildLoader() {
    return Container(
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
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeSlideTransition(
          delay: const Duration(milliseconds: 500),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Remember your password? ",
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
                    'Sign in',
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
          delay: const Duration(milliseconds: 600),
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
