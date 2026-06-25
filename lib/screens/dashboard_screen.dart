import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_slide_transition.dart';
import 'dashboard/home_tab.dart';
import 'dashboard/bookings_tab.dart';
import 'dashboard/services_tab.dart';
import 'dashboard/earnings_tab.dart';
import 'dashboard/profile_tab.dart';
import 'dashboard/settings_tab.dart';
import 'dashboard/reviews_view.dart';
import 'dashboard/my_salon_view.dart';
import 'dashboard/home_service_view.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Navigation State
  // Indexes 0-4 correspond directly to bottom navigation tabs
  // Indexes 5+ correspond to drawer-only items
  int _currentIndex = 0;
  String _activeDrawerItem = 'Dashboard';

  // Profile & Salon Data state
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _salonDetail;
  List<Map<String, dynamic>> _mySalons = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  // Dashboard metrics state
  Map<String, dynamic>? _dashboardData;
  bool _isLoadingDashboard = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final profileResult = await ApiService().getProfile();
      if (profileResult['success'] != true) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = profileResult['error'] ?? 'Failed to load user profile';
        });
        return;
      }

      final profileData = profileResult['data'];

      final salonsResult = await ApiService().getMySalons();
      if (salonsResult['success'] != true) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = salonsResult['error'] ?? 'Failed to load salon details';
        });
        return;
      }

      final List<dynamic> salonsList = salonsResult['data'] ?? [];
      _mySalons = List<Map<String, dynamic>>.from(salonsList);
      
      Map<String, dynamic>? matchedSalon;
      if (_mySalons.isNotEmpty) {
        if (_salonDetail != null) {
          final int existingIdx = _mySalons.indexWhere((s) => s['id'] == _salonDetail?['id']);
          if (existingIdx != -1) {
            matchedSalon = _mySalons[existingIdx];
          }
        }
        matchedSalon ??= _mySalons.first;
      }

      setState(() {
        _userProfile = Map<String, dynamic>.from(profileData);
        _salonDetail = matchedSalon;
      });

      if (matchedSalon != null) {
        final res = await ApiService().getSalonDashboard(matchedSalon['id']);
        if (res['success'] == true) {
          _dashboardData = res['data'];
        }
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  Future<void> _loadDashboardDetailsForSalon(dynamic salonId) async {
    if (salonId == null) return;
    setState(() {
      _isLoadingDashboard = true;
    });
    try {
      final res = await ApiService().getSalonDashboard(salonId);
      if (mounted) {
        setState(() {
          if (res['success'] == true) {
            _dashboardData = res['data'];
          }
          _isLoadingDashboard = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDashboard = false;
        });
      }
    }
  }

  // Navigation items mapping
  final List<Map<String, dynamic>> _drawerItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_rounded, 'tabIndex': 0},
    {'title': 'Bookings', 'icon': Icons.calendar_today_rounded, 'tabIndex': 1},
    {'title': 'Home Service', 'icon': Icons.home_repair_service_rounded, 'tabIndex': 5},
    {'title': 'Services', 'icon': Icons.content_cut_rounded, 'tabIndex': 2},
    {'title': 'Employees', 'icon': Icons.badge_rounded, 'tabIndex': 6},
    {'title': 'Earnings', 'icon': Icons.payments_rounded, 'tabIndex': 3},
    {'title': 'Salon', 'icon': Icons.storefront_rounded, 'tabIndex': 9},
  ];

  void _navigateToTab(int index, String title) {
    setState(() {
      _currentIndex = index;
      _activeDrawerItem = title;
    });
    // Close drawer if open on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          onOpenDrawer: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          onManageBookingsTap: () => _navigateToTab(1, 'Bookings'),
          activeSalon: _salonDetail,
          salons: _mySalons,
          dashboardData: _dashboardData,
          isLoadingDashboard: _isLoadingDashboard,
          onSalonChanged: (salon) {
            setState(() {
              _salonDetail = salon;
              _dashboardData = null;
            });
            _loadDashboardDetailsForSalon(salon['id']);
          },
          onCreateSalonTap: () => _navigateToTab(9, 'Salon'),
        );
      case 1:
        return BookingsTab(salonDetail: _salonDetail);
      case 2:
        return ServicesTab(salonDetail: _salonDetail);
      case 3:
        return EarningsTab(salonDetail: _salonDetail);
      case 4:
        return ProfileTab(
          userProfile: _userProfile,
          salonDetail: _salonDetail,
          onSalonDetailsTap: () => _navigateToTab(9, 'Salon'),
        );
      case 5:
        return HomeServiceView(salonDetail: _salonDetail);
      case 6:
        return _buildEmployeesView();
      case 7:
        return ReviewsView(
          salonDetail: _salonDetail,
        );
      case 8:
        return _buildAnalyticsView();
      case 9:
        return MySalonView(
          salonDetail: _salonDetail,
          salons: _mySalons,
          onSalonUpdated: (updatedSalon) {
            setState(() {
              _salonDetail = updatedSalon;
            });
            _loadDashboardData();
          },
          onSalonAdded: (newSalon) {
            setState(() {
              _salonDetail = newSalon;
            });
            _loadDashboardData();
          },
        );
      case 10:
        return _buildSettingsView();
      default:
        return const Center(child: Text('Screen not found.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Partner Portal...',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Failed to Load Portal Data',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text(
                    'RETRY LOADING',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await ApiService().clearSession();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    // Persistent sidebar layout for desktop/tablet widths
    final bool isSidebarPersistent = screenWidth > 950;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAF9F6),
      drawer: isSidebarPersistent ? null : _buildSidebar(isPersistent: false),
      body: SafeArea(
        child: Row(
          children: [
            if (isSidebarPersistent) ...[
              _buildSidebar(isPersistent: true),
              Container(width: 1, color: AppColors.borderLight),
            ],
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _getBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    // Only highlight bottom bar tabs when the active index is 0-4
    final bool isTabActive = _currentIndex >= 0 && _currentIndex <= 4;
    final int selectedBottomIndex = isTabActive ? _currentIndex : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.accentPurple.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.accentPurple, size: 24);
            }
            return const IconThemeData(color: AppColors.textSecondary, size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedBottomIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          onDestinationSelected: (int index) {
            final titles = ['Dashboard', 'Bookings', 'Services', 'Earnings', 'Profile'];
            _navigateToTab(index, titles[index]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.content_cut_outlined),
              selectedIcon: Icon(Icons.content_cut_rounded),
              label: 'Services',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments_rounded),
              label: 'Earnings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool isPersistent}) {
    return Container(
      width: 270,
      height: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & Salon Title (Strictly NO Profile section/avatar inside sidebar as requested)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GlowDew Partner',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Salon Suite v3.2',
                      style: GoogleFonts.inter(
                        color: AppColors.textLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 24),
          
          // Navigation Drawer Items Scrollable
          Expanded(
            child: ListView.builder(
              itemCount: _drawerItems.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = _drawerItems[index];
                final bool isSelected = _activeDrawerItem == item['title'];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: InkWell(
                    onTap: () => _navigateToTab(item['tabIndex'], item['title']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.accentPurple.withValues(alpha: 0.08) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item['title'],
                            style: GoogleFonts.inter(
                              color: isSelected ? AppColors.accentPurple : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              '© 2026 GlowDew Partner Portal',
              style: GoogleFonts.inter(
                color: AppColors.textLight,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DRAWER SUB-SCREENS (MOCK MANAGEMENT BOARDS) ---



  Widget _buildEmployeesView() {
    // A beautiful responsive employees list
    final employees = [
      {'name': 'Alex Carter', 'role': 'Master Barber & Stylist', 'rating': '4.9 ★', 'status': 'Active'},
      {'name': 'Sarah Jenkins', 'role': 'Nail Artist & Esthetician', 'rating': '4.8 ★', 'status': 'Active'},
      {'name': 'Marcus Vance', 'role': 'Skin & Face Specialist', 'rating': '4.8 ★', 'status': 'Active'},
      {'name': 'Elena Rostova', 'role': 'Senior Color Specialist', 'rating': '4.7 ★', 'status': 'Away'},
    ];

    return _buildCustomSubView(
      title: 'Stylist & Employees',
      icon: Icons.badge_rounded,
      subtitle: 'Manage duty schedules, performance levels, and service assignments.',
      content: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Salon Roster', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: AppColors.accentPurple),
              label: Text('Invite Staff', style: GoogleFonts.inter(color: AppColors.accentPurple, fontSize: 12)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accentPurple)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...employees.map((emp) {
          final isActive = emp['status'] == 'Active';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accentPurple.withValues(alpha: 0.1),
                  child: Text(emp['name']!.split(' ').map((n) => n[0]).join(), style: GoogleFonts.outfit(color: AppColors.accentPurple, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(emp['role']!, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(emp['rating']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B), fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        emp['status']!,
                        style: GoogleFonts.inter(color: isActive ? const Color(0xFF10B981) : Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }



  Widget _buildAnalyticsView() {
    return _buildCustomSubView(
      title: 'Business Analytics',
      icon: Icons.analytics_rounded,
      subtitle: 'Monitor customer acquisition speed, retention indices, and busiest shifts.',
      content: [
        Row(
          children: [
            Expanded(child: _buildSimpleStat('84.2%', 'Customer Retention')),
            const SizedBox(width: 12),
            Expanded(child: _buildSimpleStat('₹2,450', 'Average Ticket Size')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSimpleStat('45 min', 'Avg Session Duration')),
            const SizedBox(width: 12),
            Expanded(child: _buildSimpleStat('12:00 - 15:00', 'Busiest Hours')),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Retention Trend', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Customers', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                  Text('+32 this week', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.76,
                backgroundColor: AppColors.borderLight,
                color: AppColors.accentPurple,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsView() {
    return const SettingsTab();
  }

  // --- REUSABLE UTILS FOR MOCK SUB-VIEWS ---

  Widget _buildCustomSubView({
    required String title,
    required IconData icon,
    required String subtitle,
    required List<Widget> content,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => _navigateToTab(0, 'Dashboard'),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: FadeSlideTransition(
            delay: const Duration(milliseconds: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppColors.accentPurple, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                ...content,
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSimpleStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
