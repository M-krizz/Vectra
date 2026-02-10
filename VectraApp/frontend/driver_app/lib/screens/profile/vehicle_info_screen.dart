import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/signup_data.dart';

class VehicleInfoScreen extends StatefulWidget {
  final SignUpData? signUpData;
  const VehicleInfoScreen({super.key, this.signUpData});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  late SignUpData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.signUpData ?? SignUpData()
      ..vehicleType = 'Bike'
      ..vehicleBrand = 'Honda'
      ..vehicleModel = 'Activa 6G'
      ..vehicleNumber = 'TN 01 AB 1234'
      ..vehicleColor = 'Blue'
      ..vehicleYear = 2023;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Vehicle Details',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildVehicleSummary(
              context,
              type: _data.vehicleType,
              brand: _data.vehicleBrand,
              model: _data.vehicleModel,
              number: _data.vehicleNumber,
              color: _data.vehicleColor,
              year: _data.vehicleYear.toString(),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              title: 'Vehicle Type',
              value: _data.vehicleType,
              icon: Icons.directions_bike,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Brand',
              value: _data.vehicleBrand,
              icon: Icons.branding_watermark,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Model',
              value: _data.vehicleModel,
              icon: Icons.model_training,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Registration Number',
              value: _data.vehicleNumber,
              icon: Icons.pin,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Vehicle Color',
              value: _data.vehicleColor,
              icon: Icons.palette,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: 'Manufacturing Year',
              value: _data.vehicleYear.toString(),
              icon: Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSummary(
    BuildContext context, {
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String year,
  }) {
    // Determine icon based on vehicle type
    IconData vehicleIcon;
    switch (type.toLowerCase()) {
      case 'car':
      case 'suv':
        vehicleIcon = Icons.directions_car;
        break;
      case 'auto rickshaw':
        vehicleIcon = Icons.electric_rickshaw; // Approximate icon
        break;
      case 'bike':
      default:
        vehicleIcon = Icons.motorcycle;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(vehicleIcon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            '$brand $model',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
