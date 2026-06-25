import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/gradient_button.dart';
import '../../services/api_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // --- STATE VARIABLES ---

  // 1. Business Settings
  bool _autoAcceptBookings = true;
  bool _requireAdvanceDeposit = false;
  bool _allowBookingCancellation = true;
  int _cancellationDeadlineHours = 24;
  String _businessStatus = 'Open'; // 'Open' or 'Closed'
  bool _isSavingBusiness = false;

  // 2. Notification Preferences
  // Email
  bool _emailNewBookings = true;
  bool _emailNewReviews = false;
  bool _emailPromotionalMessages = false;
  // Push
  bool _pushNewBookings = true;
  bool _pushNewReviews = true;
  bool _pushPaymentUpdates = true;
  bool _isSavingNotifications = false;

  // Global Save All State
  bool _isSavingAll = false;

  @override
  void dispose() {
    super.dispose();
  }

  // --- ACTIONS & TOASTS ---

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent.shade400 : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isSavingAll = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _isSavingAll = false);
    _showToast('All salon settings saved successfully!');
  }

  Future<void> _saveSection(String sectionName, Function(bool) setLoading) async {
    setState(() => setLoading(true));
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => setLoading(false));
    _showToast('$sectionName saved successfully!');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to log out of GlowDew Partner?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ApiService().logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  // --- SHARED UI DESIGN TEMPLATES ---

  Widget _buildCard({
    required String title,
    required IconData icon,
    required String subtitle,
    required List<Widget> children,
    Widget? footer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.accentPurple, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: footer,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeTrackColor = AppColors.accentPurple,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: activeTrackColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCounter({
    required String label,
    required int value,
    required int min,
    required int max,
    required String helperText,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  helperText,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    value.toString(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl({
    required String label,
    required String selected,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: options.map((opt) {
                    final isSel = selected == opt;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            opt,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSel ? AppColors.accentPurple : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildMiniSaveButton({
    required bool isLoading,
    required VoidCallback onPressed,
    String text = 'Save Settings',
  }) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save_rounded, size: 16, color: AppColors.accentPurple),
      label: Text(
        text,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.accentPurple, fontSize: 13),
      ),
    );
  }

  // --- CARDS RENDER METHODS ---

  Widget _buildBusinessSettingsCard() {
    return _buildCard(
      title: 'Business Settings',
      icon: Icons.business_center_rounded,
      subtitle: 'Manage operational business rules',
      children: [
        _buildToggleTile(
          title: 'Auto Accept Bookings',
          description: 'Automatically accept new booking requests.',
          value: _autoAcceptBookings,
          onChanged: (val) => setState(() => _autoAcceptBookings = val),
        ),
        const Divider(height: 16),
        _buildToggleTile(
          title: 'Require Advance Deposit',
          description: 'Customers must pay a deposit before booking confirmation.',
          value: _requireAdvanceDeposit,
          onChanged: (val) => setState(() => _requireAdvanceDeposit = val),
        ),
        const Divider(height: 16),
        _buildToggleTile(
          title: 'Allow Booking Cancellation',
          description: 'Allow customers to cancel their bookings.',
          value: _allowBookingCancellation,
          onChanged: (val) => setState(() => _allowBookingCancellation = val),
        ),
        if (_allowBookingCancellation) ...[
          const Divider(height: 16),
          _buildNumberCounter(
            label: 'Cancellation Deadline (Hours)',
            helperText: 'Minimum hours before appointment that customers can cancel.',
            value: _cancellationDeadlineHours,
            min: 1,
            max: 168,
            onChanged: (val) => setState(() => _cancellationDeadlineHours = val),
          ),
        ],
        const Divider(height: 16),
        _buildSegmentedControl(
          label: 'Business Status',
          selected: _businessStatus,
          options: const ['Open', 'Closed'],
          onChanged: (val) => setState(() => _businessStatus = val),
        ),
      ],
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMiniSaveButton(
            isLoading: _isSavingBusiness,
            onPressed: () => _saveSection('Business Settings', (v) => _isSavingBusiness = v),
            text: 'Save Business Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard() {
    return _buildCard(
      title: 'Notification Preferences',
      icon: Icons.notifications_active_rounded,
      subtitle: 'Choose how you want to receive important updates',
      children: [
        _buildSectionHeader('EMAIL NOTIFICATIONS'),
        _buildToggleTile(
          title: 'New Bookings',
          description: 'Alert for every new incoming request.',
          value: _emailNewBookings,
          onChanged: (val) => setState(() => _emailNewBookings = val),
        ),
        _buildToggleTile(
          title: 'New Reviews',
          description: 'Weekly digest of incoming customer feedback.',
          value: _emailNewReviews,
          onChanged: (val) => setState(() => _emailNewReviews = val),
        ),
        _buildToggleTile(
          title: 'Promotional Messages',
          description: 'Newsletter, insights, and discount updates.',
          value: _emailPromotionalMessages,
          onChanged: (val) => setState(() => _emailPromotionalMessages = val),
        ),
        const Divider(height: 24),
        _buildSectionHeader('PUSH NOTIFICATIONS'),
        _buildToggleTile(
          title: 'New Bookings',
          description: 'Popups for newly added appointments.',
          value: _pushNewBookings,
          onChanged: (val) => setState(() => _pushNewBookings = val),
        ),
        _buildToggleTile(
          title: 'New Reviews',
          description: 'Real-time alert when reviews are posted.',
          value: _pushNewReviews,
          onChanged: (val) => setState(() => _pushNewReviews = val),
        ),
        _buildToggleTile(
          title: 'Payment Updates',
          description: 'Instant notification on deposit clearings.',
          value: _pushPaymentUpdates,
          onChanged: (val) => setState(() => _pushPaymentUpdates = val),
        ),
      ],
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMiniSaveButton(
            isLoading: _isSavingNotifications,
            onPressed: () => _saveSection('Notification Preferences', (v) => _isSavingNotifications = v),
            text: 'Save Notifications',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return _buildCard(
      title: 'Account Actions',
      icon: Icons.gpp_maybe_rounded,
      subtitle: 'Session and security controls',
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: Text('Reset Password', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    label: Text('Logout from App', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- CORE LAYOUT GENERATION ---

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    final isDesktop = width > 1150;
    final isTablet = width <= 1150 && width > 750;

    // --- STAGGERED TRANSITION LAYOUT ---
    
    Widget buildResponsiveLayout() {
      if (isDesktop) {
        // 3-Column Grid for Desktop
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1
            Expanded(
              child: Column(
                children: [
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 50),
                    child: _buildBusinessSettingsCard(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Column 2
            Expanded(
              child: Column(
                children: [
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 150),
                    child: _buildNotificationPreferencesCard(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Column 3
            Expanded(
              child: Column(
                children: [
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 250),
                    child: _buildAccountActionsCard(),
                  ),
                ],
              ),
            ),
          ],
        );
      } else if (isTablet) {
        // 2-Column Grid for Tablet
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1
            Expanded(
              child: Column(
                children: [
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 50),
                    child: _buildBusinessSettingsCard(),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 250),
                    child: _buildAccountActionsCard(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Column 2
            Expanded(
              child: Column(
                children: [
                  FadeSlideTransition(
                    delay: const Duration(milliseconds: 150),
                    child: _buildNotificationPreferencesCard(),
                  ),
                ],
              ),
            ),
          ],
        );
      } else {
        // 1-Column List for Mobile
        return Column(
          children: [
            FadeSlideTransition(
              delay: const Duration(milliseconds: 50),
              child: _buildBusinessSettingsCard(),
            ),
            const SizedBox(height: 20),
            FadeSlideTransition(
              delay: const Duration(milliseconds: 150),
              child: _buildNotificationPreferencesCard(),
            ),
            const SizedBox(height: 20),
            FadeSlideTransition(
              delay: const Duration(milliseconds: 250),
              child: _buildAccountActionsCard(),
            ),
          ],
        );
      }
    }

    // --- MAIN RENDER TREE ---

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              FadeSlideTransition(
                delay: Duration.zero,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage your salon preferences, notifications, business rules, and account settings.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Top Right Save All Button
                      _isSavingAll
                          ? Container(
                              height: 48,
                              width: 140,
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
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
                          : SizedBox(
                              height: 48,
                              width: 150,
                              child: GradientButton(
                                text: 'Save All',
                                borderRadius: 14,
                                onPressed: _saveAllSettings,
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              // Responsive Cards Container
              buildResponsiveLayout(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
