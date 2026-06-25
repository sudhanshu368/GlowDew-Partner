import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../services/api_service.dart';

class BookingsTab extends StatefulWidget {
  final Map<String, dynamic>? salonDetail;
  const BookingsTab({super.key, this.salonDetail});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  // Filters State
  String _searchQuery = '';
  String _selectedStatusFilter = 'All Status';
  bool _showEmptyState = false;

  // Bookings Data State
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
  dynamic _salonId;

  @override
  void initState() {
    super.initState();
    _loadSalonAndBookings();
  }

  @override
  void didUpdateWidget(covariant BookingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.salonDetail?['id'] != oldWidget.salonDetail?['id']) {
      _loadSalonAndBookings();
    }
  }

  Future<void> _loadSalonAndBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      dynamic salonId = widget.salonDetail?['id'];
      
      if (salonId == null) {
        // Fallback: If parent doesn't have salonId, fetch profile to see if it's there
        final profileRes = await ApiService().getAuthProfile();
        if (profileRes['success'] == true) {
          salonId = profileRes['data']?['salonId'];
        }
      }

      if (salonId == null) {
        // Fallback 2: Check all salons and match by user email
        final salonsRes = await ApiService().getSalons();
        if (salonsRes['success'] == true && salonsRes['data'] is List) {
          final profileRes = await ApiService().getProfile();
          final userEmail = profileRes['data']?['email'];
          final userPhone = profileRes['data']?['phone'];
          
          final List<dynamic> salonsList = salonsRes['data'];
          for (var s in salonsList) {
            if (s['email'] == userEmail || s['phone'] == userPhone) {
              salonId = s['id'];
              break;
            }
          }
          if (salonId == null && salonsList.isNotEmpty) {
            salonId = salonsList.first['id'];
          }
        }
      }

      if (salonId == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Unable to determine Salon ID.';
          _isLoading = false;
        });
        return;
      }

      _salonId = salonId;
      await _fetchBookings();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookings() async {
    if (_salonId == null) return;
    try {
      final res = await ApiService().getSalonBookings(_salonId);
      if (!mounted) return;
      if (res['success'] == true && res['data'] is List) {
        final List<dynamic> bookingList = res['data'];
        setState(() {
          _bookings = bookingList.map((b) => _mapBackendBookingToUI(b)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['error'] ?? 'Failed to fetch bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapBackendBookingToUI(dynamic b) {
    // 1. Resolve ID and bookingNumber
    final id = b['id']?.toString() ?? b['bookingId']?.toString() ?? b['_id']?.toString() ?? 'BKG-Unknown';
    final bookingNumber = b['bookingNumber']?.toString() ?? id;

    // 2. Customer details
    final customerName = b['customer']?['name'] ?? b['customerName'] ?? b['client']?['name'] ?? b['clientName'] ?? 'Unknown Client';
    final phone = b['customer']?['phone'] ?? b['phone'] ?? b['client']?['phone'] ?? b['clientPhone'] ?? '';
    final email = b['customer']?['email'] ?? b['client']?['email'] ?? b['email'] ?? '';

    // 3. Service details & Category
    String serviceName = 'Salon Service';
    String categoryName = 'General';
    if (b['service'] != null) {
      if (b['service'] is Map) {
        serviceName = b['service']['name']?.toString() ?? 'Salon Service';
        categoryName = b['service']['category']?.toString() ?? 'General';
      } else if (b['service'].toString().isNotEmpty) {
        serviceName = b['service'].toString();
      }
    } else if (b['services'] is List && (b['services'] as List).isNotEmpty) {
      final firstService = b['services'][0];
      if (firstService is Map) {
        serviceName = firstService['name']?.toString() ?? 'Salon Service';
        categoryName = firstService['category']?.toString() ?? 'General';
      } else {
        serviceName = firstService.toString();
      }
    } else if (b['serviceName'] != null) {
      serviceName = b['serviceName'].toString();
    }

    if (b['category'] != null) {
      categoryName = b['category'].toString();
    }

    // 4. Date and time (check startTime first, since it is the appointment start time in ISO format)
    final dateTime = _formatDateTime(
      b['startTime'] ?? b['date'] ?? b['bookingDate'], 
      b['time'] ?? b['bookingTime'], 
      b['startTime'] ?? b['dateTime'] ?? b['createdAt']
    );

    // 5. Payments and prices
    final paymentStatus = _normalizePaymentStatus(b['paymentStatus'] ?? b['payment']);
    final price = b['grandTotal']?.toString() ?? b['finalBill']?.toString() ?? b['totalPrice']?.toString() ?? b['price']?.toString() ?? b['amount']?.toString() ?? b['totalAmount']?.toString() ?? '0';

    // 6. Stylist
    final stylist = b['employee']?['name'] ?? b['stylist'] ?? b['stylistName'] ?? 'No Stylist';

    // 7. Booking Status
    final bookingStatus = _normalizeBookingStatus(b['status'] ?? b['bookingStatus']);

    // 8. Financial fields & Extra details
    final servicePrice = b['servicePrice'] ?? (b['service'] is Map ? b['service']['price'] : null) ?? 0;
    final discount = b['discount'] ?? 0;
    final extraChargeAmount = b['extraChargeAmount'] ?? 0;
    final customerPay = b['customerPay'] ?? 0;
    final salonPay = b['salonPay'] ?? 0;
    final serviceFee = b['serviceFee'] ?? 0;
    final platformFee = b['platformFee'] ?? 0;
    final taxAmount = b['taxAmount'] ?? 0;
    final grandTotal = b['grandTotal'] ?? 0;
    
    final notes = b['notes']?.toString() ?? '';
    final cancellationReason = b['cancellationReason']?.toString() ?? '';
    final cancelledAt = b['cancelledAt']?.toString() ?? '';
    final cancelledBy = b['cancelledBy']?.toString() ?? '';

    return {
      'id': id,
      'bookingNumber': bookingNumber,
      'customerName': customerName,
      'phone': phone,
      'email': email,
      'service': serviceName,
      'category': categoryName,
      'dateTime': dateTime,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'price': price,
      'stylist': stylist,
      'servicePrice': servicePrice,
      'discount': discount,
      'extraChargeAmount': extraChargeAmount,
      'customerPay': customerPay,
      'salonPay': salonPay,
      'serviceFee': serviceFee,
      'platformFee': platformFee,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt,
      'cancelledBy': cancelledBy,
    };
  }

  String _normalizePaymentStatus(dynamic raw) {
    if (raw == null) return 'Unpaid';
    final str = raw.toString().toLowerCase();
    if (str == 'paid') return 'Paid';
    if (str == 'partial') return 'Partial';
    if (str == 'pending') return 'Pending';
    return 'Unpaid';
  }

  String _normalizeBookingStatus(dynamic raw) {
    if (raw == null) return 'Pending';
    final str = raw.toString().toLowerCase();
    if (str == 'pending') return 'Pending';
    if (str == 'confirmed') return 'Confirmed';
    if (str == 'in progress' || str == 'inprogress' || str == 'in_progress') return 'In Progress';
    if (str == 'completed') return 'Completed';
    if (str == 'cancelled' || str == 'canceled') return 'Cancelled';
    return 'Pending';
  }

  String _formatDateTime(dynamic rawDate, dynamic rawTime, dynamic rawDateTime) {
    if (rawDateTime != null && rawDateTime.toString().isNotEmpty) {
      final str = rawDateTime.toString();
      if (str.contains('•')) return str;
      
      try {
        final parsed = DateTime.parse(str);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = parsed.day.toString().padLeft(2, '0');
        final monthStr = months[parsed.month - 1];
        final year = parsed.year;
        
        int hour = parsed.hour;
        final minute = parsed.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        final hourStr = hour.toString().padLeft(2, '0');
        
        return '$monthStr $day, $year • $hourStr:$minute $period';
      } catch (_) {
        return str;
      }
    }
    
    if (rawDate != null) {
      String dateStr = rawDate.toString();
      try {
        final parsed = DateTime.parse(dateStr);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = parsed.day.toString().padLeft(2, '0');
        final monthStr = months[parsed.month - 1];
        final year = parsed.year;
        dateStr = '$monthStr $day, $year';
      } catch (_) {
        // use rawDate as is
      }
      if (rawTime != null) {
        return '$dateStr • ${rawTime.toString()}';
      }
      return dateStr;
    }
    
    return 'Date/Time Unknown';
  }

  // Dynamic Statistics Calculations
  int get _totalBookings => _bookings.length;

  int get _pendingBookings => _bookings.where((b) => b['bookingStatus'] == 'Pending').length;

  int get _confirmedBookings => _bookings.where((b) => b['bookingStatus'] == 'Confirmed' || b['bookingStatus'] == 'In Progress').length;

  int get _paidBookings => _bookings.where((b) => b['paymentStatus'] == 'Paid').length;

  // Filter Bookings logic
  List<Map<String, dynamic>> get _filteredBookings {
    if (_showEmptyState) return [];

    return _bookings.where((booking) {
      final name = (booking['customerName'] as String).toLowerCase();
      final phone = (booking['phone'] as String);
      final service = (booking['service'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();

      final nameMatch = name.contains(query) || phone.contains(query) || service.contains(query);
      
      if (_selectedStatusFilter == 'All Status') {
        return nameMatch;
      } else {
        return nameMatch && booking['bookingStatus'] == _selectedStatusFilter;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth <= 750;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: FadeSlideTransition(
            delay: const Duration(milliseconds: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                _buildHeader(screenWidth),
                const SizedBox(height: 24),

                // Responsive summary cards
                _buildStatisticsGrid(screenWidth),
                const SizedBox(height: 28),

                // Search & Filters bar
                _buildSearchAndFilters(screenWidth),
                const SizedBox(height: 20),

                // List Section
                _buildDynamicBookingSection(isMobile),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeader(double screenWidth) {
    final isMobile = screenWidth < 600;

    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Management',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'View and manage all customer bookings',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _loadSalonAndBookings,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, size: 12, color: AppColors.accentBlue),
                const SizedBox(width: 4),
                Text(
                  'Refresh',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Show/Hide Mock Empty State
        GestureDetector(
          onTap: () {
            setState(() {
              _showEmptyState = !_showEmptyState;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.15)),
            ),
            child: Text(
              _showEmptyState ? 'Show Data' : 'Show Empty',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.accentPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleSection,
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: actionButtons,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        titleSection,
        actionButtons,
      ],
    );
  }

  // --- 2. STATISTICS SECTION ---
  Widget _buildStatisticsGrid(double screenWidth) {
    int crossAxisCount = 4;
    double childAspectRatio = 1.8;

    if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.35;
    } else if (screenWidth < 950) {
      crossAxisCount = 2;
      childAspectRatio = 2.1;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Bookings',
          value: '$_totalBookings',
          icon: Icons.book_online_rounded,
          bgColor: const Color(0xFFF3E8FF), // Soft purple
          iconColor: const Color(0xFF7E22CE),
        ),
        _buildStatCard(
          title: 'Pending Slots',
          value: '$_pendingBookings',
          icon: Icons.hourglass_empty_rounded,
          bgColor: const Color(0xFFFEF3C7), // Soft gold
          iconColor: const Color(0xFFB45309),
        ),
        _buildStatCard(
          title: 'Confirmed Slots',
          value: '$_confirmedBookings',
          icon: Icons.check_circle_outline_rounded,
          bgColor: const Color(0xFFD1FAE5), // Soft green
          iconColor: const Color(0xFF047857),
        ),
        _buildStatCard(
          title: 'Paid Bookings',
          value: '$_paidBookings',
          icon: Icons.task_alt_rounded,
          bgColor: const Color(0xFFDBEAFE), // Soft blue
          iconColor: const Color(0xFF1D4ED8),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. FILTER BAR ---
  Widget _buildSearchAndFilters(double screenWidth) {
    final isMobile = screenWidth < 700;

    final searchField = Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search client name, phone, service...',
          hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

    final statusDropdown = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          onChanged: (val) {
            setState(() {
              _selectedStatusFilter = val!;
            });
          },
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
          isExpanded: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          items: ['All Status', 'Pending', 'Confirmed', 'In Progress', 'Completed', 'Cancelled']
              .map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  const Icon(Icons.toggle_on_rounded, color: AppColors.accentPurple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          statusDropdown,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: statusDropdown),
      ],
    );
  }

  // --- 4. BOOKINGS VIEW CONTROLLER ---
  Widget _buildDynamicBookingSection(bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to Load Bookings',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSalonAndBookings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final bookings = _filteredBookings;

    if (bookings.isEmpty) {
      return _buildEmptyStateView();
    }

    if (isMobile) {
      return Column(
        children: List.generate(bookings.length, (index) {
          final booking = bookings[index];
          return _buildMobileCard(booking);
        }),
      );
    }

    return Column(
      children: [
        _buildTableHeader(),
        const SizedBox(height: 4),
        ...List.generate(bookings.length, (index) {
          final booking = bookings[index];
          return _buildTableRow(booking, index);
        }),
      ],
    );
  }

  // --- 5. TABLE LAYOUT (DESKTOP) ---
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Booking ID', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text('Customer Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text('Selected Service', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text('Date & Time Slot', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Payment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> booking, int index) {
    final id = booking['id'] as String;
    final bookingNumber = (booking['bookingNumber'] ?? id) as String;
    final customerName = booking['customerName'] as String;
    final phone = booking['phone'] as String;
    final service = booking['service'] as String;
    final dateTime = booking['dateTime'] as String;
    final paymentStatus = booking['paymentStatus'] as String;
    final bookingStatus = booking['bookingStatus'] as String;
    final category = (booking['category'] ?? 'General') as String;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ID
          Expanded(
            flex: 2,
            child: Text(
              bookingNumber,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.accentPurple, fontSize: 13),
            ),
          ),

          // Customer Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Service / Category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Category: $category',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Date Time
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: AppColors.textLight, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateTime,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Payment Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildPaymentChip(paymentStatus),
              ],
            ),
          ),

          // Booking Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildStatusChip(bookingStatus),
              ],
            ),
          ),

          // Actions
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionsMenu(booking),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. CARD LAYOUT (MOBILE) ---
  Widget _buildMobileCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
    final bookingNumber = (booking['bookingNumber'] ?? id) as String;
    final customerName = booking['customerName'] as String;
    final phone = booking['phone'] as String;
    final service = booking['service'] as String;
    final dateTime = booking['dateTime'] as String;
    final paymentStatus = booking['paymentStatus'] as String;
    final bookingStatus = booking['bookingStatus'] as String;
    final category = (booking['category'] ?? 'General') as String;
    final price = booking['price'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bookingNumber,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPurple,
                  fontSize: 14,
                ),
              ),
              _buildStatusChip(bookingStatus),
            ],
          ),
          const Divider(height: 20),
          Text(
            customerName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phone,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Service', service),
          _buildInfoRow('Date & Time', dateTime),
          _buildInfoRow('Category', category),
          _buildInfoRow('Cost', '₹$price'),
          
          const Divider(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Payment: ',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  _buildPaymentChip(paymentStatus),
                ],
              ),
              _buildActionsMenu(booking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS POPUP ---
  Widget _buildActionsMenu(Map<String, dynamic> booking) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      tooltip: 'Actions',
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (String action) {
        _handleBookingAction(action, booking);
      },
      itemBuilder: (BuildContext context) => [
        _buildPopupItem('View Details', Icons.visibility_outlined, Colors.blue),
        _buildPopupItem('Confirm Booking', Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
        _buildPopupItem('Reschedule Slot', Icons.schedule_rounded, const Color(0xFFF59E0B)),
        _buildPopupItem('Mark Completed', Icons.task_alt_rounded, const Color(0xFF3B82F6)),
        _buildPopupItem('Cancel Booking', Icons.cancel_outlined, const Color(0xFFEF4444)),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBookingAction(String action, Map<String, dynamic> booking) {
    switch (action) {
      case 'View Details':
        _showDetailsModal(booking);
        break;
      case 'Confirm Booking':
        _confirmBookingAPI(booking);
        break;
      case 'Reschedule Slot':
        _showAddEditBookingModal(booking: booking);
        break;
      case 'Mark Completed':
        _markCompletedAPI(booking);
        break;
      case 'Cancel Booking':
        _confirmCancelBooking(booking);
        break;
    }
  }

  Future<void> _confirmBookingAPI(Map<String, dynamic> booking) async {
    _showLoadingDialog('Confirming booking...');
    try {
      final res = await ApiService().confirmBooking(booking['id'].toString());
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (res['success'] == true) {
        setState(() {
          booking['bookingStatus'] = 'Confirmed';
        });
        _showToast('Booking ${booking['id']} has been confirmed!');
      } else {
        _showToast(res['error'] ?? 'Failed to confirm booking.', isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showToast('Error: $e', isSuccess: false);
    }
  }

  Future<void> _markCompletedAPI(Map<String, dynamic> booking) async {
    _showLoadingDialog('Marking booking as completed...');
    try {
      final res = await ApiService().updateBookingStatus(booking['id'].toString(), 'COMPLETED');
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (res['success'] == true) {
        setState(() {
          booking['bookingStatus'] = 'Completed';
          booking['paymentStatus'] = 'Paid';
        });
        _showToast('Booking ${booking['id']} marked as completed & fully paid!');
      } else {
        _showToast(res['error'] ?? 'Failed to complete booking.', isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showToast('Error: $e', isSuccess: false);
    }
  }

  void _showToast(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: const Duration(seconds: 2),
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
              Icon(isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancelBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Cancel Appointment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: Text('Are you sure you want to cancel the booking "${booking['id']}" for ${booking['customerName']}?', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Slot', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close confirm dialog
                _cancelBookingAPI(booking);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Cancel Booking', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBookingAPI(Map<String, dynamic> booking) async {
    _showLoadingDialog('Cancelling booking...');
    try {
      final res = await ApiService().cancelPendingBooking(booking['id'].toString());
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (res['success'] == true) {
        setState(() {
          booking['bookingStatus'] = 'Cancelled';
        });
        _showToast('Booking ${booking['id']} cancelled.', isSuccess: false);
      } else {
        _showToast(res['error'] ?? 'Failed to cancel booking.', isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showToast('Error: $e', isSuccess: false);
    }
  }

  // --- STATUS CHIPS ---
  Widget _buildPaymentChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = const Color(0xFF10B981);
        break;
      case 'partial':
        color = const Color(0xFFF59E0B);
        break;
      case 'unpaid':
      default:
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = const Color(0xFF10B981);
        break;
      case 'pending':
        color = AppColors.accentPurple;
        break;
      case 'in progress':
        color = const Color(0xFF3B82F6);
        break;
      case 'completed':
        color = const Color(0xFF10B981);
        break;
      case 'cancelled':
      default:
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- EMPTY STATE VIEW ---
  Widget _buildEmptyStateView() {
    return Center(
      child: FadeSlideTransition(
        delay: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.accentPurple,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No Bookings Found',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We couldn\'t find any bookings matching your current filters.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DETAILS MODAL Draggable/Scrollable (OVERFLOW-SAFE) ---
  void _showDetailsModal(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
    final bookingNumber = (booking['bookingNumber'] ?? id) as String;
    final customerName = booking['customerName'] as String;
    final phone = booking['phone'] as String;
    final email = booking['email']?.toString() ?? '';
    final service = booking['service'] as String;
    final dateTime = booking['dateTime'] as String;
    final paymentStatus = booking['paymentStatus'] as String;
    final bookingStatus = booking['bookingStatus'] as String;
    final category = (booking['category'] ?? 'General') as String;
    final price = booking['price'] as String;

    final notes = booking['notes']?.toString() ?? '';
    final cancellationReason = booking['cancellationReason']?.toString() ?? '';
    final cancelledAt = booking['cancelledAt']?.toString() ?? '';
    final cancelledBy = booking['cancelledBy']?.toString() ?? '';

    // Financial breakdown fields
    final double servicePrice = double.tryParse(booking['servicePrice']?.toString() ?? '') ?? 0.0;
    final double discount = double.tryParse(booking['discount']?.toString() ?? '') ?? 0.0;
    final double extraChargeAmount = double.tryParse(booking['extraChargeAmount']?.toString() ?? '') ?? 0.0;
    final double customerPay = double.tryParse(booking['customerPay']?.toString() ?? '') ?? 0.0;
    final double salonPay = double.tryParse(booking['salonPay']?.toString() ?? '') ?? 0.0;
    final double serviceFee = double.tryParse(booking['serviceFee']?.toString() ?? '') ?? 0.0;
    final double platformFee = double.tryParse(booking['platformFee']?.toString() ?? '') ?? 0.0;
    final double taxAmount = double.tryParse(booking['taxAmount']?.toString() ?? '') ?? 0.0;
    final double grandTotal = double.tryParse(booking['grandTotal']?.toString() ?? '') ?? 0.0;

    List<dynamic> loadedServices = [];
    bool isLoadingServices = true;
    String? servicesError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                // Load services dynamically
                if (isLoadingServices && servicesError == null && loadedServices.isEmpty) {
                  ApiService().getBookingServices(id).then((res) {
                    if (res['success'] == true && res['data'] is List) {
                      setModalState(() {
                        loadedServices = res['data'];
                        isLoadingServices = false;
                      });
                    } else {
                      setModalState(() {
                        servicesError = res['error'] ?? 'No services details found';
                        isLoadingServices = false;
                      });
                    }
                  }).catchError((err) {
                    setModalState(() {
                      servicesError = err.toString();
                      isLoadingServices = false;
                    });
                  });
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking Specifics',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailItem(Icons.tag_rounded, 'Booking Number', bookingNumber),
                      if (bookingNumber != id)
                        _buildDetailItem(Icons.fingerprint_rounded, 'Database ID', id),
                      _buildDetailItem(Icons.person_outline_rounded, 'Client', customerName),
                      _buildDetailItem(Icons.phone_iphone_rounded, 'Phone Contact', phone),
                      if (email.isNotEmpty)
                        _buildDetailItem(Icons.email_outlined, 'Email Address', email),
                      _buildDetailItem(Icons.content_cut_rounded, 'Service Selected', service),
                      _buildDetailItem(Icons.category_rounded, 'Category', category),
                      
                      // Dynamic Extra Services
                      if (isLoadingServices)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt_rounded, size: 16, color: AppColors.textLight),
                              const SizedBox(width: 10),
                              Text('Services List', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple)),
                              ),
                            ],
                          ),
                        )
                      else if (loadedServices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.list_alt_rounded, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Text('All Included Services:', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 26.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: loadedServices.map<Widget>((s) {
                                    final sName = s is Map ? (s['name'] ?? 'Service') : s.toString();
                                    final sPrice = s is Map ? (s['price'] ?? s['cost'] ?? '') : '';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('• $sName', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                          if (sPrice.toString().isNotEmpty)
                                            Text('₹$sPrice', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      _buildDetailItem(Icons.calendar_month_rounded, 'Date & Time', dateTime),
                      
                      // Notes section
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Client Notes',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade100),
                          ),
                          child: Text(
                            notes,
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],

                      // Cancellation Details
                      if (bookingStatus.toLowerCase() == 'cancelled' || cancellationReason.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cancellation Details',
                                    style: GoogleFonts.outfit(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, color: Colors.redAccent),
                              if (cancellationReason.isNotEmpty) ...[
                                Text(
                                  'Reason:',
                                  style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cancellationReason,
                                  style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 13, height: 1.4),
                                ),
                              ],
                              if (cancelledAt.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cancelled At:',
                                      style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _formatDateTime(null, null, cancelledAt),
                                      style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                              if (cancelledBy.isNotEmpty && cancelledBy != 'null') ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cancelled By:',
                                      style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      cancelledBy,
                                      style: GoogleFonts.inter(color: Colors.red.shade900, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Wrap status chips in Row for detail modal
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text('Payment Status: ', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            _buildPaymentChip(paymentStatus),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text('Booking Status: ', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            _buildStatusChip(bookingStatus),
                          ],
                        ),
                      ),
                      
                      // Detailed Bill breakdown card
                      const SizedBox(height: 16),
                      Text(
                        'Payment Receipt Breakdown',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            _buildBillRow('Service Price', '₹${servicePrice > 0 ? servicePrice.toStringAsFixed(2) : (double.tryParse(price) ?? 0.0).toStringAsFixed(2)}'),
                            if (discount > 0)
                              _buildBillRow('Discount Applied', '-₹${discount.toStringAsFixed(2)}', valueColor: const Color(0xFF10B981)),
                            if (extraChargeAmount > 0)
                              _buildBillRow('Extra Charges', '+₹${extraChargeAmount.toStringAsFixed(2)}'),
                            if (serviceFee > 0)
                              _buildBillRow('Service Fee', '+₹${serviceFee.toStringAsFixed(2)}'),
                            if (platformFee > 0)
                              _buildBillRow('Platform Fee', '+₹${platformFee.toStringAsFixed(2)}'),
                            if (taxAmount > 0)
                              _buildBillRow('Tax Amount', '+₹${taxAmount.toStringAsFixed(2)}'),
                            const Divider(height: 20),
                            _buildBillRow(
                              'Grand Total', 
                              '₹${grandTotal > 0 ? grandTotal.toStringAsFixed(2) : (double.tryParse(price) ?? 0.0).toStringAsFixed(2)}', 
                              isBold: true,
                              fontSize: 15,
                              valueColor: AppColors.accentPurple,
                            ),
                            if (customerPay > 0 || salonPay > 0) ...[
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('Customer Paid', style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text('₹${customerPay.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('Salon Earnings', style: GoogleFonts.inter(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text('₹${salonPay.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddEditBookingModal(booking: booking);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.accentPurple),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Reschedule Slot',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Done',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false, double fontSize = 12, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize, 
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- SHOW ADD / EDIT / RESCHEDULE BOOKING MODAL DIALOG ---
  void _showAddEditBookingModal({Map<String, dynamic>? booking}) {
    AddEditBookingForm.show(
      context,
      booking: booking,
      salonId: _salonId,
      onSave: (updatedData) {
        setState(() {
          if (booking != null) {
            final index = _bookings.indexWhere((element) => element['id'] == booking['id']);
            if (index != -1) {
              _bookings[index] = updatedData;
            }
          } else {
            _bookings.insert(0, updatedData);
          }
        });
        _showToast(booking != null ? 'Booking rescheduled/updated!' : 'Manual booking created successfully!');
      },
    );
  }
}

// --- SUB-WIDGET: BOOKING FORM (OVERFLOW FREE SCROLL VIEWS & KEYBOARD OFFSET SAFEGARDS) ---

class AddEditBookingForm extends StatefulWidget {
  final Map<String, dynamic>? booking;
  final dynamic salonId;
  final Function(Map<String, dynamic> updatedData) onSave;

  const AddEditBookingForm({
    super.key,
    this.booking,
    this.salonId,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    Map<String, dynamic>? booking,
    dynamic salonId,
    required Function(Map<String, dynamic> updatedData) onSave,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return AddEditBookingForm(booking: booking, salonId: salonId, onSave: onSave);
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              child: AddEditBookingForm(booking: booking, salonId: salonId, onSave: onSave),
            ),
          );
        },
      );
    }
  }

  @override
  State<AddEditBookingForm> createState() => _AddEditBookingFormState();
}

class _AddEditBookingFormState extends State<AddEditBookingForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _priceController;
  
  late String _selectedService;
  late String _selectedStylist;
  late String _selectedTimeSlot;
  late String _selectedPaymentStatus;
  late String _selectedBookingStatus;
  late DateTime _selectedDate;

  bool _isSaving = false;
  bool _showSuccessAnimation = false;

  bool _isLoadingSlots = false;
  List<String> _dynamicSlots = [];

  final List<String> _servicesList = [
    'Premium Haircut & Styling',
    'Detox Facial & Beard Spa',
    'Balayage Hair Coloring',
    'Gel Nail Art & Mani-Pedi',
    'Royal Hair Therapy & Spa',
    'Deep Tissue Swedish Massage',
    'Bridal Makeup Package',
    'Hydrating Face Glow Mask'
  ];

  final List<String> _stylistsList = [
    'Alex Carter',
    'Sarah Jenkins',
    'Marcus Vance',
    'Elena Rostova',
    'No Stylist'
  ];

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM'
  ];

  final List<String> _paymentStatuses = ['Paid', 'Partial', 'Unpaid'];
  final List<String> _bookingStatuses = ['Pending', 'Confirmed', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    final b = widget.booking;

    _nameController = TextEditingController(text: b != null ? b['customerName'] : '');
    _phoneController = TextEditingController(text: b != null ? b['phone'] : '');
    _priceController = TextEditingController(text: b != null ? b['price'] : '1200');

    _selectedService = b != null ? b['service'] : _servicesList[0];
    _selectedStylist = b != null ? b['stylist'] : _stylistsList[0];
    _selectedPaymentStatus = b != null ? b['paymentStatus'] : _paymentStatuses[1]; // Partial default
    _selectedBookingStatus = b != null ? b['bookingStatus'] : _bookingStatuses[0]; // Pending default

    _dynamicSlots = List.from(_timeSlots);

    // Parse date and time if editing
    if (b != null) {
      final dateTimeStr = b['dateTime'] as String; // e.g. "May 30, 2026 • 10:30 AM"
      _selectedDate = DateTime(2026, 5, 30); // Mock default date
      
      // Attempt to extract timeslot
      final parts = dateTimeStr.split(' • ');
      if (parts.length > 1 && _timeSlots.contains(parts[1])) {
        _selectedTimeSlot = parts[1];
      } else {
        _selectedTimeSlot = _timeSlots[2]; // Default "10:30 AM"
      }
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1)); // Tomorrow
      _selectedTimeSlot = _timeSlots[2]; // 10:30 AM default
    }

    // Fetch dynamic slots
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailableSlots();
    });
  }

  String _formatSlotTime(String isoString) {
    try {
      // Stripping 'Z' offset makes parse treat it as a local date-time 
      // representing the exact salon-time hour (e.g. 09:00 AM)
      final stripped = isoString.replaceAll('Z', '');
      final dateTime = DateTime.parse(stripped);
      int hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      try {
        final tPart = isoString.split('T')[1];
        final hms = tPart.split(':');
        int hour = int.parse(hms[0]);
        final minute = hms[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '${hour.toString().padLeft(2, '0')}:$minute $period';
      } catch (e) {
        return '';
      }
    }
  }

  Future<void> _fetchAvailableSlots() async {
    if (widget.salonId == null) return;
    setState(() {
      _isLoadingSlots = true;
    });
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final res = await ApiService().getAvailableSlots(widget.salonId, dateStr);
      if (res['success'] == true) {
        final data = res['data'];
        List<dynamic> slotsList = [];
        if (data is Map && data['slots'] is List) {
          slotsList = data['slots'];
        } else if (data is List) {
          slotsList = data;
        }

        final List<String> fetchedSlots = [];
        for (var s in slotsList) {
          if (s is Map) {
            if (s['isAvailable'] == true && s['startTime'] != null) {
              final formattedTime = _formatSlotTime(s['startTime'].toString());
              if (formattedTime.isNotEmpty) {
                fetchedSlots.add(formattedTime);
              }
            }
          } else if (s is String) {
            fetchedSlots.add(s);
          }
        }

        setState(() {
          _dynamicSlots = fetchedSlots;
          _isLoadingSlots = false;
          if (_dynamicSlots.isNotEmpty) {
            if (!_dynamicSlots.contains(_selectedTimeSlot)) {
              _selectedTimeSlot = _dynamicSlots[0];
            }
          } else {
            _selectedTimeSlot = '';
          }
        });
      } else {
        setState(() {
          _dynamicSlots = List.from(_timeSlots); // fallback
          _isLoadingSlots = false;
        });
      }
    } catch (_) {
      setState(() {
        _dynamicSlots = List.from(_timeSlots); // fallback
        _isLoadingSlots = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentPurple,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAvailableSlots();
    }
  }

  String _formatDateString(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final dateFormatted = _formatDateString(_selectedDate);
        final fullDateTime = _selectedTimeSlot.isEmpty
            ? dateFormatted
            : '$dateFormatted • $_selectedTimeSlot';

        if (widget.booking != null) {
          final bookingId = widget.booking!['id'].toString();

          // Check if date or timeslot has changed
          final originalDateTime = widget.booking!['dateTime'] as String;
          final isDateTimeChanged = originalDateTime != fullDateTime;

          // Check if booking status has changed
          final originalStatus = widget.booking!['bookingStatus'] as String;
          final isStatusChanged = originalStatus != _selectedBookingStatus;

          if (isDateTimeChanged) {
            // Construct ISO 8601 string
            int hour = 0;
            int minute = 0;
            if (_selectedTimeSlot.isNotEmpty) {
              final timeParts = _selectedTimeSlot.split(' ');
              if (timeParts.length == 2) {
                final timeString = timeParts[0];
                final period = timeParts[1].toUpperCase();
                final hoursMinutes = timeString.split(':');
                if (hoursMinutes.length == 2) {
                  hour = int.tryParse(hoursMinutes[0]) ?? 0;
                  minute = int.tryParse(hoursMinutes[1]) ?? 0;
                  if (period == 'PM' && hour < 12) hour += 12;
                  if (period == 'AM' && hour == 12) hour = 0;
                }
              }
            }
            final newDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
            final isoString = newDateTime.toUtc().toIso8601String();

            final res = await ApiService().rescheduleBooking(bookingId, isoString);
            if (res['success'] != true) {
              throw Exception(res['error'] ?? 'Failed to reschedule booking.');
            }
          }

          if (isStatusChanged) {
            final res = await ApiService().updateBookingStatus(bookingId, _selectedBookingStatus.toUpperCase());
            if (res['success'] != true) {
              throw Exception(res['error'] ?? 'Failed to update booking status.');
            }
          }
        }

        // On success:
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _showSuccessAnimation = true;
        });

        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;

        final updatedData = {
          'id': widget.booking != null ? widget.booking!['id'] : 'BKG-${1000 + DateTime.now().second * 13}',
          'customerName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'service': _selectedService,
          'dateTime': fullDateTime,
          'paymentStatus': _selectedPaymentStatus,
          'bookingStatus': _selectedBookingStatus,
          'price': _priceController.text.trim(),
          'stylist': _selectedStylist,
        };

        widget.onSave(updatedData);
        Navigator.pop(context);

      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;

    if (_showSuccessAnimation) {
      return Container(
        height: 380,
        alignment: Alignment.center,
        color: Colors.white,
        child: const AnimatedCheckmark(),
      );
    }

    final header = Container(
      decoration: const BoxDecoration(
        color: AppColors.accentBlue,
      ),
      child: SafeArea(
        top: isMobile,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.booking == null ? 'Create Manual Booking' : 'Reschedule Appointment',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking == null ? 'Generate a new appointment slot' : 'Modify scheduling slot parameters',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );

    final formContent = Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildFormSectionHeader('Client Information'),
          const SizedBox(height: 12),
          
          _buildTextField(
            label: 'Customer Full Name *',
            controller: _nameController,
            placeholder: 'e.g. Sudhanshu Shekhar',
            enabled: widget.booking == null,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter Customer Name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Phone Contact *',
            controller: _phoneController,
            placeholder: 'e.g. +91 98765 43210',
            keyboardType: TextInputType.phone,
            enabled: widget.booking == null,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter Phone Contact';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          _buildFormSectionHeader('Appointment Particulars'),
          const SizedBox(height: 12),

          _buildFormDropdown(
            label: 'Select Service *',
            value: _selectedService,
            items: _servicesList,
            onChanged: widget.booking == null ? (val) => setState(() => _selectedService = val!) : null,
          ),
          const SizedBox(height: 16),

          _buildFormDropdown(
            label: 'Assigned Stylist *',
            value: _selectedStylist,
            items: _stylistsList,
            onChanged: widget.booking == null ? (val) => setState(() => _selectedStylist = val!) : null,
          ),
          const SizedBox(height: 16),

          // Date Picker & Time Slot row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Date *',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDateString(_selectedDate),
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.accentPurple, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoadingSlots
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Slot *',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildFormDropdown(
                        label: 'Time Slot *',
                        value: _selectedTimeSlot.isEmpty && _dynamicSlots.isNotEmpty ? _dynamicSlots[0] : _selectedTimeSlot,
                        items: _dynamicSlots.isNotEmpty ? _dynamicSlots : ['No Slots Available'],
                        onChanged: (val) {
                          if (val != 'No Slots Available' && val != null) {
                            setState(() => _selectedTimeSlot = val);
                          }
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Billing Cost (₹) *',
            controller: _priceController,
            placeholder: 'Price amount in ₹',
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: widget.booking == null,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter Cost Price';
              }
              final parsed = double.tryParse(val);
              if (parsed == null || parsed <= 0) {
                return 'Enter Valid Price';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          _buildFormSectionHeader('Status Settings'),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFormDropdown(
                  label: 'Payment status',
                  value: _selectedPaymentStatus,
                  items: _paymentStatuses,
                  onChanged: widget.booking == null ? (val) => setState(() => _selectedPaymentStatus = val!) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormDropdown(
                  label: 'Booking status',
                  value: _selectedBookingStatus,
                  items: _bookingStatuses,
                  onChanged: widget.booking == null ? (val) => setState(() => _selectedBookingStatus = val!) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildFooterActions(),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: isMobile 
          ? const BorderRadius.vertical(top: Radius.circular(24)) 
          : BorderRadius.circular(24),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            header,
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
                child: formContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          enabled: enabled,
          style: GoogleFonts.inter(
            color: enabled ? AppColors.textPrimary : AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.normal),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.inter(
              color: enabled ? AppColors.textPrimary : AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: enabled ? const Color(0xFFFAF9F6) : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    // Ensure the value exists in items to prevent Flutter assertion crashes
    final safeValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    final bool enabled = onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFFAF9F6) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              key: ValueKey('${label}_${safeValue}_${items.join(",")}'),
              initialValue: safeValue,
              isExpanded: true,
              onChanged: onChanged,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: enabled ? AppColors.textSecondary : AppColors.textLight),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: GoogleFonts.inter(
                color: enabled ? AppColors.textPrimary : AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    if (_isSaving) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
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

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.booking == null ? 'Generate Booking' : 'Confirm Save',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- SUB-WIDGET: ANIMATED SUCCESS CHECKMARK ---

class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({super.key});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 56,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Success!',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Appointment details successfully saved.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
