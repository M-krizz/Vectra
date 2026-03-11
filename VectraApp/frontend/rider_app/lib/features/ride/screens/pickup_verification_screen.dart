import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import '../widgets/safety_fab.dart';

class PickupVerificationScreen extends StatefulWidget {
  const PickupVerificationScreen({super.key});

  @override
  State<PickupVerificationScreen> createState() =>
      _PickupVerificationScreenState();
}

class _PickupVerificationScreenState extends State<PickupVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focuses = List.generate(4, (_) => FocusNode());
  bool _error = false;

  String get _enteredOtp =>
      _controllers.map((c) => c.text).join();

  void _onDigit(int index, String val) {
    if (val.isNotEmpty && index < 3) {
      _focuses[index + 1].requestFocus();
    }
    setState(() => _error = false);
  }

  void _verify() {
    final state = context.read<RideBloc>().state;
    final correctOtp = state.riderOtp;
    if (correctOtp == null || correctOtp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for trip OTP from server...')),
      );
      return;
    }
    if (_enteredOtp.length < 4) return;

    if (_enteredOtp == correctOtp) {
      context.read<RideBloc>().add(const RideOTPVerified());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified. Waiting for driver to start trip...')),
      );
    } else {
      setState(() => _error = true);
      for (final c in _controllers) {
        c.clear();
      }
      _focuses[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RideBloc, RideState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final tripId = state.rideId ?? 'current';
        if (state.status == RideStatus.inProgress) {
          context.go('/trip/$tripId/in-progress');
        } else if (state.status == RideStatus.completed) {
          context.go('/trip/$tripId/completed');
        } else if (state.status == RideStatus.cancelled) {
          context.go('/trip/$tripId/cancelled');
        }
      },
      child: BlocBuilder<RideBloc, RideState>(
        builder: (context, state) {
          final otp = state.riderOtp;
          return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Verify Pickup',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Theme.of(context).colorScheme.outline),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Show this OTP to your driver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your driver will enter this code to start the trip.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Display OTP for rider to show driver
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: otp != null && otp.isNotEmpty
                        ? otp
                              .split('')
                              .map(
                                (digit) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    digit,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              )
                              .toList()
                        : [
                            const Text(
                              '----',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                  ),
                ),
                if (otp == null || otp.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Waiting for driver assignment OTP...',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),

                const SizedBox(height: 32),
                const Text(
                  'Or enter if driver confirms it:',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // OTP input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(
                        width: 56,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _error
                                ? AppColors.error
                                : _focuses[i].hasFocus
                                    ? AppColors.primary
                                    : AppColors.border,
                            width: _focuses[i].hasFocus ? 2 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focuses[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => _onDigit(i, v),
                        ),
                      )),
                ),

                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: const Text(
                      'Incorrect OTP. Please try again.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Verify & Start',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: const SafetyFab(),
        );
      },
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }
}
