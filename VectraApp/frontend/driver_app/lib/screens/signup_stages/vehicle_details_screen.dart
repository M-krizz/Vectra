import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';
import 'document_upload_screen.dart';
import '../../utils/notification_overlay.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final SignUpData signUpData;

  const VehicleDetailsScreen({super.key, required this.signUpData});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();
  final _colorController = TextEditingController();

  String? _selectedVehicleType;
  int _selectedYear = DateTime.now().year;

  final List<String> _vehicleTypes = ['Bike', 'Auto Rickshaw', 'Car', 'SUV'];

  @override
  void initState() {
    super.initState();
    _brandController.text = widget.signUpData.vehicleBrand;
    _modelController.text = widget.signUpData.vehicleModel;
    _numberController.text = widget.signUpData.vehicleNumber;
    _colorController.text = widget.signUpData.vehicleColor;
    _selectedVehicleType = widget.signUpData.vehicleType.isEmpty
        ? null
        : widget.signUpData.vehicleType;
    _selectedYear = widget.signUpData.vehicleYear;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _numberController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleType == null) {
        NotificationOverlay.showMessage(
          context,
          'Please select a vehicle type',
          backgroundColor: AppColors.error,
        );
        return;
      }

      widget.signUpData.vehicleType = _selectedVehicleType!;
      widget.signUpData.vehicleBrand = _brandController.text;
      widget.signUpData.vehicleModel = _modelController.text;
      widget.signUpData.vehicleNumber = _numberController.text.toUpperCase();
      widget.signUpData.vehicleColor = _colorController.text;
      widget.signUpData.vehicleYear = _selectedYear;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DocumentUploadScreen(signUpData: widget.signUpData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(2),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Details',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Step 2 of 4',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Vehicle Type
                      const Text(
                        'Vehicle Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVehicleType,
                        decoration: const InputDecoration(
                          hintText: 'Select vehicle type',
                          prefixIcon: Icon(
                            Icons.directions_car,
                            color: AppColors.primary,
                          ),
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedVehicleType = value);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Vehicle Brand
                      const Text(
                        'Vehicle Brand',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Honda, Bajaj, Maruti',
                          prefixIcon: Icon(
                            Icons.branding_watermark,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle brand';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Vehicle Model
                      const Text(
                        'Vehicle Model',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Activa, Pulsar, Swift',
                          prefixIcon: Icon(
                            Icons.model_training,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle model';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Vehicle Number
                      const Text(
                        'Vehicle Registration Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _numberController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'e.g., TN01AB1234',
                          prefixIcon: Icon(Icons.pin, color: AppColors.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle number';
                          }
                          if (value.length < 6) {
                            return 'Please enter a valid vehicle number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Vehicle Color
                      const Text(
                        'Vehicle Color',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Black, White, Red',
                          prefixIcon: Icon(
                            Icons.palette,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle color';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Manufacturing Year
                      const Text(
                        'Manufacturing Year',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                          ),
                        ),
                        items: List.generate(30, (index) {
                          final year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (value) {
                          setState(() => _selectedYear = value!);
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep - 1;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
