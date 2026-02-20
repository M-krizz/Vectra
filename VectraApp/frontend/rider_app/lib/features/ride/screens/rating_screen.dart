import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  final _tags = ['Polite driver', 'Clean vehicle', 'Safe driving', 'On time', 'Great route'];
  final Set<String> _selectedTags = {};
  bool _submitted = false;

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Rate Your Ride',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          body: _submitted ? _SuccessView(onDone: () {
            context.read<RideBloc>().add(const RideCleared());
            context.go('/home');
          }) : _RatingForm(
            driver: state.driver,
            rating: _rating,
            tags: _tags,
            selectedTags: _selectedTags,
            feedbackController: _feedbackController,
            onRating: (r) => setState(() => _rating = r),
            onTagToggle: (t) => setState(() {
              if (_selectedTags.contains(t)) {
                _selectedTags.remove(t);
              } else {
                _selectedTags.add(t);
              }
            }),
            onSubmit: _submit,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}

class _RatingForm extends StatelessWidget {
  final DriverInfo? driver;
  final int rating;
  final List<String> tags;
  final Set<String> selectedTags;
  final TextEditingController feedbackController;
  final Function(int) onRating;
  final Function(String) onTagToggle;
  final VoidCallback onSubmit;

  const _RatingForm({
    required this.driver,
    required this.rating,
    required this.tags,
    required this.selectedTags,
    required this.feedbackController,
    required this.onRating,
    required this.onTagToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Driver avatar
        Center(
          child: Column(children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: Color(0xFFF5F7FA), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 38, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(driver?.name ?? 'Your Driver',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(driver?.vehicleModel ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
        ),

        const SizedBox(height: 28),

        // Stars
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < rating;
              return GestureDetector(
                onTap: () => onRating(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 44,
                    color: filled ? const Color(0xFFFFA000) : AppColors.border,
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),
        Center(
          child: Text(
            rating == 0 ? 'Tap to rate' : ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][rating],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: rating > 0 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Tags
        const Text('What went well?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((t) {
            final selected = selectedTags.contains(t);
            return GestureDetector(
              onTap: () => onTagToggle(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFE8F0FE) : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(t,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppColors.primary : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Feedback text
        const Text('Additional feedback (optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: feedbackController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Share your experience…',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Submit Rating',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🙏', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          const Text('Thank you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Your feedback helps us keep improving Vectra for everyone.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Back to Home',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
