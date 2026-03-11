import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../repository/ride_repository.dart';

/// Rating dialog shown after ride completion
class RatingDialog extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String vehicleNumber;
  final double fare;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  const RatingDialog({
    super.key,
    required this.tripId,
    required this.driverName,
    required this.vehicleNumber,
    required this.fare,
    required this.onSubmit,
    required this.onSkip,
  });

  /// Show the rating dialog
  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required String driverName,
    required String vehicleNumber,
    required double fare,
    required VoidCallback onComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingDialog(
        tripId: tripId,
        driverName: driverName,
        vehicleNumber: vehicleNumber,
        fare: fare,
        onSubmit: () {
          Navigator.pop(context);
          onComplete();
        },
        onSkip: () {
          Navigator.pop(context);
          onComplete();
        },
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickReviews = [
    'Great driver!',
    'Smooth ride',
    'Very punctual',
    'Clean car',
    'Polite & friendly',
  ];
  String? _selectedQuickReview;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Checkmark
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Ride Completed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Text(
                'You paid ₹${widget.fare.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
              ),

              const SizedBox(height: 24),

              // Driver info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.outline.withValues(alpha: 0.3),
                      child: Icon(Icons.person, size: 28, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.vehicleNumber,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Rating stars
              const Text(
                'How was your ride?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _rating = index + 1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: index < _rating
                            ? AppColors.accent
                            : colors.outline,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 8),
              Text(
                _getRatingText(),
                style: TextStyle(
                  color: _rating > 0 ? AppColors.warning : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Quick reviews (only show if rated)
              if (_rating > 0) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickReviews.map((review) {
                    final isSelected = _selectedQuickReview == review;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedQuickReview = isSelected ? null : review;
                          if (!isSelected) {
                            _reviewController.text = review;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          review,
                          style: TextStyle(
                            color: isSelected ? colors.onPrimary : colors.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Review text field
                TextField(
                  controller: _reviewController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a comment (optional)',
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Tip section (optional feature)
              if (_rating >= 4) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add a tip for your driver?',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '100% goes to the driver',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tip feature coming soon'),
                            ),
                          );
                        },
                        child: const Text('Add Tip'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rating > 0 && !_isSubmitting
                      ? _submitRating
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor: colors.outline.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Submit Rating'),
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: _isSubmitting ? null : widget.onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Very Bad';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      if (widget.tripId.isEmpty) {
        throw Exception('Missing trip id for rating submission');
      }

      await context.read<RideRepository>().submitTripRating(
        tripId: widget.tripId,
        rating: _rating,
        feedback: _reviewController.text,
        tags: _selectedQuickReview == null ? null : [_selectedQuickReview!],
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      widget.onSubmit();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit rating. Please try again.')),
      );
    }
  }
}
