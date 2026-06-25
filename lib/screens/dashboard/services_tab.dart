import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../services/api_service.dart';
import '../../models/service_category.dart';

String _cleanBase64(String base64Str) {
  return base64Str
      .replaceAll('&#x2F;', '/')
      .replaceAll('&#x3D;', '=')
      .replaceAll('&#x2B;', '+')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

class ServicesTab extends StatefulWidget {
  final Map<String, dynamic>? salonDetail;
  const ServicesTab({super.key, this.salonDetail});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  List<Map<String, dynamic>> _services = [];
  List<ServiceCategory> _dynamicCategories = [];
  bool _isLoading = true;
  String? _error;
  dynamic _salonId;

  @override
  void initState() {
    super.initState();
    _loadSalonAndServices();
  }

  @override
  void didUpdateWidget(covariant ServicesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.salonDetail?['id'] != oldWidget.salonDetail?['id']) {
      _loadSalonAndServices();
    }
  }

  Future<void> _loadSalonAndServices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _fetchCategories();
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
      await _fetchServices();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchServices() async {
    if (_salonId == null) return;
    try {
      final res = await ApiService().getSalonServices(_salonId);
      if (!mounted) return;
      if (res['success'] == true && res['data'] is List) {
        final List<dynamic> serviceList = res['data'];
        setState(() {
          _services = serviceList.map((s) => _mapBackendServiceToUI(s)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['error'] ?? 'Failed to fetch services';
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

  Map<String, dynamic> _mapBackendServiceToUI(dynamic service) {
    return {
      'id': service['id']?.toString() ?? '',
      'name': service['name'] ?? '',
      'category': service['category'] ?? 'Other',
      'duration': service['duration'] is int ? service['duration'] : (int.tryParse(service['duration']?.toString() ?? '') ?? 30),
      'price': (service['price'] as num?)?.toDouble() ?? 0.0,
      'isActive': service['isActive'] ?? true,
      'isHomeService': service['isHomeServiceAvailable'] ?? false,
      'homePrice': (service['homeServicePrice'] as num?)?.toDouble(),
      'description': service['description'] ?? '',
      'imagePath': service['image'],
      'xFile': null,
      'isFeatured': service['isFeatured'] ?? false,
      'isPopular': service['isPopular'] ?? false,
    };
  }


  Future<void> _toggleServiceStatus(Map<String, dynamic> service, bool newStatus) async {
    if (_salonId == null) return;
    
    // Optimistic UI update
    final originalStatus = service['isActive'];
    setState(() {
      service['isActive'] = newStatus;
    });

    final res = newStatus
        ? await ApiService().activateService(service['id'])
        : await ApiService().deactivateService(service['id']);

    if (!mounted) return;
    if (res['success'] == true) {
      _showToast('${service['name']} is now ${newStatus ? 'Active' : 'Inactive'}');
    } else {
      // Revert status on failure
      setState(() {
        service['isActive'] = originalStatus;
      });
      _showToast('Failed to update status: ${res['error']}', isSuccess: false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService().fetchServiceCategories();
      if (res['success'] == true && res['data'] is List) {
        final List<dynamic> catList = res['data'];
        _dynamicCategories = catList.map((c) => ServiceCategory.fromJson(c)).toList();
      } else {
        _loadDefaultCategories();
      }
    } catch (_) {
      _loadDefaultCategories();
    }
  }

  void _loadDefaultCategories() {
    _dynamicCategories = [
      ServiceCategory(id: 'hair', name: 'Hair Services', icon: 'scissors'),
      ServiceCategory(id: 'grooming', name: 'Grooming', icon: 'razor'),
      ServiceCategory(id: 'spa', name: 'Spa & Wellness', icon: 'droplet'),
      ServiceCategory(id: 'nail', name: 'Nail Services', icon: 'nail'),
      ServiceCategory(id: 'makeup', name: 'Makeup', icon: 'palette'),
      ServiceCategory(id: 'massage', name: 'Massage Therapy', icon: 'hand'),
      ServiceCategory(id: 'facial', name: 'Facial Treatments', icon: 'sparkles'),
      // Legacy compatibility
      ServiceCategory(id: 'beard', name: 'Beard Grooming', icon: 'razor'),
      ServiceCategory(id: 'hair color', name: 'Hair Color', icon: 'palette'),
      ServiceCategory(id: 'skin care', name: 'Skin Care', icon: 'sparkles'),
      ServiceCategory(id: 'bridal', name: 'Bridal Makeup', icon: 'sparkles'),
      ServiceCategory(id: 'nail care', name: 'Nail Care', icon: 'nail'),
      ServiceCategory(id: 'other', name: 'Other Services', icon: 'bubble'),
    ];
  }

  String _getCategoryDisplayName(String categoryVal) {
    if (_dynamicCategories.isEmpty) {
      _loadDefaultCategories();
    }
    final match = _dynamicCategories.firstWhere(
      (c) => c.id.toLowerCase() == categoryVal.toLowerCase() || c.name.toLowerCase() == categoryVal.toLowerCase(),
      orElse: () => ServiceCategory(id: categoryVal, name: categoryVal, icon: ''),
    );
    return match.name;
  }

  List<String> get _categoriesList {
    if (_dynamicCategories.isEmpty) {
      _loadDefaultCategories();
    }
    return _dynamicCategories.map((c) => c.name).toList();
  }

  // Filters State
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _sortBy = 'Name';

  // Pagination State
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Calculation helpers for Statistics Cards
  int get _totalServices => _services.length;

  double get _averagePrice {
    if (_services.isEmpty) return 0;
    double sum = _services.fold(0, (prev, element) => prev + (element['price'] as double));
    return sum / _services.length;
  }

  double get _averageDuration {
    if (_services.isEmpty) return 0;
    int sum = _services.fold(0, (prev, element) => prev + (element['duration'] as int));
    return sum / _services.length;
  }

  int get _uniqueCategoriesCount {
    return _services.map((s) => s['category'] as String).toSet().length;
  }

  // Filter & Sort Logic
  List<Map<String, dynamic>> get _filteredAndSortedServices {
    List<Map<String, dynamic>> result = List.from(_services);

    // Search query matching
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((service) {
        final name = (service['name'] as String).toLowerCase();
        final desc = (service['description'] as String? ?? '').toLowerCase();
        final cat = (service['category'] as String).toLowerCase();
        return name.contains(query) || desc.contains(query) || cat.contains(query);
      }).toList();
    }

    // Category Filter
    if (_selectedCategoryFilter != 'All') {
      result = result.where((service) {
        final serviceCat = service['category'] as String;
        if (_dynamicCategories.isEmpty) {
          _loadDefaultCategories();
        }
        final match = _dynamicCategories.firstWhere(
          (c) => c.id.toLowerCase() == _selectedCategoryFilter.toLowerCase() || 
                 c.name.toLowerCase() == _selectedCategoryFilter.toLowerCase(),
          orElse: () => ServiceCategory(id: '', name: '', icon: ''),
        );
        return serviceCat.toLowerCase() == match.id.toLowerCase() || 
               serviceCat.toLowerCase() == match.name.toLowerCase();
      }).toList();
    }

    // Status Filter
    if (_selectedStatusFilter != 'All') {
      final bool targetActive = _selectedStatusFilter == 'Active';
      result = result.where((service) => service['isActive'] == targetActive).toList();
    }

    // Sorting
    if (_sortBy == 'Name') {
      result.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
    } else if (_sortBy == 'Price: Low to High') {
      result.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortBy == 'Price: High to Low') {
      result.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
    } else if (_sortBy == 'Duration') {
      result.sort((a, b) => (a['duration'] as int).compareTo(b['duration'] as int));
    }

    return result;
  }

  // Paginated List
  List<Map<String, dynamic>> _getPagedServices(List<Map<String, dynamic>> filteredList) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= filteredList.length) {
      return [];
    }
    final endIndex = startIndex + _itemsPerPage;
    return filteredList.sublist(
      startIndex,
      endIndex > filteredList.length ? filteredList.length : endIndex,
    );
  }

  // Category Icons lookup
  IconData _getCategoryIcon(String categoryVal) {
    if (_dynamicCategories.isEmpty) {
      _loadDefaultCategories();
    }
    final match = _dynamicCategories.firstWhere(
      (c) => c.id.toLowerCase() == categoryVal.toLowerCase() || c.name.toLowerCase() == categoryVal.toLowerCase(),
      orElse: () => ServiceCategory(id: '', name: '', icon: ''),
    );
    
    final iconName = match.icon.toLowerCase();
    final id = match.id.toLowerCase();
    
    if (iconName == 'scissors' || id.contains('hair')) {
      return Icons.content_cut_rounded;
    } else if (iconName == 'razor' || id.contains('beard') || id.contains('grooming')) {
      return Icons.face_retouching_natural_rounded;
    } else if (iconName == 'droplet' || id.contains('spa')) {
      return Icons.spa_rounded;
    } else if (iconName == 'nail') {
      return Icons.palette_outlined;
    } else if (iconName == 'palette' || id.contains('makeup') || id.contains('color')) {
      return Icons.brush_rounded;
    } else if (iconName == 'hand' || id.contains('massage')) {
      return Icons.spa_outlined;
    } else if (iconName == 'sparkles' || id.contains('facial') || id.contains('skin') || id.contains('bridal')) {
      return Icons.face_rounded;
    }
    return Icons.bubble_chart_rounded;
  }

  // Category Colors badge (soft pastel background)
  Color _getCategoryColor(String categoryVal) {
    final id = categoryVal.toLowerCase();
    if (id.contains('hair') && !id.contains('color')) {
      return const Color(0xFFEFF6FF); // Light Blue
    } else if (id.contains('beard') || id.contains('grooming')) {
      return const Color(0xFFF0FDF4); // Light Green
    } else if (id.contains('facial') || id.contains('skin') || id.contains('spa')) {
      return const Color(0xFFFDF2F8); // Light Pink
    } else if (id.contains('makeup') || id.contains('bridal')) {
      return const Color(0xFFFAF5FF); // Light Purple
    } else if (id.contains('massage')) {
      return const Color(0xFFECFDF5); // Light Emerald
    } else if (id.contains('color')) {
      return const Color(0xFFFFF7ED); // Light Orange
    } else if (id.contains('nail')) {
      return const Color(0xFFF5F3FF); // Light Violet
    }
    return const Color(0xFFF9FAFB); // Gray
  }

  // Category text colors matching the badge
  Color _getCategoryTextColor(String categoryVal) {
    final id = categoryVal.toLowerCase();
    if (id.contains('hair') && !id.contains('color')) {
      return const Color(0xFF1D4ED8);
    } else if (id.contains('beard') || id.contains('grooming')) {
      return const Color(0xFF15803D);
    } else if (id.contains('facial') || id.contains('skin') || id.contains('spa')) {
      return const Color(0xFFBE185D);
    } else if (id.contains('makeup') || id.contains('bridal')) {
      return const Color(0xFF7E22CE);
    } else if (id.contains('massage')) {
      return const Color(0xFF047857);
    } else if (id.contains('color')) {
      return const Color(0xFFC2410C);
    } else if (id.contains('nail')) {
      return const Color(0xFF6D28D9);
    }
    return const Color(0xFF374151);
  }

  Widget _buildServiceImage({
    required String? imagePath,
    required XFile? xFile,
    required double width,
    required double height,
    required IconData fallbackIcon,
    double borderRadius = 8,
    double? fallbackHeight,
    String? fallbackLabel,
  }) {
    Widget img;
    if (xFile != null) {
      img = kIsWeb
          ? Image.network(xFile.path, width: width, height: height, fit: BoxFit.cover)
          : Image.file(File(xFile.path), width: width, height: height, fit: BoxFit.cover);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        img = Image.network(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackContainer(width, fallbackHeight ?? height, fallbackIcon, borderRadius, fallbackLabel),
        );
      } else if (imagePath.startsWith('data:image') || imagePath.contains('base64')) {
        try {
          final cleanPath = _cleanBase64(imagePath);
          final base64Content = cleanPath.split(',').last;
          final bytes = base64Decode(base64Content);
          img = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackContainer(width, fallbackHeight ?? height, fallbackIcon, borderRadius, fallbackLabel),
          );
        } catch (e) {
          img = _buildFallbackContainer(width, fallbackHeight ?? height, fallbackIcon, borderRadius, fallbackLabel);
        }
      } else {
        img = Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackContainer(width, fallbackHeight ?? height, fallbackIcon, borderRadius, fallbackLabel),
        );
      }
    } else {
      return _buildFallbackContainer(width, fallbackHeight ?? height, fallbackIcon, borderRadius, fallbackLabel);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: img,
    );
  }

  Widget _buildFallbackContainer(double width, double height, IconData icon, double borderRadius, String? label) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accentPurple, size: height > 80 ? 28 : 20),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAndSortedServices;
    final pagedList = _getPagedServices(filteredList);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
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
                            'Failed to Load Services',
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
                            onPressed: _loadSalonAndServices,
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

                          // Table or Card List Section
                          if (filteredList.isEmpty)
                            _buildEmptyStateView()
                          else ...[
                            // Desktop/Tablet layout uses custom Table structure, Mobile uses custom Cards
                            if (screenWidth > 750)
                              Column(
                                children: [
                                  _buildTableHeader(),
                                  const SizedBox(height: 4),
                                  ...List.generate(pagedList.length, (index) {
                                    final service = pagedList[index];
                                    return _buildTableRow(service, index);
                                  }),
                                ],
                              )
                            else
                              Column(
                                children: List.generate(pagedList.length, (index) {
                                  final service = pagedList[index];
                                  return _buildMobileCard(service);
                                }),
                              ),
                            
                            const SizedBox(height: 12),
                            // Pagination controls
                            _buildPaginationFooter(filteredList.length),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(double screenWidth) {
    final isMobile = screenWidth < 600;

    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Management',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage all services offered at your salon',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final addServiceBtn = Container(
      decoration: BoxDecoration(
        color: AppColors.accentPurple,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEditServiceModal(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Service',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleSection,
          const SizedBox(height: 16),
          addServiceBtn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        titleSection,
        addServiceBtn,
      ],
    );
  }

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
          title: 'Total Services',
          value: '$_totalServices',
          icon: Icons.list_alt_rounded,
          bgColor: const Color(0xFFF3E8FF), // Soft purple
          iconColor: const Color(0xFF7E22CE),
        ),
        _buildStatCard(
          title: 'Average Price',
          value: '₹${_averagePrice.toStringAsFixed(0)}',
          icon: Icons.payments_rounded,
          bgColor: const Color(0xFFD1FAE5), // Soft green
          iconColor: const Color(0xFF047857),
        ),
        _buildStatCard(
          title: 'Average Duration',
          value: '${_averageDuration.toStringAsFixed(0)} min',
          icon: Icons.access_time_filled_rounded,
          bgColor: const Color(0xFFDBEAFE), // Soft blue
          iconColor: const Color(0xFF1D4ED8),
        ),
        _buildStatCard(
          title: 'Categories',
          value: '$_uniqueCategoriesCount',
          icon: Icons.category_rounded,
          bgColor: const Color(0xFFFEF3C7), // Soft gold
          iconColor: const Color(0xFFB45309),
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
              // Icon Circle Background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Text Content
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
            _currentPage = 1;
          });
        },
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search service name, description...',
          hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

    final categoryDropdown = _buildDropdownFilter(
      value: _selectedCategoryFilter,
      items: ['All', ..._categoriesList],
      onChanged: (val) {
        setState(() {
          _selectedCategoryFilter = val!;
          _currentPage = 1;
        });
      },
      icon: Icons.filter_list_rounded,
      hint: 'Category',
    );

    final statusDropdown = _buildDropdownFilter(
      value: _selectedStatusFilter,
      items: ['All', 'Active', 'Inactive'],
      onChanged: (val) {
        setState(() {
          _selectedStatusFilter = val!;
          _currentPage = 1;
        });
      },
      icon: Icons.toggle_on_rounded,
      hint: 'Status',
    );

    final sortDropdown = _buildDropdownFilter(
      value: _sortBy,
      items: ['Name', 'Price: Low to High', 'Price: High to Low', 'Duration'],
      onChanged: (val) {
        setState(() {
          _sortBy = val!;
        });
      },
      icon: Icons.sort_rounded,
      hint: 'Sort By',
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: categoryDropdown),
              const SizedBox(width: 8),
              Expanded(child: statusDropdown),
            ],
          ),
          const SizedBox(height: 8),
          sortDropdown,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: categoryDropdown),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: statusDropdown),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: sortDropdown),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
          isExpanded: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, color: AppColors.accentPurple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

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
            flex: 3,
            child: Text('Service Name', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Duration', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Price', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Home Service', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> service, int index) {
    final name = service['name'] as String;
    final category = service['category'] as String;
    final duration = service['duration'] as int;
    final price = service['price'] as double;
    final isHome = service['isHomeService'] as bool;
    final isActive = service['isActive'] as bool;
    final XFile? xFile = service['xFile'] as XFile?;
    final String? imagePath = service['imagePath'] as String?;

    final leadImage = _buildServiceImage(
      imagePath: imagePath,
      xFile: xFile,
      width: 36,
      height: 36,
      fallbackIcon: _getCategoryIcon(category),
      borderRadius: 8,
    );

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
          // Service Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                leadImage,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (service['isFeatured'] == true || service['isPopular'] == true) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (service['isFeatured'] == true)
                              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 12),
                            if (service['isFeatured'] == true && service['isPopular'] == true)
                              const SizedBox(width: 4),
                            if (service['isPopular'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                child: Text('POPULAR', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 7, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getCategoryDisplayName(category),
                    style: GoogleFonts.inter(
                      color: _getCategoryTextColor(category),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Duration
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.textLight, size: 14),
                const SizedBox(width: 6),
                Text(
                  '$duration min',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Price
          Expanded(
            flex: 2,
            child: Text(
              '₹${price.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),

          // Home Service Chip
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHome ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHome ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isHome ? const Color(0xFF137333) : const Color(0xFF5F6368),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isHome ? 'Available' : 'Salon Only',
                        style: GoogleFonts.inter(
                          color: isHome ? const Color(0xFF137333) : const Color(0xFF5F6368),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Switch
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Switch(
                  value: isActive,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => _toggleServiceStatus(service, val),
                ),
              ],
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(Icons.visibility_outlined, Colors.blue, 'View Details', () => _showServiceDetails(service)),
                const SizedBox(width: 4),
                _buildActionButton(Icons.edit_outlined, Colors.orange, 'Edit', () => _showAddEditServiceModal(service: service)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> service) {
    final name = service['name'] as String;
    final category = service['category'] as String;
    final duration = service['duration'] as int;
    final price = service['price'] as double;
    final isHome = service['isHomeService'] as bool;
    final isActive = service['isActive'] as bool;
    final XFile? xFile = service['xFile'] as XFile?;
    final String? imagePath = service['imagePath'] as String?;

    final leadImage = _buildServiceImage(
      imagePath: imagePath,
      xFile: xFile,
      width: 48,
      height: 48,
      fallbackIcon: _getCategoryIcon(category),
      borderRadius: 12,
    );

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
          // Row for Image, Name, and Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leadImage,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getCategoryDisplayName(category),
                              style: GoogleFonts.inter(
                                color: _getCategoryTextColor(category),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badges (Featured/Popular)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (service['isFeatured'] == true) ...[
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                                child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 10),
                              ),
                            ],
                            if (service['isPopular'] == true) ...[
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                                child: Text('POPULAR', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 7, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          if (service['description'] != null && (service['description'] as String).isNotEmpty) ...[
            Text(
              service['description'],
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Technical fields: Price, Duration, Home Service
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('₹${price.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Duration', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$duration min', 
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Home Service', style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHome ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHome ? 'Available' : 'N/A',
                        style: GoogleFonts.inter(
                          color: isHome ? const Color(0xFF137333) : const Color(0xFF5F6368),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Status & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.inter(
                          color: isActive ? const Color(0xFF10B981) : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: isActive,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                        onChanged: (val) => _toggleServiceStatus(service, val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, color: Colors.blue, size: 20),
                    onPressed: () => _showServiceDetails(service),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                    onPressed: () => _showAddEditServiceModal(service: service),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(int totalFilteredItems) {
    final totalPages = (totalFilteredItems / _itemsPerPage).ceil();
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;
    final startItem = totalFilteredItems == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage) > totalFilteredItems ? totalFilteredItems : (_currentPage * _itemsPerPage);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Showing $startItem-$endItem of $totalFilteredItems',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Page $_currentPage of $displayTotalPages',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/services.png',
                width: 140,
                height: 140,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: AppColors.accentPurple, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No services yet. Add your first service!',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Create a professional catalog of services to show in your shop list.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddEditServiceModal(),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
              label: Text('Add New Service', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTIONS & DIALOG HANDLERS ---

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

  void _confirmDeleteService(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Service', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          content: Text('Are you sure you want to delete "${service['name']}"? This action cannot be undone.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (_salonId == null) {
                  _showToast('Cannot delete service: Salon ID is missing', isSuccess: false);
                  return;
                }

                _showToast('Deleting "${service['name']}"...');
                final res = await ApiService().deleteSalonService(_salonId, service['id']);
                
                if (!mounted) return;
                if (res['success'] == true) {
                  setState(() {
                    _services.removeWhere((element) => element['id'] == service['id']);
                    final totalFiltered = _filteredAndSortedServices.length;
                    final maxPages = (totalFiltered / _itemsPerPage).ceil();
                    if (_currentPage > maxPages && _currentPage > 1) {
                      _currentPage = maxPages;
                    }
                  });
                  _showToast('"${service['name']}" deleted successfully');
                } else {
                  _showToast('Failed to delete service: ${res['error']}', isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showServiceDetails(Map<String, dynamic> service) {
    final name = service['name'] as String;
    final category = service['category'] as String;
    final duration = service['duration'] as int;
    final price = service['price'] as double;
    final isHome = service['isHomeService'] as bool;
    final homePrice = service['homePrice'] as double?;
    final isActive = service['isActive'] as bool;
    final isFeatured = service['isFeatured'] as bool;
    final isPopular = service['isPopular'] as bool;
    final description = service['description'] as String? ?? 'No description provided.';
    final XFile? xFile = service['xFile'] as XFile?;
    final String? imagePath = service['imagePath'] as String?;

    final detailImage = _buildServiceImage(
      imagePath: imagePath,
      xFile: xFile,
      width: double.infinity,
      height: 160,
      fallbackIcon: _getCategoryIcon(category),
      borderRadius: 16,
      fallbackHeight: 80,
      fallbackLabel: category,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getCategoryDisplayName(category),
                          style: GoogleFonts.inter(
                            color: _getCategoryTextColor(category),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: AppColors.accentPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? const Color(0xFF10B981).withValues(alpha: 0.1) 
                              : Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.inter(
                            color: isActive ? const Color(0xFF10B981) : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  
                  // Detail Image
                  detailImage,
                  const SizedBox(height: 20),

                  Text(
                    'Details',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time_rounded, 'Duration', '$duration minutes'),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.home_rounded, 
                    'Home Service', 
                    isHome 
                        ? 'Available (Price: ₹${(homePrice ?? price).toStringAsFixed(0)})'
                        : 'Not Available',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.star_outline_rounded, 
                    'Settings', 
                    'Featured: ${isFeatured ? "Yes" : "No"}  •  Popular: ${isPopular ? "Yes" : "No"}',
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  // Footer Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteService(service);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          label: Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddEditServiceModal(service: service);
                          },
                          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                          label: Text('Edit Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _showAddEditServiceModal({Map<String, dynamic>? service}) {
    if (_salonId == null) {
      _showToast('Cannot add/edit service: Salon ID is missing', isSuccess: false);
      return;
    }
    if (_dynamicCategories.isEmpty) {
      _loadDefaultCategories();
    }
    AddEditServiceForm.show(
      context,
      salonId: _salonId,
      service: service,
      categories: _dynamicCategories,
      onSave: (updatedData) {
        setState(() {
          if (service != null) {
            // Edit mode: replace values in the list
            final index = _services.indexWhere((element) => element['id'] == service['id']);
            if (index != -1) {
              _services[index] = updatedData;
            }
            _showToast('"${updatedData['name']}" updated successfully');
          } else {
            // Add mode: append to the list
            _services.add(updatedData);
            _showToast('"${updatedData['name']}" added successfully');
          }
        });
      },
    );
  }
}

// --- SUB-WIDGET: ADD & EDIT SERVICE FORM ---

class AddEditServiceForm extends StatefulWidget {
  final dynamic salonId;
  final Map<String, dynamic>? service;
  final List<ServiceCategory> categories;
  final Function(Map<String, dynamic> updatedData) onSave;

  const AddEditServiceForm({
    super.key,
    required this.salonId,
    this.service,
    required this.categories,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    required dynamic salonId,
    Map<String, dynamic>? service,
    required List<ServiceCategory> categories,
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
          return AddEditServiceForm(salonId: salonId, service: service, categories: categories, onSave: onSave);
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
              constraints: const BoxConstraints(maxWidth: 650, maxHeight: 850),
              child: AddEditServiceForm(salonId: salonId, service: service, categories: categories, onSave: onSave),
            ),
          );
        },
      );
    }
  }

  @override
  State<AddEditServiceForm> createState() => _AddEditServiceFormState();
}

class _AddEditServiceFormState extends State<AddEditServiceForm> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _homePriceController;
  late TextEditingController _customDurationController;

  late String _selectedCategory;
  late String _selectedDurationOption;

  late bool _isHomeService;
  late bool _isActive;
  late bool _isFeatured;
  late bool _isPopular;

  XFile? _selectedImage;
  String? _existingImagePath;

  bool _isSaving = false;
  bool _showSuccessAnimation = false;

  final List<String> _durations = [
    '15',
    '30',
    '45',
    '60',
    '90',
    '120',
    'Custom'
  ];

  final Map<String, String> _categoryImageTemplates = {
    'Hair Services': 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=300&q=80',
    'Grooming': 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=300&q=80',
    'Spa & Wellness': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=300&q=80',
    'Nail Services': 'https://images.unsplash.com/photo-1519014816548-bf5fe059798b?auto=format&fit=crop&w=300&q=80',
    'Makeup': 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=300&q=80',
    'Massage Therapy': 'https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?auto=format&fit=crop&w=300&q=80',
    'Facial Treatments': 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?auto=format&fit=crop&w=300&q=80',
    'Other': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=300&q=80',
  };

  String? _getCategoryImageTemplate(String categoryId) {
    if (widget.categories.isEmpty) return _categoryImageTemplates['Other'];
    final match = widget.categories.firstWhere(
      (c) => c.id.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => ServiceCategory(id: '', name: '', icon: ''),
    );
    final name = match.name;
    if (_categoryImageTemplates.containsKey(name)) {
      return _categoryImageTemplates[name];
    }
    final id = categoryId.toLowerCase();
    if (id.contains('hair') && !id.contains('color')) {
      return _categoryImageTemplates['Hair Services'];
    } else if (id.contains('beard') || id.contains('grooming')) {
      return _categoryImageTemplates['Grooming'];
    } else if (id.contains('facial') || id.contains('skin')) {
      return _categoryImageTemplates['Facial Treatments'];
    } else if (id.contains('makeup') || id.contains('bridal')) {
      return _categoryImageTemplates['Makeup'];
    } else if (id.contains('spa')) {
      return _categoryImageTemplates['Spa & Wellness'];
    } else if (id.contains('massage')) {
      return _categoryImageTemplates['Massage Therapy'];
    } else if (id.contains('nail')) {
      return _categoryImageTemplates['Nail Services'];
    }
    return _categoryImageTemplates['Other'];
  }

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    
    _nameController = TextEditingController(text: service != null ? service['name'] : '');
    _priceController = TextEditingController(text: service != null ? (service['price'] as double).toStringAsFixed(0) : '');
    _descController = TextEditingController(text: service != null ? service['description'] : '');
    _homePriceController = TextEditingController(
      text: service != null && service['homePrice'] != null ? (service['homePrice'] as double).toStringAsFixed(0) : ''
    );
    _customDurationController = TextEditingController();

    final initialCat = service != null ? service['category']?.toString() ?? '' : '';
    final matchedCat = widget.categories.firstWhere(
      (c) => c.id.toLowerCase() == initialCat.toLowerCase() || c.name.toLowerCase() == initialCat.toLowerCase(),
      orElse: () => ServiceCategory(id: '', name: '', icon: ''),
    );
    
    if (matchedCat.id.isNotEmpty) {
      _selectedCategory = matchedCat.id;
    } else if (initialCat.isNotEmpty) {
      _selectedCategory = initialCat;
      widget.categories.add(ServiceCategory(id: initialCat, name: initialCat, icon: ''));
    } else {
      _selectedCategory = widget.categories.isNotEmpty ? widget.categories.first.id : 'hair';
    }

    _isHomeService = service != null ? service['isHomeService'] : false;
    _isActive = service != null ? service['isActive'] : true;
    _isFeatured = service != null ? service['isFeatured'] : false;
    _isPopular = service != null ? service['isPopular'] : false;
    
    _selectedImage = service != null ? service['xFile'] as XFile? : null;
    _existingImagePath = service != null 
        ? service['imagePath'] as String? 
        : _getCategoryImageTemplate(_selectedCategory);

    if (service != null) {
      final dur = service['duration'] as int;
      if (['15', '30', '45', '60', '90', '120'].contains(dur.toString())) {
        _selectedDurationOption = dur.toString();
      } else {
        _selectedDurationOption = 'Custom';
        _customDurationController.text = dur.toString();
      }
    } else {
      _selectedDurationOption = '30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _homePriceController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                  if (_selectedImage == null) {
                    _existingImagePath = _getCategoryImageTemplate(_selectedCategory);
                  }
                });
              },
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              items: widget.categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    c.name,
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

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      // Extract duration
      int finalDuration;
      if (_selectedDurationOption == 'Custom') {
        finalDuration = int.parse(_customDurationController.text);
      } else {
        finalDuration = int.parse(_selectedDurationOption);
      }

      // Extract optional home price
      final double? homePrice = _isHomeService && _homePriceController.text.trim().isNotEmpty
          ? double.tryParse(_homePriceController.text.trim())
          : null;

      String? imageVal;
      if (_selectedImage != null) {
        try {
          final bytes = await _selectedImage!.readAsBytes();
          final b64 = base64Encode(bytes);
          imageVal = 'data:image/jpeg;base64,$b64';
        } catch (e) {
          imageVal = _existingImagePath;
        }
      } else {
        imageVal = _existingImagePath;
      }

      final servicePayload = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text.trim()),
        'duration': finalDuration,
        'description': _descController.text.trim(),
        'isActive': _isActive,
        'isHomeServiceAvailable': _isHomeService,
        'homeServicePrice': homePrice,
        'image': imageVal,
        'isFeatured': _isFeatured,
        'isPopular': _isPopular,
      };

      try {
        final Map<String, dynamic> res;
        if (widget.service != null) {
          // Edit Mode
          final updatePayload = {
            'name': _nameController.text.trim(),
            'description': _descController.text.trim(),
            'category': _selectedCategory,
            'isActive': _isActive,
            'isHomeServiceAvailable': _isHomeService,
            'homeSericePrice': homePrice ?? 0.0,
            'price': double.parse(_priceController.text.trim()),
            'duration': finalDuration,
          };
          res = await ApiService().updateSalonService(widget.salonId, widget.service!['id'], updatePayload);
        } else {
          // Create Mode
          res = await ApiService().createSalonService(widget.salonId, servicePayload);
        }

        if (!mounted) return;

        if (res['success'] == true) {
          setState(() {
            _isSaving = false;
            _showSuccessAnimation = true;
          });

          // Let success checkmark animate for 1 second, then pop
          await Future.delayed(const Duration(milliseconds: 1000));

          if (!mounted) return;

          // Map response data to UI format
          final Map<String, dynamic> responseData = res['data'] ?? {};
          
          final updatedData = {
            'id': responseData['id']?.toString() ?? widget.service?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'name': responseData['name'] ?? _nameController.text.trim(),
            'category': responseData['category'] ?? _selectedCategory,
            'price': (responseData['price'] as num?)?.toDouble() ?? double.parse(_priceController.text.trim()),
            'duration': responseData['duration'] ?? finalDuration,
            'description': responseData['description'] ?? _descController.text.trim(),
            'isHomeService': responseData['isHomeServiceAvailable'] ?? _isHomeService,
            'homePrice': (responseData['homeServicePrice'] as num?)?.toDouble() ?? homePrice,
            'isActive': responseData['isActive'] ?? _isActive,
            'isFeatured': responseData['isFeatured'] ?? widget.service?['isFeatured'] ?? _isFeatured,
            'isPopular': responseData['isPopular'] ?? widget.service?['isPopular'] ?? _isPopular,
            'xFile': _selectedImage,
            'imagePath': responseData['image'] ?? widget.service?['imagePath'] ?? imageVal,
          };

          widget.onSave(updatedData);
          Navigator.pop(context);
        } else {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error'] ?? 'An error occurred while saving the service.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save service: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;
    
    // Switch to animated checkmark view upon success
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
                      widget.service == null ? 'Add New Service' : 'Edit Service',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.service == null ? 'Create a new salon service' : 'Update salon service details',
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
          _buildFormSectionHeader('Basic Information'),
          const SizedBox(height: 12),
          
          _buildTextField(
            label: 'Service Name *',
            controller: _nameController,
            placeholder: 'e.g. Haircut',
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter Service Name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormDropdown(
                  label: 'Duration (Minutes) *',
                  value: _selectedDurationOption,
                  items: _durations,
                  onChanged: (val) => setState(() => _selectedDurationOption = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedDurationOption == 'Custom') ...[
            _buildTextField(
              label: 'Custom Duration (Minutes) *',
              controller: _customDurationController,
              placeholder: 'Enter minutes',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (val) {
                if (_selectedDurationOption == 'Custom') {
                  if (val == null || val.trim().isEmpty) {
                    return 'Select Duration';
                  }
                  final parsed = int.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Select Duration';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          _buildTextField(
            label: 'Price (₹) *',
            controller: _priceController,
            placeholder: 'e.g. 500',
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter Valid Price';
              }
              final parsed = double.tryParse(val);
              if (parsed == null || parsed <= 0) {
                return 'Enter Valid Price';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          _buildImageSelectorSection(),
          const SizedBox(height: 24),

          _buildFormSectionHeader('Description'),
          const SizedBox(height: 12),
          _buildDescriptionField(),
          const SizedBox(height: 24),

          _buildFormSectionHeader('Home Service Availability'),
          const SizedBox(height: 12),
          _buildHomeServiceCard(),
          const SizedBox(height: 24),

          _buildFormSectionHeader('Service Status'),
          const SizedBox(height: 12),
          _buildStatusCard(),
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
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.normal),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: const Color(0xFFFAF9F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
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
    required ValueChanged<String?> onChanged,
  }) {
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
            color: const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              onChanged: onChanged,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          maxLines: 3,
          maxLength: 250,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
            return Text(
              '$currentLength / $maxLength characters',
              style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 11),
            );
          },
          decoration: InputDecoration(
            hintText: 'Describe the service...',
            hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: const Color(0xFFFAF9F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _existingImagePath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Widget _buildImageSelectorSection() {
    Widget previewImageWidget;
    
    if (_selectedImage != null) {
      previewImageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: kIsWeb 
            ? Image.network(_selectedImage!.path, height: 120, width: double.infinity, fit: BoxFit.cover)
            : Image.file(File(_selectedImage!.path), height: 120, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (_existingImagePath != null) {
      if (_existingImagePath!.startsWith('http')) {
        previewImageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(_existingImagePath!, height: 120, width: double.infinity, fit: BoxFit.cover),
        );
      } else if (_existingImagePath!.startsWith('data:image') || _existingImagePath!.contains('base64')) {
        try {
          final cleanPath = _cleanBase64(_existingImagePath!);
          final base64Content = cleanPath.split(',').last;
          final bytes = base64Decode(base64Content);
          previewImageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(bytes, height: 120, width: double.infinity, fit: BoxFit.cover),
          );
        } catch (e) {
          previewImageWidget = Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          );
        }
      } else {
        previewImageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(_existingImagePath!, height: 120, width: double.infinity, fit: BoxFit.cover),
        );
      }
    } else {
      previewImageWidget = InkWell(
        onTap: _pickImageFromGallery,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentPurple.withValues(alpha: 0.3),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppColors.accentPurple,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Service Cover Image',
                style: GoogleFonts.outfit(
                  color: AppColors.accentPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to select from gallery',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormSectionHeader('Service Cover Image'),
        const SizedBox(height: 12),
        
        // Preview with option to clear
        Stack(
          children: [
            previewImageWidget,
            if (_selectedImage != null || _existingImagePath != null)
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: 'Clear Image',
                  child: ClipOval(
                    child: Container(
                      width: 28,
                      height: 28,
                      color: Colors.black54,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _existingImagePath = null;
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
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
        const SizedBox(height: 16),
        
        // Options Label
        Text(
          'Choose Template or Select from Gallery',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        // Row of options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Predefined category templates
              ..._categoryImageTemplates.entries.map((entry) {
                final categoryName = entry.key;
                final imageUrl = entry.value;
                final isSelected = _existingImagePath == imageUrl && _selectedImage == null;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _existingImagePath = imageUrl;
                      _selectedImage = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accentPurple : AppColors.borderLight,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryName,
                          style: GoogleFonts.inter(
                            color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              
              // Custom Gallery Picker button
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImage != null ? AppColors.accentPurple : AppColors.accentPurple.withValues(alpha: 0.4),
                          width: _selectedImage != null ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.accentPurple,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gallery',
                            style: GoogleFonts.inter(
                              color: AppColors.accentPurple,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Custom',
                      style: GoogleFonts.inter(
                        color: _selectedImage != null ? AppColors.accentPurple : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: _selectedImage != null ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeServiceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isHomeService ? AppColors.accentPurple : AppColors.borderLight, width: _isHomeService ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: _isHomeService ? AppColors.accentPurple.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isHomeService ? AppColors.accentPurple.withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_rounded, color: _isHomeService ? AppColors.accentPurple : AppColors.textSecondary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available for Home Service',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customers can book this service at their location.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isHomeService,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.accentPurple,
                onChanged: (val) {
                  setState(() {
                    _isHomeService = val;
                  });
                },
              ),
            ],
          ),
          if (_isHomeService) ...[
            const Divider(height: 24),
            _buildTextField(
              label: 'Home Service Price (₹)',
              controller: _homePriceController,
              placeholder: 'Leave empty to use the same price as salon service',
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 6),
            Text(
              'Leave empty to use the same price as salon service.',
              style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isActive ? const Color(0xFF10B981) : AppColors.borderLight,
          width: _isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isActive
                ? const Color(0xFF10B981).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isActive
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.toggle_on_rounded,
              color: _isActive ? const Color(0xFF10B981) : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Status (Active)',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isActive
                      ? 'Visible to customers and open for bookings.'
                      : 'Hidden from customers and bookings disabled.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF10B981),
            onChanged: (val) {
              setState(() {
                _isActive = val;
              });
            },
          ),
        ],
      ),
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
                widget.service == null ? 'Save Service' : 'Update Details',
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
            'Service updated in your catalog.',
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
