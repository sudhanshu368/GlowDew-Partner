import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/fade_slide_transition.dart';
import '../../services/api_service.dart';

class ReviewsView extends StatefulWidget {
  final Map<String, dynamic>? salonDetail;

  const ReviewsView({
    super.key,
    this.salonDetail,
  });

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  List<dynamic> _reviewsList = [];
  Map<String, dynamic>? _ratingStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviewsData();
  }

  Future<void> _loadReviewsData() async {
    final salonId = widget.salonDetail?['id'];
    if (salonId == null) {
      setState(() {
        _isLoading = false;
        _reviewsList = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviewsRes = await ApiService().getSalonReviews(salonId);
      final statsRes = await ApiService().getSalonRatingsSummary(salonId);

      if (reviewsRes['success'] == true && statsRes['success'] == true) {
        setState(() {
          _reviewsList = reviewsRes['data'] is List ? reviewsRes['data'] : [];
          _ratingStats = statsRes['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = reviewsRes['error'] ?? statsRes['error'] ?? 'Failed to fetch reviews data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recently';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonName = widget.salonDetail?['name'] ?? 'Salon';
    final averageRating = _ratingStats?['averageRating'] ?? widget.salonDetail?['rating'] ?? 0.0;
    final totalReviews = _ratingStats?['totalReviews'] ?? widget.salonDetail?['totalReviews'] ?? 0;

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
          'Customer Reviews',
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
                            'Failed to Load Reviews',
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
                            onPressed: _loadReviewsData,
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
                    onRefresh: _loadReviewsData,
                    color: AppColors.accentPurple,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                  child: const Icon(Icons.star_rate_rounded, color: AppColors.accentPurple, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Feedback board for $salonName',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Monitor user ratings and respond to business feedback.',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Feedback Board',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${averageRating.toStringAsFixed(2)} Salon Average ($totalReviews)',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_reviewsList.isEmpty)
                              _buildEmptyReviewsState()
                            else
                              ..._reviewsList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final rev = entry.value;
                                return _buildReviewCard(rev, index);
                              }),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyReviewsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(28),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_outlined, color: AppColors.accentPurple, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your salon doesn\'t have any customer reviews yet. Ratings and reviews will automatically appear here once users submit feedback.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> rev, int index) {
    final clientName = rev['user']?['name'] ?? rev['client'] ?? 'Anonymous';
    final rating = (rev['rating'] ?? 5) as int;
    final text = rev['comment'] ?? rev['text'] ?? '';
    final date = _formatDate(rev['createdAt'] ?? rev['date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                clientName,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                date,
                style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star_rounded,
                color: i < rating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                size: 14,
              ),
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
