class SignUpData {
  // Phone & OTP
  String phoneNumber = '';

  // Stage 1: Basic Details
  String fullName = '';
  String email = '';
  String password = '';

  // Stage 2: Vehicle Details
  String vehicleType = '';
  String vehicleBrand = '';
  String vehicleModel = '';
  String vehicleNumber = '';
  String vehicleColor = '';
  int vehicleYear = DateTime.now().year;

  // Stage 3: Documents
  String? licensePath;
  String? rcBookPath;
  String? aadharPath;
  String? panCardPath;
}
