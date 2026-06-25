import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';

class SupportHelpdeskView extends StatelessWidget {
  const SupportHelpdeskView({super.key});

  static const String _phone = '9135768042';
  static const String _email = 'helpglowdew@gmail.com';

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _phone);
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (canLaunch) {
      await launchUrl(uri);
    } else {
      _showSnackBar(context, 'Could not open dialer. Please call $_phone manually.', isError: true);
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {
        'subject': 'GlowDew Partner Support Request',
      },
    );
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (canLaunch) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(const ClipboardData(text: _email));
      if (context.mounted) {
        _showSnackBar(context, 'Email copied to clipboard!');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header Banner
            FadeSlideTransition(
              delay: const Duration(milliseconds: 60),
              child: _buildHeaderBanner(),
            ),

            const SizedBox(height: 28),

            // Section label
            FadeSlideTransition(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'CONTACT OPTIONS',
                style: GoogleFonts.inter(
                  color: AppColors.accentPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Phone Card
            FadeSlideTransition(
              delay: const Duration(milliseconds: 130),
              child: _buildContactCard(
                context: context,
                icon: Icons.call_rounded,
                iconBgColor: AppColors.accentPurple,
                label: 'Call Us',
                value: '+91 9135768042',
                description: 'Mon – Sat, 9:00 AM – 7:00 PM',
                actionLabel: 'Call Now',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _launchPhone(context);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Email Card
            FadeSlideTransition(
              delay: const Duration(milliseconds: 160),
              child: _buildContactCard(
                context: context,
                icon: Icons.email_rounded,
                iconBgColor: AppColors.accentPurple,
                label: 'Email Us',
                value: _email,
                description: 'We respond within 24 business hours',
                actionLabel: 'Send Email',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _launchEmail(context);
                },
              ),
            ),

            const SizedBox(height: 28),

            // Support Hours
            FadeSlideTransition(
              delay: const Duration(milliseconds: 200),
              child: _buildSupportHoursCard(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAF9F6),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: AppColors.textPrimary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Help Desk',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'We\'re here to help you',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.accentPurple,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle background design circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentBlue.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 50,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentBlue.withValues(alpha: 0.02),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'PARTNER SUPPORT',
                            style: GoogleFonts.inter(
                              color: AppColors.accentBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Need Help?',
                          style: GoogleFonts.outfit(
                            color: AppColors.accentBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Our partner support team is\nready to assist you.',
                          style: GoogleFonts.inter(
                            color: AppColors.accentBlue.withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required String value,
    required String description,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconBgColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Action button
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHoursCard() {
    final hours = [
      {'day': 'Monday – Friday', 'time': '9:00 AM – 7:00 PM', 'active': true},
      {'day': 'Saturday', 'time': '10:00 AM – 5:00 PM', 'active': true},
      {'day': 'Sunday & Holidays', 'time': 'Email Only', 'active': false},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.accentPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Support Hours',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...hours.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: h['active'] == true
                            ? const Color(0xFF10B981)
                            : AppColors.borderLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h['day'] as String,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      h['time'] as String,
                      style: GoogleFonts.inter(
                        color: h['active'] == true
                            ? AppColors.textPrimary
                            : AppColors.textLight,
                        fontSize: 12.5,
                        fontWeight: h['active'] == true
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
          Divider(height: 20, color: AppColors.borderLight.withValues(alpha: 0.6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.textLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'For urgent issues outside business hours, email $_email and mention "URGENT" in the subject.',
                  style: GoogleFonts.inter(
                    color: AppColors.textLight,
                    fontSize: 11.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
