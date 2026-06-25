import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../services/api_service.dart';
import 'reviews_view.dart';
import 'account_settings_view.dart';
import 'support_helpdesk_view.dart';
import 'terms_privacy_view.dart';

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? salonDetail;
  final VoidCallback? onSalonDetailsTap;

  const ProfileTab({
    super.key,
    this.userProfile,
    this.salonDetail,
    this.onSalonDetailsTap,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  File? _profileImage;
  File? _coverImage;
  


  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        _showSuccessSnackBar('Profile photo updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting profile image: $e');
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
        _showSuccessSnackBar('Cover banner updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting cover image: $e');
    }
  }



  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'RT';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Salon Profile',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                // 1. Profile / Salon Summary Card (With Cover & Profile Picture view/edit)
                _buildProfileCard(),

                const SizedBox(height: 24),

                // 3. Settings Options List
                _buildMenuSection('MANAGEMENT', [
                  _buildMenuItem(context, Icons.storefront_rounded, 'Salon Details', 'Hours, services, gallery', widget.onSalonDetailsTap),
                ]),

                const SizedBox(height: 16),

                _buildMenuSection('PREFERENCES & SYSTEM', [
                  _buildMenuItem(
                    context,
                    Icons.settings_outlined,
                    'Account Settings',
                    'Profile details & password',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountSettingsView(
                            userProfile: widget.userProfile,
                            salonDetail: widget.salonDetail,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.star_rate_rounded,
                    'Customer Reviews',
                    'View client ratings & feedback',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsView(salonDetail: widget.salonDetail),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.help_outline_rounded,
                    'Support & Help Desk',
                    'FAQs, chat with GlowDew support',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportHelpdeskView(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.policy_outlined,
                    'Terms & Privacy Policies',
                    'Legal conditions & terms',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsPrivacyView(),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 28),

                // 4. Logout Button
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 300),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        _showLogoutConfirmation(context);
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      label: Text(
                        'Log Out of Business Portal',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = widget.salonDetail?['name'] ?? widget.userProfile?['name'] ?? 'Royal Touch Salon';
    final initials = _getInitials(name);
    final isVerified = widget.salonDetail?['isVerified'] ?? widget.userProfile?['isVerified'] ?? false;
    final partnerId = widget.salonDetail != null ? 'SKS-SL-${widget.salonDetail!['id']}' : 'SKS-RT-4029';
    final email = widget.userProfile?['email'] ?? widget.salonDetail?['email'] ?? 'admin@royaltouch.com';
    final rating = widget.salonDetail?['rating'] ?? 0.0;
    final totalReviews = widget.salonDetail?['totalReviews'] ?? 0;

    return FadeSlideTransition(
      delay: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Banner with overlapping Profile Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Banner
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: _coverImage != null
                        ? Image.file(
                            _coverImage!,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&q=80',
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                // Edit Cover Icon Button (Floating Glassmorphism style)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Tooltip(
                    message: 'Edit Cover Photo',
                    child: ClipOval(
                      child: Container(
                        width: 36,
                        height: 36,
                        color: Colors.black.withValues(alpha: 0.4),
                        child: InkWell(
                          onTap: _pickCoverImage,
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Overlapping Profile Avatar Circle
                Positioned(
                  bottom: -36,
                  left: 20,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _profileImage != null
                              ? Image.file(
                                  _profileImage!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?auto=format&fit=crop&w=300&q=80',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.accentPurple,
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      // Camera edit overlay badge for profile avatar
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Tooltip(
                          message: 'Edit Profile Photo',
                          child: ClipOval(
                            child: Container(
                              width: 28,
                              height: 28,
                              color: AppColors.accentPurple,
                              child: InkWell(
                                onTap: _pickProfileImage,
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Text Details Padded down to clear the profile avatar overlay
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Pending',
                          style: GoogleFonts.inter(
                            color: isVerified ? const Color(0xFF10B981) : Colors.orange,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Partner ID: $partnerId',
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.toString()} ($totalReviews reviews)',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMenuSection(String sectionTitle, List<Widget> items) {
    return FadeSlideTransition(
      delay: const Duration(milliseconds: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              sectionTitle,
              style: GoogleFonts.inter(
                color: AppColors.accentPurple,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, 
    IconData icon, 
    String title, 
    String subtitle, 
    VoidCallback? onTap
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accentPurple, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textLight,
        size: 20,
      ),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuring $title is only available in production mode.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out of the GlowDew Partner Dashboard?',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                await ApiService().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

