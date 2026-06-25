import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/razor_logo.dart';
import '../services/api_service.dart';

class SalonOnboardingScreen extends StatefulWidget {
  const SalonOnboardingScreen({super.key});

  @override
  State<SalonOnboardingScreen> createState() => _SalonOnboardingScreenState();
}

class _SalonOnboardingScreenState extends State<SalonOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _isInit = true;

  // Form keys for validation per step (4 steps now)
  final List<GlobalKey<FormState>> _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // Step 1: Basic Info Controllers
  final _salonNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2: Salon Details Controllers
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController(text: 'https://voguestudio.com');
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();

  final List<Map<String, String>> _descriptionTemplates = [
    {
      'title': 'Premium Unisex Salon',
      'text': 'Welcome to our premium unisex salon where style meets sophistication. We offer a complete range of hair, beauty, and grooming services for men and women. Our experienced stylists use only the finest products and latest techniques to ensure you look and feel your best. From trendy haircuts to luxurious spa treatments, we provide personalized services in a relaxing ambiance. Visit us for a transformative beauty experience.'
    },
    {
      'title': 'Modern Hair Studio',
      'text': 'Step into our modern hair studio, your destination for contemporary hairstyling and color expertise. We specialize in precision cuts, creative coloring, and hair treatments using premium international brands. Our talented team stays updated with global trends to bring you the latest looks. Whether you want a classic style or bold transformation, we deliver exceptional results. Book your appointment today and discover the difference.'
    },
    {
      'title': 'Bridal Beauty Specialist',
      'text': 'Your trusted partner for bridal beauty and special occasion makeovers. We specialize in creating stunning bridal looks that enhance your natural beauty. Our comprehensive bridal packages include hair styling, makeup, mehendi, and pre-bridal treatments. With years of experience and attention to detail, we ensure you look picture-perfect on your big day. We also offer party makeup and hairstyling for all celebrations.'
    },
    {
      'title': 'Family Salon & Spa',
      'text': 'A welcoming family salon offering quality services for all ages. From kids\' first haircuts to senior styling, we cater to everyone with care and expertise. Our services include haircuts, styling, coloring, facials, waxing, and relaxing spa treatments. We maintain high hygiene standards and use gentle, quality products. Enjoy our comfortable atmosphere and friendly service. Walk-ins welcome, appointments preferred.'
    },
    {
      'title': 'Men\'s Grooming Lounge',
      'text': 'The ultimate grooming destination for the modern man. We offer expert haircuts, beard styling, shaves, facials, and grooming services tailored specifically for men. Our skilled barbers combine traditional techniques with contemporary styles. Relax in our masculine ambiance while we take care of your grooming needs. We use premium men\'s grooming products for the best results. Experience professional grooming at its finest.'
    }
  ];

  // Step 3: Business Profile State
  String _selectedPriceRange = 'BUDGET'; // BUDGET, MEDIUM, PREMIUM
  final _basePriceController = TextEditingController(text: '300');
  
  final List<String> _gendersServed = []; // 'MEN', 'WOMEN', 'UNISEX'
  bool _offersHomeService = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Prefill fields from registration page if passed as route arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, String>) {
        if (args.containsKey('ownerName')) {
          _ownerNameController.text = args['ownerName']!;
        }
        if (args.containsKey('email')) {
          _emailController.text = args['email']!;
        }
        if (args.containsKey('phone')) {
          _phoneController.text = args['phone']!;
        }
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _salonNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  // Form Validation and navigation helper
  void _nextStep() {
    if (_currentPage == 3) return; // Last page is submit page

    // Validate the current page's form
    if (_formKeys[_currentPage].currentState != null && 
        !_formKeys[_currentPage].currentState!.validate()) {
      return;
    }

    // Step-specific logical validations
    if (_currentPage == 1) {
      // Validate description length
      if (_descriptionController.text.trim().length < 20) {
        _showErrorSnackBar('Please provide a description of at least 20 characters.');
        return;
      }
    }
    
    if (_currentPage == 2) {
      // Check starting price
      final startingPrice = int.tryParse(_basePriceController.text) ?? 0;
      if (startingPrice < 20) {
        _showErrorSnackBar('Base price must be at least ₹20.');
        return;
      }
      // Check gender served
      if (_gendersServed.isEmpty) {
        _showErrorSnackBar('Please select at least one gender served.');
        return;
      }
    }

    setState(() {
      _currentPage++;
    });
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentPage == 0) return;
    setState(() {
      _currentPage--;
    });
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToStep(int stepIndex) {
    setState(() {
      _currentPage = stepIndex;
    });
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  // Handle final submission to API
  void _handleSubmit() async {
    if (!_agreedToTerms) return;

    setState(() {
      _isLoading = true;
    });

    final payload = {
      "businessName": _salonNameController.text.trim(),
      "ownerName": _ownerNameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "city": _cityController.text.trim(),
      "state": _stateController.text.trim(),
      "zipCode": _zipCodeController.text.trim(),
      "description": _descriptionController.text.trim(),
      "website": _websiteController.text.trim(),
      "genderServed": _gendersServed,
      "offersHomeService": _offersHomeService,
      "priceRange": _selectedPriceRange,
      "basePrice": int.tryParse(_basePriceController.text) ?? 300,
    };

    final result = await ApiService().submitOnboarding(payload);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['error'] ?? 'Submission failed. Please try again.');
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
                  'Application Submitted!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your registration onboarding request has been received successfully. Verify your email to continue step by step.',
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
                    color: AppColors.accentPurple.withValues(alpha: 0.10),
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

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildProgressIndicator(),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStepBasic(),
                            _buildStepDetails(),
                            _buildStepBusiness(),
                            _buildStepReview(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomNavBar(isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const RazorLogo(iconSize: 24, fontSize: 20),
          TextButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textSecondary),
            label: Text(
              'Back to Login',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final double progress = (_currentPage + 1) / 4.0;
    final List<String> stepNames = [
      'Basic Info',
      'Salon Details',
      'Business Profile',
      'Review & Submit'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepNames[_currentPage],
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Step ${_currentPage + 1} of 4',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                width: MediaQuery.of(context).size.width * progress - 48,
                decoration: BoxDecoration(
                  color: AppColors.accentPurple,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isTablet) {
    final bool isLastStep = _currentPage == 3;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _prevStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'PREVIOUS',
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: 2,
                child: _isLoading
                    ? Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.06),
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
                    : GradientButton(
                        text: isLastStep ? 'SUBMIT APPLICATION' : 'NEXT STEP',
                        borderRadius: 14,
                        onPressed: (isLastStep && !_agreedToTerms) ? null : (isLastStep ? _handleSubmit : _nextStep),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 1: Basic Information
  Widget _buildStepBasic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Let\'s start with basic info',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide basic contact and name details for your salon.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _salonNameController,
              hintText: 'Salon Name',
              prefixIcon: Icons.storefront_rounded,
              borderRadius: 14,
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter salon name' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _ownerNameController,
              hintText: 'Owner Name',
              prefixIcon: Icons.person_outline_rounded,
              borderRadius: 14,
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter owner name' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email Address',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              borderRadius: 14,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter email';
                final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegExp.hasMatch(val.trim())) return 'Please enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              borderRadius: 14,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(val.trim())) return 'Enter a valid 10-15 digit phone number';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: Salon Details
  Widget _buildStepDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about your Salon',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a sample description or write your own:',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            
            // Description Template list selector
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _descriptionTemplates.length,
                itemBuilder: (context, index) {
                  final template = _descriptionTemplates[index];
                  final isSelected = _descriptionController.text == template['text'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _descriptionController.text = template['text']!;
                      });
                    },
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentPurple.withValues(alpha: 0.10) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.accentPurple : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.text_fields_rounded,
                            size: 20,
                            color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.accentPurple : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe your salon, services, and specialties...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            CustomTextField(
              controller: _websiteController,
              hintText: 'Website (Optional)',
              prefixIcon: Icons.language_rounded,
              borderRadius: 14,
            ),
            
            const SizedBox(height: 20),
            Text(
              'Complete Address',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _addressController,
              hintText: 'Street Address',
              prefixIcon: Icons.location_on_outlined,
              borderRadius: 14,
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
            ),
            const SizedBox(height: 16),
            
            // TextFields for State and City instead of rigid dropdowns
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _stateController,
                    hintText: 'State',
                    prefixIcon: Icons.map_outlined,
                    borderRadius: 14,
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter State' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _cityController,
                    hintText: 'City',
                    prefixIcon: Icons.location_city_outlined,
                    borderRadius: 14,
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter City' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _zipCodeController,
              hintText: 'ZIP Code',
              prefixIcon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              borderRadius: 14,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter ZIP code';
                if (val.trim().length < 5 || val.trim().length > 10) return 'ZIP code must be 5 to 10 digits';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Business Profile
  Widget _buildStepBusiness() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Business Profile',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            
            // Price Range Cards
            Text(
              'Price Range*',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPriceCard('BUDGET', 'Budget', '₹1 - ₹999'),
                const SizedBox(width: 8),
                _buildPriceCard('MEDIUM', 'Moderate', '₹1K - ₹5,999'),
                const SizedBox(width: 8),
                _buildPriceCard('PREMIUM', 'Premium', '₹6K & Beyond'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Starting Price (basePrice)
            Text(
              'Base Price*',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _basePriceController,
              hintText: 'Enter Base Price',
              prefixIcon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              borderRadius: 14,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter base price';
                if ((int.tryParse(val) ?? 0) < 20) return 'Minimum ₹20 required';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimum: ₹20 • This is the base service charge for your salon bookings on GlowDew Partner.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Genders Served selector
            Text(
              'Gender Served*',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderCapsule('MEN'),
                const SizedBox(width: 8),
                _buildGenderCapsule('WOMEN'),
                const SizedBox(width: 8),
                _buildGenderCapsule('UNISEX'),
              ],
            ),

            const SizedBox(height: 24),
            
            // Home Service Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Service',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Do you provide services at customer\'s home?',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _offersHomeService,
                    activeThumbColor: AppColors.accentPurple,
                    activeTrackColor: AppColors.accentPurple.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() {
                        _offersHomeService = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(String value, String label, String range) {
    final bool isSelected = _selectedPriceRange == value;
    String symbol = '₹';
    if (value == 'MEDIUM') symbol = '₹₹';
    if (value == 'PREMIUM') symbol = '₹₹₹';
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriceRange = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.accentPurple : AppColors.borderLight,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                symbol,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.accentPurple : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.accentPurple : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                range,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCapsule(String gender) {
    final bool isSelected = _gendersServed.contains(gender);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _gendersServed.remove(gender);
            } else {
              _gendersServed.add(gender);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.accentPurple : AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            gender,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // STEP 4: Review & Submit
  Widget _buildStepReview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Please review your details',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Check all inputs carefully before submitting.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Basic Info Summary
            _buildReviewSectionHeader('Basic Information', 0),
            _buildReviewItem('Salon Name', _salonNameController.text),
            _buildReviewItem('Owner Name', _ownerNameController.text),
            _buildReviewItem('Email', _emailController.text),
            _buildReviewItem('Phone', _phoneController.text),
            const Divider(height: 32),

            // Salon Details Summary
            _buildReviewSectionHeader('Salon Details', 1),
            _buildReviewItem('Description', _descriptionController.text, isMultiline: true),
            _buildReviewItem('Website', _websiteController.text.isEmpty ? 'None' : _websiteController.text),
            _buildReviewItem('Address', _addressController.text),
            _buildReviewItem('City', _cityController.text),
            _buildReviewItem('State', _stateController.text),
            _buildReviewItem('ZIP Code', _zipCodeController.text),
            const Divider(height: 32),

            // Business Profile Summary
            _buildReviewSectionHeader('Business Information', 2),
            _buildReviewItem('Price Range', _selectedPriceRange),
            _buildReviewItem('Base Price', '₹${_basePriceController.text}'),
            _buildReviewItem('Gender Served', _gendersServed.join(', ')),
            _buildReviewItem('Home Service', _offersHomeService ? 'Yes' : 'No'),
            const Divider(height: 32),

            // Agreement checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppColors.accentPurple,
                    onChanged: (val) {
                      setState(() {
                        _agreedToTerms = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I agree to the Terms & Conditions and Privacy Policy',
                        style: GoogleFonts.inter(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: AppColors.textPrimary
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By submitting, you agree to our terms of service and privacy policy.',
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          color: AppColors.textSecondary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSectionHeader(String title, int stepIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.accentPurple,
          ),
        ),
        InkWell(
          onTap: () => _goToStep(stepIndex),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 14, color: AppColors.accentPurple),
                const SizedBox(width: 4),
                Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: isMultiline ? 1.4 : 1.2,
            ),
            maxLines: isMultiline ? 4 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
