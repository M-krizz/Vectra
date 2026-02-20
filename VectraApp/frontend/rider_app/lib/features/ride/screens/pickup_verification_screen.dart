import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_theme.dart';
import '../bloc/ride_bloc.dart';
import '../widgets/safety_fab.dart';
import 'in_trip_screen.dart';

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
    final correctOtp = state.riderOtp ?? '1234';
    if (_enteredOtp.length < 4) return;

    if (_enteredOtp == correctOtp) {
      context.read<RideBloc>()
        ..add(RideOTPVerified(correctOtp))
        ..add(const RideStarted());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InTripScreen()),
      );
    } else {
      setState(() => _error = true);
      for (final c in _controllers) c.clear();
      _focuses[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideBloc, RideState>(
      builder: (context, state) {
        final otp = state.riderOtp ?? '1234';
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Verify Pickup',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0FE),
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
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: otp.split('').map((d) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                        )).toList(),
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
                          color: const Color(0xFFF5F7FA),
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
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }
}
