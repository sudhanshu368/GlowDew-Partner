import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../services/api_service.dart';

class HomeServiceView extends StatefulWidget {
  final Map<String, dynamic>? salonDetail;

  const HomeServiceView({super.key, this.salonDetail});

  @override
  State<HomeServiceView> createState() => _HomeServiceViewState();
}

class _HomeServiceViewState extends State<HomeServiceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Settings State
  bool _isLoadingSettings = false;
  bool _isSavingSettings = false;
  bool _offersHomeService = false;
  bool _isEditingSettings = false;
  
  final _radiusController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _feeController = TextEditingController();

  // Bookings State
  bool _isLoadingBookings = false;
  List<Map<String, dynamic>> _homeServiceBookings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void didUpdateWidget(covariant HomeServiceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.salonDetail?['id'] != oldWidget.salonDetail?['id']) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _radiusController.dispose();
    _minOrderController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    _loadSettings();
    _loadBookings();
  }

  Future<void> _loadSettings() async {
    final salonId = widget.salonDetail?['id'];
    if (salonId == null) return;

    setState(() {
      _isLoadingSettings = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService().getHomeServiceSettings(salonId);
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
          if (res['success'] == true) {
            final data = res['data'] ?? {};
            _offersHomeService = data['offersHomeService'] ?? false;
            _radiusController.text = data['homeServiceRadius']?.toString() ?? '';
            _minOrderController.text = data['homeServiceMinOrder']?.toString() ?? '';
            _feeController.text = data['homeServiceFee']?.toString() ?? '';
            _isEditingSettings = false;
          } else {
            _errorMessage = res['error'] ?? 'Failed to load home service settings.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
          _errorMessage = 'Error loading settings: $e';
        });
      }
    }
  }

  Future<void> _loadBookings() async {
    final salonId = widget.salonDetail?['id'];
    if (salonId == null) return;

    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final res = await ApiService().getSalonBookings(salonId);
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          if (res['success'] == true) {
            final List<dynamic> bookingsList = res['data'] ?? [];
            _homeServiceBookings = bookingsList.where((b) {
              final isHomeType = b['isHomeService'] == true || 
                                 b['offersHomeService'] == true ||
                                 b['bookingType']?.toString().toUpperCase() == 'HOME_SERVICE' ||
                                 b['deliveryAddress'] != null ||
                                 b['homeServiceAddress'] != null;
              return isHomeType;
            }).map<Map<String, dynamic>>((b) {
              final customerName = b['customer']?['name'] ?? b['customerName'] ?? b['client']?['name'] ?? 'Unknown Client';
              final phone = b['customer']?['phone'] ?? b['phone'] ?? b['client']?['phone'] ?? 'N/A';
              
              String serviceName = 'Salon Service';
              if (b['service'] != null) {
                if (b['service'] is Map) {
                  serviceName = b['service']['name']?.toString() ?? 'Salon Service';
                } else if (b['service'].toString().isNotEmpty) {
                  serviceName = b['service'].toString();
                }
              } else if (b['services'] is List && (b['services'] as List).isNotEmpty) {
                final firstService = b['services'][0];
                if (firstService is Map) {
                  serviceName = firstService['name']?.toString() ?? 'Salon Service';
                } else {
                  serviceName = firstService.toString();
                }
              }

              final address = b['deliveryAddress'] ?? b['homeServiceAddress'] ?? b['address'] ?? 'Customer Location';
              final priceVal = b['grandTotal']?.toString() ?? b['finalBill']?.toString() ?? b['totalPrice']?.toString() ?? b['price']?.toString() ?? b['amount']?.toString() ?? '0';

              return {
                'id': b['bookingNumber']?.toString() ?? b['id']?.toString() ?? 'BKG-${b['bookingId'] ?? 'UNK'}',
                'customerName': customerName,
                'phone': phone,
                'service': serviceName,
                'address': address,
                'price': '₹$priceVal',
                'status': _normalizeStatus(b['status'] ?? b['bookingStatus']),
                'raw': b,
              };
            }).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  String _normalizeStatus(dynamic raw) {
    if (raw == null) return 'PENDING';
    final str = raw.toString().toUpperCase();
    if (str == 'IN_PROGRESS' || str == 'IN PROGRESS' || str == 'INPROGRESS') return 'SERVICE_IN_PROGRESS';
    return str;
  }

  Future<void> _handleSaveSettings() async {
    final salonId = widget.salonDetail?['id'];
    if (salonId == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSavingSettings = true;
    });

    final radius = double.tryParse(_radiusController.text.trim());
    final minOrder = double.tryParse(_minOrderController.text.trim());
    final fee = double.tryParse(_feeController.text.trim());

    // Dual-key mapping payload to ensure complete compatibility
    final payload = {
      // API Specifications
      'isHomeServiceActive': _offersHomeService,
      'maxTravelDistance': radius,
      'minimumOrderValue': minOrder,
      'travelFee': fee,

      // Database / Response Mappings
      'offersHomeService': _offersHomeService,
      'homeServiceRadius': radius,
      'homeServiceMinOrder': minOrder,
      'homeServiceFee': fee,
    };

    try {
      final res = await ApiService().updateHomeServiceSettings(salonId, payload);
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
        if (res['success'] == true) {
          _showSnackBar(res['message'] ?? 'Settings updated successfully!', isError: false);
          _loadSettings();
        } else {
          _showSnackBar(res['error'] ?? 'Failed to update settings.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
        _showSnackBar('An error occurred: $e', isError: true);
      }
    }
  }

  Future<void> _handleUpdateBookingStatus(dynamic bookingId, String newStatus) async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final res = await ApiService().updateHomeServiceStatus(bookingId, newStatus);
      if (mounted) {
        if (res['success'] == true) {
          _showSnackBar(res['message'] ?? 'Booking status updated successfully!', isError: false);
          _loadBookings();
        } else {
          _showSnackBar(res['error'] ?? 'Failed to update status.', isError: true);
          setState(() {
            _isLoadingBookings = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('An error occurred: $e', isError: true);
        setState(() {
          _isLoadingBookings = false;
        });
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
        automaticallyImplyLeading: false,
        title: Text(
          'Home Service Manager',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accentPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentPurple,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
          tabs: const [
            Tab(text: 'Service Configuration'),
            Tab(text: 'Bookings Tracker'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSettingsTab(),
            _buildBookingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_isLoadingSettings) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (!_isEditingSettings) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: FadeSlideTransition(
          delay: const Duration(milliseconds: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_offersHomeService) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home Grooming Active',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Your salon is open for home services.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildReadOnlyDetailRow(
                        icon: Icons.map_outlined,
                        label: 'Maximum Travel Range',
                        value: '${_radiusController.text.isNotEmpty ? _radiusController.text : "0"} km',
                      ),
                      const SizedBox(height: 20),
                      _buildReadOnlyDetailRow(
                        icon: Icons.sell_outlined,
                        label: 'Minimum Order Value',
                        value: '₹${_minOrderController.text.isNotEmpty ? _minOrderController.text : "0"}',
                      ),
                      const SizedBox(height: 20),
                      _buildReadOnlyDetailRow(
                        icon: Icons.delivery_dining_rounded,
                        label: 'Home Grooming Flat Fee',
                        value: _feeController.text.trim().isEmpty || _feeController.text.trim() == '0'
                            ? 'Free Delivery / No Fee'
                            : '₹${_feeController.text}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditingSettings = true;
                      });
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.accentPurple),
                    label: Text(
                      'Edit Configurations',
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_repair_service_rounded,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Home Grooming Service Disabled',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enable home service to let clients book appointments at their location, specify your travel range, minimum order requirements, and travel fees.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: GradientButton(
                    text: 'Enable & Configure',
                    borderRadius: 12,
                    onPressed: () {
                      setState(() {
                        _isEditingSettings = true;
                        _offersHomeService = true;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: FadeSlideTransition(
        delay: const Duration(milliseconds: 50),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      value: _offersHomeService,
                      title: Text(
                        'Offers Home Grooming Service',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Enable this to receive and service client bookings at their location.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.accentPurple,
                      onChanged: (val) {
                        setState(() {
                          _offersHomeService = val;
                        });
                      },
                    ),
                    if (_offersHomeService) ...[
                      const Divider(height: 32),
                      _buildFieldLabel('Maximum Travel Range (km)'),
                      CustomTextField(
                        hintText: 'e.g. 15',
                        prefixIcon: Icons.map_outlined,
                        keyboardType: TextInputType.number,
                        controller: _radiusController,
                        validator: (val) {
                          if (_offersHomeService && (val == null || val.trim().isEmpty)) {
                            return 'Please enter travel range';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Minimum Order Value (₹)'),
                      CustomTextField(
                        hintText: 'e.g. 1000',
                        prefixIcon: Icons.sell_outlined,
                        keyboardType: TextInputType.number,
                        controller: _minOrderController,
                        validator: (val) {
                          if (_offersHomeService && (val == null || val.trim().isEmpty)) {
                            return 'Please enter minimum order value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Home Grooming Flat Fee (Optional - ₹)'),
                      CustomTextField(
                        hintText: 'e.g. 200',
                        prefixIcon: Icons.delivery_dining_rounded,
                        keyboardType: TextInputType.number,
                        controller: _feeController,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          _loadSettings();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: _isSavingSettings
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                              ),
                            )
                          : GradientButton(
                              text: 'Save Configurations',
                              borderRadius: 12,
                              onPressed: _handleSaveSettings,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (_isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
        ),
      );
    }

    if (_homeServiceBookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBookings,
        color: AppColors.accentPurple,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      color: AppColors.accentPurple,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Home Service Bookings',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All scheduled client home services will appear here.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.accentPurple,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20.0),
        itemCount: _homeServiceBookings.length,
        itemBuilder: (context, index) {
          final b = _homeServiceBookings[index];
          final bookingId = b['id'];
          final status = b['status'] as String;

          return FadeSlideTransition(
            delay: Duration(milliseconds: 50 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          b['customerName']!,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${b['phone']}',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.content_cut_rounded, b['service']!),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.pin_drop_outlined, b['address']!),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.sell_outlined, 'Total Price: ${b['price']}'),
                  const Divider(height: 24),
                  _buildStatusActionButtons(bookingId, status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildReadOnlyDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.accentPurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case 'PENDING':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        break;
      case 'CONFIRMED':
        color = AppColors.accentPurple;
        bgColor = AppColors.accentPurple.withValues(alpha: 0.1);
        break;
      case 'EN_ROUTE':
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        break;
      case 'ARRIVED_AT_LOCATION':
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
        break;
      case 'SERVICE_IN_PROGRESS':
        color = const Color(0xFFEC4899);
        bgColor = const Color(0xFFEC4899).withValues(alpha: 0.1);
        break;
      case 'COMPLETED':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        break;
      case 'CANCELLED':
        color = Colors.redAccent;
        bgColor = Colors.redAccent.withValues(alpha: 0.1);
        break;
      default:
        color = AppColors.textSecondary;
        bgColor = AppColors.borderLight;
    }

    String displayText = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusActionButtons(dynamic bookingId, String status) {
    if (status == 'COMPLETED' || status == 'CANCELLED') {
      return const SizedBox.shrink();
    }

    String nextStatus = '';
    String buttonText = '';
    IconData icon = Icons.check;

    if (status == 'PENDING' || status == 'CONFIRMED') {
      nextStatus = 'EN_ROUTE';
      buttonText = 'Mark En Route';
      icon = Icons.directions_car_rounded;
    } else if (status == 'EN_ROUTE') {
      nextStatus = 'ARRIVED_AT_LOCATION';
      buttonText = 'Mark Arrived';
      icon = Icons.pin_drop_rounded;
    } else if (status == 'ARRIVED_AT_LOCATION') {
      nextStatus = 'SERVICE_IN_PROGRESS';
      buttonText = 'Start Grooming';
      icon = Icons.play_arrow_rounded;
    } else if (status == 'SERVICE_IN_PROGRESS') {
      nextStatus = 'COMPLETED';
      buttonText = 'Complete Booking';
      icon = Icons.task_alt_rounded;
    }

    if (nextStatus.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => _handleUpdateBookingStatus(bookingId, nextStatus),
          icon: Icon(icon, size: 15, color: AppColors.accentPurple),
          label: Text(
            buttonText,
            style: GoogleFonts.inter(
              color: AppColors.accentPurple,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accentPurple),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}
