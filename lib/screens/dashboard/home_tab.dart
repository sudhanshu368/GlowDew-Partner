import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/fade_slide_transition.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onManageBookingsTap;
  final Map<String, dynamic>? activeSalon;
  final List<Map<String, dynamic>> salons;
  final Map<String, dynamic>? dashboardData;
  final bool isLoadingDashboard;
  final Function(Map<String, dynamic>) onSalonChanged;
  final VoidCallback onCreateSalonTap;

  const HomeTab({
    super.key,
    required this.onOpenDrawer,
    required this.onManageBookingsTap,
    this.activeSalon,
    required this.salons,
    this.dashboardData,
    required this.isLoadingDashboard,
    required this.onSalonChanged,
    required this.onCreateSalonTap,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showEmptyScheduleState = false;

  void _showSalonSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Switch Salon',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.salons.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No salons registered yet.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.salons.length,
                    itemBuilder: (context, index) {
                      final s = widget.salons[index];
                      final isSelected = s['id'] == widget.activeSalon?['id'];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppColors.accentPurple.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          child: Icon(
                            Icons.storefront_rounded,
                            color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          s['name'] ?? 'Salon Name',
                          style: GoogleFonts.inter(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          s['city'] ?? s['address'] ?? '',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.accentPurple)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSalonChanged(s);
                        },
                      );
                    },
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCreateSalonTap();
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentPurple),
                    label: Text(
                      'Add New Salon',
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  List<Map<String, String>> get _recentScheduleList {
    final List<dynamic> bookingsList = widget.dashboardData?['recentBookings'] ?? [];
    return bookingsList.map<Map<String, String>>((b) {
      final customerName = b['customerName'] ?? b['customer']?['name'] ?? b['client']?['name'] ?? b['clientName'] ?? 'Unknown Client';
      
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
      }

      if (categoryName == 'General' && serviceName.toLowerCase() == 'hair') {
        categoryName = 'Hair';
      }
      
      // Format time
      final timeFormatted = _formatDateTime(
        b['startTime'] ?? b['bookingDate'] ?? b['date'],
        b['time'] ?? b['bookingTime'],
        b['startTime'] ?? b['bookingDate'] ?? b['dateTime'] ?? b['createdAt']
      );

      final priceVal = b['grandTotal']?.toString() ?? b['finalBill']?.toString() ?? b['totalPrice']?.toString() ?? b['totalAmount']?.toString() ?? b['price']?.toString() ?? b['amount']?.toString() ?? '0';
      final statusVal = b['bookingStatus'] ?? b['status'] ?? 'Pending';

      return {
        'client': customerName,
        'service': serviceName,
        'time': timeFormatted,
        'price': '₹$priceVal',
        'status': statusVal[0] + statusVal.substring(1).toLowerCase(),
        'category': categoryName,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 750;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Matches theme background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Sticky App Bar Header with merged search field in bottom
            SliverAppBar(
              floating: false,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: const Color(0xFFFAF9F6),
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              toolbarHeight: 68,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Hamburger Menu Icon
                        IconButton(
                          icon: const Icon(Icons.notes_rounded, color: AppColors.textPrimary, size: 28),
                          onPressed: widget.onOpenDrawer,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showSalonSwitcher(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.activeSalon?['name'] ?? 'Select Salon',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentPurple, size: 18),
                                ],
                              ),
                              Text(
                                'Partner Hub',
                                style: GoogleFonts.inter(
                                  color: AppColors.accentPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Notification Icon with Badge
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderLight.withValues(alpha: 0.8),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Notifications are up to date.', style: GoogleFonts.inter()),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(66),
                child: Container(
                  color: const Color(0xFFFAF9F6),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search bookings, customers, services...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.accentPurple, size: 20),
                          onPressed: () {},
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.borderLight.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.borderLight.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.accentPurple,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Main Dashboard Content List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  widget.isLoadingDashboard || widget.dashboardData == null
                      ? [
                          const SizedBox(height: 100),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 48.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                              ),
                            ),
                          ),
                        ]
                      : [
                          // A. Welcome Banner Card
                          _buildWelcomeBanner(isTablet),
                          
                          const SizedBox(height: 24),

                          // B. Statistics Section Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Performance Metrics',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Live',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),

                          // C. Responsive Grid Layout of Stats
                          _buildStatsGrid(screenWidth),

                          const SizedBox(height: 32),

                          // D. Today's Schedule Section Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Today's Schedule",
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Premium Interactive Toggle for reviewing Empty State
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showEmptyScheduleState = !_showEmptyScheduleState;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentPurple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _showEmptyScheduleState ? 'Show Loaded' : 'Show Empty',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: AppColors.accentPurple,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: widget.onManageBookingsTap,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View All',
                                      style: GoogleFonts.inter(
                                        color: AppColors.accentPurple,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.accentPurple, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 14),

                          // E. Dynamic Schedule List/Empty State
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _showEmptyScheduleState 
                                ? _buildEmptyState() 
                                : _buildScheduleList(),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isTablet) {
    final bookingsByStatus = widget.dashboardData?['stats']?['bookingsByStatus'] as Map? ?? {};
    int totalBookings = 0;
    bookingsByStatus.forEach((key, val) {
      if (val is num) totalBookings += val.toInt();
    });

    final pendingBookings = bookingsByStatus['PENDING'] ?? bookingsByStatus['Pending'] ?? 0;
    
    final List<dynamic> bookingsList = widget.dashboardData?['recentBookings'] ?? [];
    final uniqueCustomers = bookingsList.map((b) => b['customerId'] ?? b['customer']?['id']).where((id) => id != null).toSet().length;
    final scheduledCount = uniqueCustomers > 0 ? uniqueCustomers : totalBookings;

    return FadeSlideTransition(
      delay: const Duration(milliseconds: 100),
      child: Container(
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
                right: -50,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentBlue.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentBlue.withValues(alpha: 0.02),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.0 : 22.0, 
                  vertical: isTablet ? 36.0 : 26.0
                ),
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
                        'BUSINESS INSIGHTS',
                        style: GoogleFonts.inter(
                          color: AppColors.accentBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back, Team!',
                      style: GoogleFonts.outfit(
                        color: AppColors.accentBlue,
                        fontSize: isTablet ? 26 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your salon has $pendingBookings pending bookings and $scheduledCount customers scheduled for today. Make it a wonderful session!',
                      style: GoogleFonts.inter(
                        color: AppColors.accentBlue.withValues(alpha: 0.8),
                        fontSize: isTablet ? 14 : 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: widget.onManageBookingsTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Manage Bookings',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
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

  Widget _buildStatsGrid(double screenWidth) {
    int crossAxisCount = 2;
    if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 550) {
      crossAxisCount = 3;
    }

    final bookingsByStatus = widget.dashboardData?['stats']?['bookingsByStatus'] as Map? ?? {};
    int totalBookings = 0;
    bookingsByStatus.forEach((key, val) {
      if (val is num) totalBookings += val.toInt();
    });

    final pendingBookings = bookingsByStatus['PENDING'] ?? bookingsByStatus['Pending'] ?? 0;
    final completedBookings = bookingsByStatus['COMPLETED'] ?? bookingsByStatus['Completed'] ?? 0;
    final activeServices = widget.dashboardData?['stats']?['activeServices'] ?? 0;
    final visibleReviews = widget.dashboardData?['stats']?['visibleReviews'] ?? 0;
    final totalEarnings = (widget.dashboardData?['earnings']?['totalEarnings'] as num? ?? 0).toDouble();

    final stats = [
      {
        'title': "Total Bookings",
        'value': '$totalBookings',
        'icon': Icons.calendar_today_rounded,
        'iconColor': AppColors.accentPurple,
        'iconBgColor': AppColors.accentPurple.withValues(alpha: 0.1),
        'trendText': 'Live',
        'isTrendPositive': true,
      },
      {
        'title': 'Total Earnings',
        'value': '₹${totalEarnings.toStringAsFixed(0)}',
        'icon': Icons.currency_rupee_rounded,
        'iconColor': const Color(0xFF10B981),
        'iconBgColor': const Color(0xFF10B981).withValues(alpha: 0.1),
        'trendText': 'Earnings',
        'isTrendPositive': true,
      },
      {
        'title': 'Active Services',
        'value': '$activeServices',
        'icon': Icons.content_cut_rounded,
        'iconColor': const Color(0xFF3B82F6),
        'iconBgColor': const Color(0xFF3B82F6).withValues(alpha: 0.1),
        'trendText': 'Services',
        'isTrendPositive': true,
      },
      {
        'title': 'Pending Bookings',
        'value': '$pendingBookings',
        'icon': Icons.hourglass_empty_rounded,
        'iconColor': const Color(0xFFF59E0B),
        'iconBgColor': const Color(0xFFF59E0B).withValues(alpha: 0.1),
        'trendText': 'Attention',
        'isTrendPositive': false,
      },
      {
        'title': 'Completed Slots',
        'value': '$completedBookings',
        'icon': Icons.task_alt_rounded,
        'iconColor': const Color(0xFF10B981),
        'iconBgColor': const Color(0xFF10B981).withValues(alpha: 0.1),
        'trendText': 'Done',
        'isTrendPositive': true,
      },
      {
        'title': "Reviews Count",
        'value': '$visibleReviews',
        'icon': Icons.star_border_rounded,
        'iconColor': const Color(0xFFF59E0B),
        'iconBgColor': const Color(0xFFF59E0B).withValues(alpha: 0.1),
        'trendText': 'Reviews',
        'isTrendPositive': true,
      },
    ];

    double childAspectRatio = 1.35;
    if (screenWidth < 340) {
      childAspectRatio = 0.85;
    } else if (screenWidth < 380) {
      childAspectRatio = 1.0;
    } else if (screenWidth < 450) {
      childAspectRatio = 1.15;
    } else if (screenWidth < 550) {
      childAspectRatio = 1.3;
    } else if (screenWidth < 700) {
      childAspectRatio = 1.15; // 3 columns
    } else if (screenWidth < 900) {
      childAspectRatio = 1.35; // 3 columns
    } else {
      childAspectRatio = 1.45; // 4 columns
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return FadeSlideTransition(
              delay: Duration(milliseconds: 150 + (index * 40)),
              child: StatCard(
                title: stat['title'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                iconColor: stat['iconColor'] as Color,
                iconBgColor: stat['iconBgColor'] as Color,
                trendText: stat['trendText'] as String?,
                isTrendPositive: stat['isTrendPositive'] as bool,
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleList() {
    final list = _recentScheduleList;
    if (list.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      key: const ValueKey('schedule_list'),
      children: List.generate(list.length, (index) {
        final booking = list[index];
        return FadeSlideTransition(
          delay: Duration(milliseconds: 200 + (index * 60)),
          child: ScheduleCard(
            clientName: booking['client']!,
            serviceName: booking['service']!,
            time: booking['time']!,
            price: booking['price']!,
            status: booking['status']!,
            categoryName: booking['category']!,
            onTap: () {},
            onStatusTap: () {},
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: const ValueKey('empty_state'),
      child: FadeSlideTransition(
        delay: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium empty state design
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: AppColors.accentPurple,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Bookings Scheduled',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'There are no customer appointments scheduled for today. Bookings will show up here as soon as they are made.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onManageBookingsTap,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accentPurple),
                label: Text(
                  'Book Appointment',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.accentPurple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
