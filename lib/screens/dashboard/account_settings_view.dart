import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';

class AccountSettingsView extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? salonDetail;

  const AccountSettingsView({
    super.key,
    this.userProfile,
    this.salonDetail,
  });

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final _formKey = GlobalKey<FormState>();
  
  // State variables for dynamic data loading
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _salonData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileAndSalon();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndSalon() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch dynamic profile data from /api/v1/auth/profile
      final profileRes = await ApiService().getAuthProfile();
      if (profileRes['success'] != true) {
        setState(() {
          _error = profileRes['error'] ?? 'Failed to load user profile';
          _isLoading = false;
        });
        return;
      }

      final profile = profileRes['data'];
      _profileData = Map<String, dynamic>.from(profile);
      _nameController.text = _profileData?['name'] ?? '';
      _phoneController.text = _profileData?['phone'] ?? '';

      // 2. Fetch dynamic salon details if salonId is available
      final salonId = widget.salonDetail?['id'] ?? _profileData?['salonId'];
      if (salonId != null) {
        final salonRes = await ApiService().getSalonDetail(salonId);
        if (salonRes['success'] == true) {
          _salonData = Map<String, dynamic>.from(salonRes['data']);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _profileData?['id'] ?? widget.userProfile?['id'];
    if (userId == null) {
      _showSnackBar('Unable to determine User ID.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final res = await ApiService().updateUserProfile(
        userId.toString(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (res['success'] == true) {
          _showSnackBar(res['message'] ?? 'Profile updated successfully!', isError: false);
          
          // Update local profile state
          setState(() {
            _profileData?['name'] = _nameController.text.trim();
            _profileData?['phone'] = _phoneController.text.trim();
          });
        } else {
          _showSnackBar(res['error'] ?? 'Failed to update profile.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showSnackBar('An unexpected error occurred: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
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
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Account Settings',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to Load Settings',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadProfileAndSalon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Retry', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Profile Section
                          _buildSectionTitle('PERSONAL PROFILE'),
                          _buildProfileCard(),

                          const SizedBox(height: 24),

                          // 2. Salon Information Section
                          if (_salonData != null) ...[
                            _buildSectionTitle('SALON REGISTRATION DETAILS'),
                            _buildSalonCard(),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.accentPurple,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final email = _profileData?['email'] ?? widget.userProfile?['email'] ?? '';
    final role = _profileData?['role'] ?? widget.userProfile?['role'] ?? 'SALON_OWNER';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editable Name
            Text(
              'Full Name',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline_rounded,
              controller: _nameController,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),

            // Editable Phone
            Text(
              'Phone Number',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              hintText: 'Enter phone number',
              prefixIcon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              controller: _phoneController,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Read-Only Email
            Text(
              'Email Address',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyField(email, Icons.mail_outline_rounded),

            const SizedBox(height: 20),

            // Read-Only Role
            Text(
              'Portal Access Role',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyField(role.replaceAll('_', ' '), Icons.badge_outlined),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _isSaving
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                      ),
                    )
                  : GradientButton(
                      text: 'Save Changes',
                      borderRadius: 14,
                      onPressed: _updateProfile,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              val,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildSalonCard() {
    final name = _salonData?['name'] ?? 'Apna Salon';
    final description = _salonData?['description'] ?? '';
    final phone = _salonData?['phone'] ?? '';
    final address = _salonData?['address'] ?? '';
    final city = _salonData?['city'] ?? '';
    final state = _salonData?['state'] ?? '';
    final pincode = _salonData?['pincode'] ?? '';
    final website = _salonData?['website'] ?? '';
    final rating = _salonData?['rating'] ?? 0.0;
    final totalReviews = _salonData?['totalReviews'] ?? 0;
    final offersHomeService = _salonData?['offersHomeService'] ?? false;
    final genderServed = _salonData?['genderServed'] is List
        ? List<String>.from(_salonData?['genderServed'])
        : <String>[];

    return Container(
      padding: const EdgeInsets.all(20),
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
          // Header with Salon Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.accentPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toString()} ($totalReviews reviews)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Description
          if (description.isNotEmpty) ...[
            Text(
              'About Business',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],

          // Phone
          _buildSalonDetailRow(Icons.phone_outlined, 'Contact Hotline', phone),
          const SizedBox(height: 12),

          // Address
          _buildSalonDetailRow(
            Icons.location_on_outlined,
            'Physical Address',
            '$address, $city, $state - $pincode',
          ),
          const SizedBox(height: 12),

          // Website
          if (website.isNotEmpty) ...[
            _buildSalonDetailRow(Icons.language_rounded, 'Website Portal', website),
            const SizedBox(height: 12),
          ],

          // Badges Row
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Home service status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: offersHomeService
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  offersHomeService ? 'Offers Home Service' : 'In-Store Service Only',
                  style: GoogleFonts.inter(
                    color: offersHomeService ? const Color(0xFF10B981) : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Gender badges
              ...genderServed.map(
                (g) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    g,
                    style: GoogleFonts.inter(
                      color: AppColors.accentPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalonDetailRow(IconData icon, String label, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textLight, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
