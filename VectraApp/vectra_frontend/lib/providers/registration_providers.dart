import 'package:flutter_riverpod/flutter_riverpod.dart';

// Step Management
final stepProvider = StateProvider<int>((_) => 0);

// Name & Email Step
final nameInputProvider = StateProvider<String>((_) => '');
final emailInputProvider = StateProvider<String>((_) => '');
final emailValidationProvider = Provider<ValidationState>((ref) {
  final input = ref.watch(emailInputProvider);
  return _validateEmail(input);
});

// Phone Step
final phoneInputProvider = StateProvider<String>((_) => '');
final phoneValidationProvider = Provider<ValidationState>((ref) {
  final input = ref.watch(phoneInputProvider);
  return _validatePhone(input);
});

// Legacy identity provider (kept for compatibility)
final identityInputProvider = StateProvider<String>((_) => '');
final identityValidationProvider = Provider<ValidationState>((ref) {
  final input = ref.watch(identityInputProvider);
  return _validateIdentity(input);
});

// OTP Step
final otpProvider = StateProvider<String>((_) => '');
final otpValidationProvider = Provider<bool>((ref) {
  final otp = ref.watch(otpProvider);
  return otp.length == 4 && RegExp(r'^\d{4}$').hasMatch(otp);
});

// Document Upload Step
final documentUploadedProvider = StateProvider<bool>((_) => false);
final uploadProgressProvider = StateProvider<double>((_) => 0.0);

// Driver Verification Status
final verificationStatusProvider = StateProvider<VerificationStatus>(
  (_) => VerificationStatus.pending,
);

// Validation Helpers
ValidationState _validateEmail(String input) {
  if (input.isEmpty) {
    return ValidationState.empty;
  }
  
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (emailRegex.hasMatch(input)) {
    return ValidationState.valid;
  }
  
  return ValidationState.invalid;
}

ValidationState _validatePhone(String input) {
  if (input.isEmpty) {
    return ValidationState.empty;
  }
  
  // Phone regex (international format)
  final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  if (phoneRegex.hasMatch(input)) {
    return ValidationState.valid;
  }
  
  return ValidationState.invalid;
}

ValidationState _validateIdentity(String input) {
  if (input.isEmpty) {
    return ValidationState.empty;
  }
  
  // Email regex
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (emailRegex.hasMatch(input)) {
    return ValidationState.valid;
  }
  
  // Phone regex (international format)
  final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  if (phoneRegex.hasMatch(input)) {
    return ValidationState.valid;
  }
  
  return ValidationState.invalid;
}

// Enums
enum ValidationState { empty, invalid, valid }

enum VerificationStatus {
  pending,
  scanning,
  identityVerified,
  documentsProcessing,
  backgroundCheckPending,
  completed,
}
