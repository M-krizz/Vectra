import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final bool isInteractive;
  final ValueChanged<double>? onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingWidget({
    super.key,
    this.initialRating = 0,
    this.isInteractive = true,
    this.onRatingChanged,
    this.size = 32,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _updateRating(double newRating) {
    if (!widget.isInteractive) return;
    
    setState(() {
      _rating = newRating;
    });
    
    widget.onRatingChanged?.call(newRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= _rating;
        final isHalfFilled = starValue - 0.5 == _rating;

        return GestureDetector(
          onTap: widget.isInteractive
              ? () => _updateRating(starValue.toDouble())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isHalfFilled
                  ? Icons.star_half
                  : isFilled
                      ? Icons.star
                      : Icons.star_border,
              color: isFilled || isHalfFilled
                  ? (widget.activeColor ?? AppColors.hyperLime)
                  : (widget.inactiveColor ?? AppColors.white30),
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}

// Display-only rating with text
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? totalRatings;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.totalRatings,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: AppColors.hyperLime,
          size: size,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: size * 0.875,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (totalRatings != null) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: GoogleFonts.dmSans(
              color: AppColors.white50,
              fontSize: size * 0.75,
            ),
          ),
        ],
      ],
    );
  }
}
