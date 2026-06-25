import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_service.dart';

class MySalonView extends StatefulWidget {
  final Map<String, dynamic>? salonDetail;
  final List<Map<String, dynamic>> salons;
  final Function(Map<String, dynamic>)? onSalonUpdated;
  final Function(Map<String, dynamic>)? onSalonAdded;

  const MySalonView({
    super.key,
    this.salonDetail,
    required this.salons,
    this.onSalonUpdated,
    this.onSalonAdded,
  });

  @override
  State<MySalonView> createState() => _MySalonViewState();
}

class _MySalonViewState extends State<MySalonView> {
  final _formKey = GlobalKey<FormState>();
  
  String _viewMode = 'list'; // 'list', 'create', 'edit'
  Map<String, dynamic>? _selectedSalonForEdit;
  bool _isSaving = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _basePriceController = TextEditingController(text: '500');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Fields state
  bool _offersHomeService = false;
  String _selectedPriceRange = '₹₹';
  String _selectedGenderServed = 'UNISEX';
  bool _isActive = true;
  bool _isLocating = false;
  late Map<String, Map<String, dynamic>> _operatingHours;

  @override
  void initState() {
    super.initState();
    _operatingHours = _createDefaultOperatingHours();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _websiteController.dispose();
    _basePriceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> _createDefaultOperatingHours() {
    return {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '18:00'}
    };
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeForUI(String timeStr) {
    try {
      final time = _parseTimeString(timeStr);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (_) {
      return timeStr;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Location Services Disabled', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: const Text('GPS/Location services are turned off on your device. Please turn them on to autofill coordinates.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Open Settings', style: GoogleFonts.inter(color: AppColors.accentPurple, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Geolocator.openLocationSettings();
                    },
                  ),
                ],
              );
            },
          );
        }
        setState(() {
          _isLocating = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied.', isError: true);
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Location Permission Denied', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: const Text('Location permissions are permanently denied. Please enable them in your app settings to use GPS location.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Open Settings', style: GoogleFonts.inter(color: AppColors.accentPurple, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Geolocator.openAppSettings();
                    },
                  ),
                ],
              );
            },
          );
        }
        setState(() {
          _isLocating = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          
          String streetName = '';
          if (place.street != null && place.street!.isNotEmpty) {
            streetName = place.street!;
          } else {
            streetName = '${place.name ?? ''} ${place.subLocality ?? ''}';
          }
          
          if (mounted) {
            if (_addressController.text.trim().isEmpty) {
              _addressController.text = streetName.trim();
            }
            if (_cityController.text.trim().isEmpty) {
              _cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
            }
            if (_stateController.text.trim().isEmpty) {
              _stateController.text = place.administrativeArea ?? '';
            }
            if (_pincodeController.text.trim().isEmpty) {
              _pincodeController.text = place.postalCode ?? '';
            }
            _showSnackBar('Location coordinates & details updated from GPS!', isError: false);
          }
        }
      } catch (e) {
        _showSnackBar('Fetched coordinates, but address lookup failed.', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to get location: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Widget _buildOperatingHoursEditor() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: days.map((day) {
        final dayData = _operatingHours[day]!;
        final isOpen = dayData['isOpen'] as bool;
        final openTime = dayData['openTime'] as String;
        final closeTime = dayData['closeTime'] as String;
        final capitalizedDay = day[0].toUpperCase() + day.substring(1);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capitalizedDay,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isOpen ? Colors.green : AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOpen,
                activeTrackColor: AppColors.accentPurple,
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _operatingHours[day]!['isOpen'] = val;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: AnimatedOpacity(
                  opacity: isOpen ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(
                    ignoring: !isOpen,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(day, 'openTime', openTime),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Center(
                                child: Text(
                                  _formatTimeForUI(openTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('-', style: TextStyle(color: AppColors.textLight)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(day, 'closeTime', closeTime),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Center(
                                child: Text(
                                  _formatTimeForUI(closeTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectTime(String day, String key, String currentTimeStr) async {
    final initialTime = _parseTimeString(currentTimeStr);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentPurple,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _operatingHours[day]![key] = _formatTimeOfDay(selectedTime);
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _descriptionController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _websiteController.clear();
    _basePriceController.text = '500';
    _latitudeController.clear();
    _longitudeController.clear();
    _offersHomeService = false;
    _selectedPriceRange = '₹₹';
    _selectedGenderServed = 'UNISEX';
    _isActive = true;
    _operatingHours = _createDefaultOperatingHours();
    _selectedSalonForEdit = null;
  }

  void _populateForm(Map<String, dynamic> s) {
    _selectedSalonForEdit = s;
    _nameController.text = s['name'] ?? '';
    _emailController.text = s['email'] ?? '';
    _phoneController.text = s['phone'] ?? '';
    _descriptionController.text = s['description'] ?? '';
    _addressController.text = s['address'] ?? '';
    _cityController.text = s['city'] ?? '';
    _stateController.text = s['state'] ?? '';
    _pincodeController.text = s['pincode']?.toString() ?? s['zipCode']?.toString() ?? '';
    _websiteController.text = s['website'] ?? '';
    _basePriceController.text = s['basePrice']?.toString() ?? '500';
    _latitudeController.text = s['latitude']?.toString() ?? '';
    _longitudeController.text = s['longitude']?.toString() ?? '';
    _offersHomeService = s['offersHomeService'] ?? false;
    _selectedPriceRange = s['priceRange'] ?? '₹₹';
    _isActive = s['isActive'] ?? true;
    
    final rawGender = s['genderServed']?.toString().toUpperCase() ?? 'UNISEX';
    if (rawGender == 'MEN' || rawGender == 'WOMEN' || rawGender == 'UNISEX') {
      _selectedGenderServed = rawGender;
    } else {
      _selectedGenderServed = 'UNISEX';
    }

    if (s['operatingHours'] is Map) {
      _operatingHours = {};
      final rawHours = s['operatingHours'] as Map;
      for (final day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
        if (rawHours[day] is Map) {
          final dayData = rawHours[day] as Map;
          _operatingHours[day] = {
            'isOpen': dayData['isOpen'] ?? false,
            'openTime': dayData['openTime']?.toString() ?? '09:00',
            'closeTime': dayData['closeTime']?.toString() ?? '18:00',
          };
        } else {
          _operatingHours[day] = {
            'isOpen': false,
            'openTime': '09:00',
            'closeTime': '18:00',
          };
        }
      }
    } else {
      _operatingHours = _createDefaultOperatingHours();
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final Map<String, dynamic> payload = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'zipCode': _pincodeController.text.trim(), // Send both for compatibility
      'basePrice': double.tryParse(_basePriceController.text.trim()) ?? 500.0,
      'priceRange': _selectedPriceRange,
      'offersHomeService': _offersHomeService,
      'genderServed': _selectedGenderServed,
      'isActive': _isActive,
      'operatingHours': _operatingHours,
    };

    if (_websiteController.text.trim().isNotEmpty) {
      payload['website'] = _websiteController.text.trim();
    }

    final latVal = double.tryParse(_latitudeController.text.trim());
    if (latVal != null) {
      payload['latitude'] = latVal;
    }

    final lngVal = double.tryParse(_longitudeController.text.trim());
    if (lngVal != null) {
      payload['longitude'] = lngVal;
    }

    try {
      if (_viewMode == 'create') {
        final res = await ApiService().createSalon(payload);
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          if (res['success'] == true) {
            _showSnackBar(res['message'] ?? 'Salon created successfully!', isError: false);
            if (widget.onSalonAdded != null) {
              widget.onSalonAdded!(res['data']);
            }
            setState(() {
              _viewMode = 'list';
            });
            _clearForm();
          } else {
            _showSnackBar(res['error'] ?? 'Failed to create salon.', isError: true);
          }
        }
      } else {
        // Edit mode
        final salonId = _selectedSalonForEdit?['id'];
        if (salonId == null) return;
        final res = await ApiService().updateSalon(salonId.toString(), payload);
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          if (res['success'] == true) {
            _showSnackBar(res['message'] ?? 'Salon updated successfully!', isError: false);
            if (widget.onSalonUpdated != null) {
              widget.onSalonUpdated!(res['data'] ?? payload);
            }
            setState(() {
              _viewMode = 'list';
            });
            _clearForm();
          } else {
            _showSnackBar(res['error'] ?? 'Failed to update salon.', isError: true);
          }
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
        automaticallyImplyLeading: false,
        title: Text(
          _viewMode == 'list'
              ? 'Salon Management'
              : (_viewMode == 'create' ? 'Create New Salon' : 'Edit Salon Settings'),
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_viewMode != 'list')
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  _viewMode = 'list';
                });
                _clearForm();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _viewMode == 'list' ? _buildSalonList() : _buildSalonForm(),
        ),
      ),
    );
  }

  Widget _buildSalonList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Salons (${widget.salons.length})',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _viewMode = 'create';
                  });
                  _clearForm();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Add Salon',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.salons.isEmpty)
            Expanded(
              child: Center(
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
                        Icons.storefront_rounded,
                        color: AppColors.accentPurple,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Salons Registered',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get started by creating your first salon profile.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.salons.length,
                itemBuilder: (context, index) {
                  final s = widget.salons[index];
                  final isActive = s['id'] == widget.salonDetail?['id'];
                  return FadeSlideTransition(
                    delay: Duration(milliseconds: 50 * index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.accentPurple.withValues(alpha: 0.6)
                              : AppColors.borderLight.withValues(alpha: 0.6),
                          width: isActive ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
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
                                s['name'] ?? 'Salon Name',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  if (s['isActive'] == false) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.red.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        'INACTIVE',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentPurple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.accentPurple.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        'CURRENT PORTAL',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentPurple,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (s['description'] != null && s['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              s['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const Divider(height: 24),
                          _buildDetailRow(Icons.pin_drop_outlined, '${s['address'] ?? ''}, ${s['city'] ?? ''}, ${s['state'] ?? ''}'),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.phone_android_rounded, s['phone'] ?? 'No contact'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildBadge(s['genderServed'] ?? 'UNISEX', Icons.wc),
                              const SizedBox(width: 8),
                              _buildBadge('Price: ${s['priceRange'] ?? '₹₹'}', Icons.sell_outlined),
                              if (s['offersHomeService'] == true) ...[
                                const SizedBox(width: 8),
                                _buildBadge('Home Service', Icons.home_outlined),
                              ],
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _viewMode = 'edit';
                                  });
                                  _populateForm(s);
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                label: Text(
                                  'Edit Salon',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonForm() {
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
              _buildFormTitle('BRANDING & HOTLINE'),
              _buildFormSectionCard([
                _buildFieldLabel('Salon Name *'),
                CustomTextField(
                  hintText: 'Enter salon registered name',
                  prefixIcon: Icons.storefront_rounded,
                  controller: _nameController,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter salon name' : null,
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Business Description *'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Describe experience, services, facilities...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter description' : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Hotline Phone Number *'),
                CustomTextField(
                  hintText: 'Enter contact phone number',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter phone' : null,
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Email Address *'),
                CustomTextField(
                  hintText: 'Enter salon email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter email' : null,
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Website URL (Optional)'),
                CustomTextField(
                  hintText: 'e.g. https://luxesalon.com',
                  prefixIcon: Icons.language_rounded,
                  controller: _websiteController,
                ),
                const Divider(height: 32),
                SwitchListTile(
                  value: _isActive,
                  title: Text(
                    'Salon Status (Active / Inactive)',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Inactive salons are hidden from client app search results.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.accentPurple,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildFormTitle('OPERATING HOURS'),
              _buildFormSectionCard([
                _buildOperatingHoursEditor(),
              ]),
              const SizedBox(height: 24),
              _buildFormTitle('PRICING & AUDIENCE'),
              _buildFormSectionCard([
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Price Category'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedPriceRange,
                                decoration: const InputDecoration(border: InputBorder.none),
                                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                items: ['₹', '₹₹', '₹₹₹', '₹₹₹₹'].map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedPriceRange = val!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Base Price (₹) *'),
                          CustomTextField(
                            hintText: 'e.g. 500',
                            prefixIcon: Icons.sell_outlined,
                            keyboardType: TextInputType.number,
                            controller: _basePriceController,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter price';
                              }
                              if (double.tryParse(val) == null) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Target Audience *'),
                Row(
                  children: [
                    _buildGenderRadio('UNISEX', Icons.wc),
                    const SizedBox(width: 8),
                    _buildGenderRadio('MEN', Icons.man),
                    const SizedBox(width: 8),
                    _buildGenderRadio('WOMEN', Icons.woman),
                  ],
                ),
                const Divider(height: 32),
                SwitchListTile(
                  value: _offersHomeService,
                  title: Text(
                    'Offers Home Service Delivery',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Allow clients to book appointments at home.',
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
              ]),
              const SizedBox(height: 24),
              _buildFormTitle('LOCATION ADDRESS'),
              _buildFormSectionCard([
                _buildFieldLabel('Street Location Address *'),
                CustomTextField(
                  hintText: 'Enter street location address',
                  prefixIcon: Icons.location_on_outlined,
                  controller: _addressController,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('City *'),
                          CustomTextField(
                            hintText: 'e.g. City',
                            prefixIcon: Icons.location_city_outlined,
                            controller: _cityController,
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter city' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('State *'),
                          CustomTextField(
                            hintText: 'e.g. State',
                            prefixIcon: Icons.map_outlined,
                            controller: _stateController,
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter state' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('ZIP / Pincode *'),
                CustomTextField(
                  hintText: 'Enter Pincode',
                  prefixIcon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  controller: _pincodeController,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter Pincode' : null,
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Latitude'),
                          CustomTextField(
                            hintText: 'e.g. 28.6139',
                            prefixIcon: Icons.explore_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: _latitudeController,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Enter valid latitude';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Longitude'),
                          CustomTextField(
                            hintText: 'e.g. 77.2090',
                            prefixIcon: Icons.explore_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: _longitudeController,
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Enter valid longitude';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    icon: _isLocating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.accentPurple),
                    label: Text(
                      _isLocating ? 'Locating via GPS...' : 'Get Location from GPS',
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.accentPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
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
                        text: _viewMode == 'create' ? 'Generate Salon Profile' : 'Save Salon Settings',
                        borderRadius: 12,
                        onPressed: _handleSave,
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
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

  Widget _buildFormSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        children: children,
      ),
    );
  }

  Widget _buildGenderRadio(String gender, IconData icon) {
    final isSelected = _selectedGenderServed == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGenderServed = gender;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple.withValues(alpha: 0.08) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.accentPurple : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                gender,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
