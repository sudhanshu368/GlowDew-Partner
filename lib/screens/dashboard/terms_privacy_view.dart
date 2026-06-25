import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';

class TermsPrivacyView extends StatefulWidget {
  const TermsPrivacyView({super.key});

  @override
  State<TermsPrivacyView> createState() => _TermsPrivacyViewState();
}

class _TermsPrivacyViewState extends State<TermsPrivacyView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        setState(() {
          _scrollProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Reading progress bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 3,
            alignment: Alignment.centerLeft,
            color: AppColors.borderLight.withValues(alpha: 0.5),
            child: FractionallySizedBox(
              widthFactor: _scrollProgress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                  ),
                ),
              ),
            ),
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTermsTab(),
                _buildPrivacyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAF9F6),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Privacy Policies',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Last updated: June 2025',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Clipboard.setData(const ClipboardData(text: 'https://glowdewpartner.app/legal'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Policy link copied to clipboard',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: '  Terms of Use  '),
          Tab(text: '  Privacy Policy  '),
        ],
      ),
    );
  }

  // ─────────────────────── TERMS OF USE TAB ────────────────────────
  Widget _buildTermsTab() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        FadeSlideTransition(
          delay: const Duration(milliseconds: 50),
          child: _buildLegalHeaderCard(
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Terms of Use',
            subtitle:
                'By accessing the GlowDew Partner application, you agree to be bound by these Terms. Please read them carefully.',
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 80),
          child: _buildSection(
            number: '01',
            title: 'Acceptance of Terms',
            content:
                'By registering as a partner on the GlowDew Partner platform ("Platform"), you agree to comply with and be legally bound by these Terms of Use. If you do not agree with any part of these terms, you must not use the Platform. GlowDew reserves the right to update these terms at any time with reasonable notice.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 100),
          child: _buildSection(
            number: '02',
            title: 'Partner Eligibility',
            content:
                'To register as a salon partner, you must:\n• Be at least 18 years of age\n• Own or be an authorized representative of a registered salon or beauty establishment\n• Provide accurate, current, and complete registration information\n• Possess all necessary business licenses and permits required by local law',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 120),
          child: _buildSection(
            number: '03',
            title: 'Partner Obligations',
            content:
                'As a GlowDew Partner, you agree to:\n• Maintain accurate and up-to-date service listings, pricing, and availability\n• Honor all bookings confirmed through the Platform\n• Provide professional, high-quality services to customers\n• Comply with all applicable hygiene and safety standards\n• Not engage in fraudulent, misleading, or deceptive practices',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 140),
          child: _buildSection(
            number: '04',
            title: 'Booking & Cancellation Policy',
            content:
                'Partners must honor all bookings confirmed through the Platform. Cancellations made by the partner within 2 hours of the scheduled appointment may attract a penalty deduction from the next payout cycle. Repeated cancellations may result in account suspension. Customers may cancel bookings as per the refund policy communicated at the time of booking.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 160),
          child: _buildSection(
            number: '05',
            title: 'Commission & Payouts',
            content:
                'GlowDew charges a platform commission on each completed booking as communicated during partner onboarding. Payout of net earnings (after commission deduction) is processed every Monday and Thursday. GlowDew reserves the right to withhold payouts in cases of disputed transactions, policy violations, or active fraud investigations.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 180),
          child: _buildSection(
            number: '06',
            title: 'Intellectual Property',
            content:
                'All content, branding, software, and technology on the Platform are owned by GlowDew or its licensors and are protected under applicable intellectual property laws. Partners may not reproduce, distribute, or create derivative works from any Platform content without explicit written consent from GlowDew.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 200),
          child: _buildSection(
            number: '07',
            title: 'Termination',
            content:
                'GlowDew reserves the right to suspend or terminate partner accounts at its sole discretion for violations of these Terms, fraudulent activity, sustained poor customer ratings, or any other conduct deemed harmful to the Platform or its users. Partners may also terminate their account at any time by contacting support.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 220),
          child: _buildSection(
            number: '08',
            title: 'Limitation of Liability',
            content:
                'To the maximum extent permitted by law, GlowDew shall not be liable for any indirect, incidental, special, or consequential damages arising from partner\'s use of the Platform. GlowDew\'s total liability shall not exceed the commission earned from the partner in the preceding 30 days.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 240),
          child: _buildContactSupportCard(),
        ),
      ],
    );
  }

  // ─────────────────────── PRIVACY POLICY TAB ──────────────────────
  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        FadeSlideTransition(
          delay: const Duration(milliseconds: 50),
          child: _buildLegalHeaderCard(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Privacy Policy',
            subtitle:
                'Your privacy is important to us. This policy explains how GlowDew collects, uses, and protects your personal and business data.',
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 80),
          child: _buildDataCollectionCard(),
        ),
        const SizedBox(height: 4),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 100),
          child: _buildSection(
            number: '01',
            title: 'Information We Collect',
            content:
                'We collect information you provide directly to us, including:\n• Business registration details (name, address, GST number)\n• Owner/representative identity (Aadhaar, PAN)\n• Bank account details for payout processing\n• Service listings, pricing, and business hours\n• Profile and salon photos you upload\n• Communication records with our support team',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 120),
          child: _buildSection(
            number: '02',
            title: 'How We Use Your Data',
            content:
                'We use your data to:\n• Verify partner identity and salon legitimacy\n• Process bookings and payouts accurately\n• Display your salon profile to customers\n• Send transaction notifications and service updates\n• Improve Platform features based on usage analytics\n• Comply with legal obligations and regulatory requirements',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 140),
          child: _buildSection(
            number: '03',
            title: 'Data Sharing & Third Parties',
            content:
                'We do not sell your personal data to third parties. We may share data with:\n• Payment processors to facilitate payouts\n• Cloud infrastructure providers (data is encrypted at rest)\n• Legal authorities when required by applicable law\n• Analytics providers in anonymized, aggregated form only\n\nAll third-party providers are bound by confidentiality obligations.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 160),
          child: _buildSection(
            number: '04',
            title: 'Data Security',
            content:
                'GlowDew implements industry-standard security measures including:\n• AES-256 encryption for sensitive data at rest\n• TLS 1.3 encryption for data in transit\n• Regular security audits and penetration testing\n• Role-based access controls for internal team members\n• Automatic session expiry and two-factor authentication support',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 180),
          child: _buildSection(
            number: '05',
            title: 'Data Retention',
            content:
                'We retain your data for as long as your partner account is active plus 7 years thereafter to comply with financial and legal obligations. Booking records and transaction logs are retained for a minimum of 5 years. You may request deletion of non-essential data by contacting our support team.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 200),
          child: _buildSection(
            number: '06',
            title: 'Your Rights',
            content:
                'You have the right to:\n• Access a copy of the personal data we hold about you\n• Request correction of inaccurate or incomplete data\n• Request deletion of your data (subject to legal retention obligations)\n• Object to processing of your data for marketing purposes\n• Data portability — receive your data in a structured format\n\nTo exercise any of these rights, contact helpglowdew@gmail.com.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 220),
          child: _buildSection(
            number: '07',
            title: 'Cookies & Analytics',
            content:
                'Our mobile app does not use browser cookies. We use anonymized analytics tools to understand feature usage and improve the Platform experience. You can opt out of analytics data collection in Account Settings → Privacy Preferences.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 240),
          child: _buildSection(
            number: '08',
            title: 'Changes to This Policy',
            content:
                'We may update this Privacy Policy from time to time. Significant changes will be communicated via in-app notification and email at least 15 days before the changes take effect. Continued use of the Platform after the effective date constitutes acceptance of the updated policy.',
          ),
        ),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 260),
          child: _buildContactSupportCard(),
        ),
      ],
    );
  }

  Widget _buildLegalHeaderCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2937), Color(0xFF374151)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: iconColor.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollectionCard() {
    final items = [
      {'icon': Icons.business_rounded, 'label': 'Business Info', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.lock_rounded, 'label': 'Securely Stored', 'color': const Color(0xFF10B981)},
      {'icon': Icons.block_rounded, 'label': 'Never Sold', 'color': Colors.redAccent},
      {'icon': Icons.verified_rounded, 'label': 'Compliant', 'color': AppColors.accentPurple},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final color = item['color'] as Color;
          return Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                item['label'] as String,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number,
                    style: GoogleFonts.outfit(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupportCard() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
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
                  Icons.contact_support_rounded,
                  color: AppColors.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Questions? Reach Our Legal Team',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildContactRow(
            icon: Icons.email_outlined,
            label: 'helpglowdew@gmail.com',
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'helpglowdew@gmail.com'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Email copied to clipboard',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildContactRow(
            icon: Icons.call_outlined,
            label: '+91 9135768042',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening dialer…',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city_rounded, size: 14, color: AppColors.textLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GlowDew Technologies Pvt. Ltd.\nIndia • Governing Law: Indian IT Act, 2000',
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentPurple, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.copy_rounded,
              color: AppColors.textLight,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}
