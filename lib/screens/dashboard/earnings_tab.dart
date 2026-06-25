import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../widgets/stat_card.dart';
import '../../services/api_service.dart';

class EarningsTab extends StatefulWidget {
  final Map<String, dynamic>? salonDetail;

  const EarningsTab({super.key, this.salonDetail});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  String _selectedTimeframe = 'Weekly';
  Map<String, dynamic>? _earningsData;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;



  @override
  void initState() {
    super.initState();
    _loadEarningsAndTransactions();
  }

  @override
  void didUpdateWidget(covariant EarningsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.salonDetail?['id'] != oldWidget.salonDetail?['id']) {
      _loadEarningsAndTransactions();
    }
  }

  Future<void> _loadEarningsAndTransactions() async {
    final salonId = widget.salonDetail?['id'];
    if (salonId == null) {
      setState(() {
        _errorMessage = 'No active salon selected.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Future<Map<String, dynamic>> earningsFuture = ApiService().getSalonEarnings(salonId);
      final Future<Map<String, dynamic>> bookingsFuture = ApiService().getSalonBookings(salonId);

      final results = await Future.wait([earningsFuture, bookingsFuture]);
      final earningsRes = results[0];
      final bookingsRes = results[1];

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (earningsRes['success'] == true) {
            _earningsData = earningsRes['data'];
          } else {
            _errorMessage = earningsRes['error'] ?? 'Failed to load earnings stats.';
          }

          if (bookingsRes['success'] == true) {
            // Map bookings to transaction structure
            final List<dynamic> bookingsList = bookingsRes['data'] ?? [];
            _transactions = bookingsList.map<Map<String, dynamic>>((b) {
              final customerName = b['customer']?['name'] ?? b['customerName'] ?? b['client']?['name'] ?? b['clientName'] ?? 'Unknown Client';
              
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
              
              // Format time
              final dateStr = b['date'] ?? b['bookingDate'] ?? 'Date';
              final timeStr = b['time'] ?? b['bookingTime'] ?? '';
              final formattedDate = timeStr.isNotEmpty ? '$dateStr, $timeStr' : dateStr;

              final priceVal = b['grandTotal']?.toString() ?? b['finalBill']?.toString() ?? b['totalPrice']?.toString() ?? b['price']?.toString() ?? b['amount']?.toString() ?? b['totalAmount']?.toString() ?? '0';
              final rawStatus = b['status'] ?? b['bookingStatus'] ?? 'Pending';
              final statusText = rawStatus.toString().toUpperCase();

              String paymentMode = 'UPI / GPay';
              if (b['paymentMode'] != null) {
                paymentMode = b['paymentMode'].toString();
              } else if (b['paymentMethod'] != null) {
                paymentMode = b['paymentMethod'].toString();
              }

              return {
                'id': b['bookingNumber']?.toString() ?? b['id']?.toString() ?? 'TXN-${b['bookingId'] ?? 'UNK'}',
                'client': customerName,
                'service': serviceName,
                'amount': '₹$priceVal',
                'date': formattedDate,
                'paymentMode': paymentMode,
                'status': statusText[0] + statusText.substring(1).toLowerCase(),
              };
            }).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
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
          'Earnings & Analytics',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentPurple),
            onPressed: _loadEarningsAndTransactions,
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _selectedTimeframe,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentPurple),
              underline: Container(),
              style: GoogleFonts.inter(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTimeframe = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadEarningsAndTransactions,
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
                : RefreshIndicator(
                    onRefresh: _loadEarningsAndTransactions,
                    color: AppColors.accentPurple,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payout Transactions',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Text(
                                    'Export CSV',
                                    style: GoogleFonts.inter(
                                      color: AppColors.accentPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTransactionsList(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalEarnings = (_earningsData?['totalEarnings'] as num? ?? 0).toDouble();
    final pendingPayouts = (_earningsData?['pendingPayouts'] as num? ?? 0).toDouble();
    final completedPayouts = (_earningsData?['completedPayouts'] as num? ?? 0).toDouble();
    final commissions = totalEarnings * 0.10;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Earnings',
                value: '₹${totalEarnings.toStringAsFixed(0)}',
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                trendText: 'Earnings',
                isTrendPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Pending Payouts',
                value: '₹${pendingPayouts.toStringAsFixed(0)}',
                icon: Icons.hourglass_empty_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                trendText: 'Pending',
                isTrendPositive: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Completed Payouts',
                value: '₹${completedPayouts.toStringAsFixed(0)}',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                trendText: 'Payouts',
                isTrendPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Commission (10%)',
                value: '₹${commissions.toStringAsFixed(0)}',
                icon: Icons.percent_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                trendText: 'Commissions',
                isTrendPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.textLight, size: 40),
            const SizedBox(height: 12),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete bookings to see your payout history here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_transactions.length, (index) {
        final txn = _transactions[index];
        return FadeSlideTransition(
          delay: Duration(milliseconds: 200 + (index * 50)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn['client']!,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${txn['paymentMode']} • ${txn['date']}',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      txn['amount']!,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        txn['status']!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
