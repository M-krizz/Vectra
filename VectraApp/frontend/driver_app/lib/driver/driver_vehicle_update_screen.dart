import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DriverVehicleUpdateScreen extends StatefulWidget {
  const DriverVehicleUpdateScreen({super.key});

  @override
  State<DriverVehicleUpdateScreen> createState() => _DriverVehicleUpdateScreenState();
}

class _DriverVehicleUpdateScreenState extends State<DriverVehicleUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _makeController = TextEditingController(text: 'Honda');
  final _modelController = TextEditingController(text: 'City');
  final _yearController = TextEditingController(text: '2020');
  final _colorController = TextEditingController(text: 'Silver');
  final _plateController = TextEditingController(text: 'KA-01-AB-1234');
  
  String _selectedVehicleType = 'Sedan';
  final List<String> _vehicleTypes = ['Bike', 'Sedan', 'SUV'];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle details updated successfully!'),
          backgroundColor: AppColors.hyperLime,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleTypeSelector(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _makeController,
                        label: 'Vehicle Make',
                        icon: Icons.directions_car,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _modelController,
                        label: 'Vehicle Model',
                        icon: Icons.car_rental,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _colorController,
                        label: 'Color',
                        icon: Icons.palette,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _plateController,
                        label: 'License Plate',
                        icon: Icons.credit_card,
                      ),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbonGrey.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.white10),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white10,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Update Vehicle',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildVehicleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Type',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _vehicleTypes.map((type) {
            final isSelected = _selectedVehicleType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.hyperLime.withOpacity(0.2)
                        : AppColors.carbonGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.hyperLime : AppColors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type == 'Bike'
                            ? Icons.two_wheeler
                            : type == 'Sedan'
                                ? Icons.directions_car
                                : Icons.airport_shuttle,
                        color: isSelected ? AppColors.hyperLime : AppColors.white50,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type,
                        style: GoogleFonts.dmSans(
                          color: isSelected ? AppColors.hyperLime : AppColors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.carbonGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.hyperLime),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _handleSave,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.hyperLime, AppColors.neonGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.hyperLime.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.black, size: 24),
            const SizedBox(width: 12),
            Text(
              'Save Changes',
              style: GoogleFonts.dmSans(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
