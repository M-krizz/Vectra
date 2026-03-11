import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/signup_data.dart';

/// Lightweight bridge that wires legacy multi-step signup UI to real backend APIs.
class LegacyOnboardingService {
  LegacyOnboardingService._();

  static final SecureStorageService _storage = SecureStorageService();
  static final ApiClient _apiClient = ApiClient(storage: _storage);

  static Future<void> submitSignUpData(SignUpData data) async {
    final fullName = data.fullName.trim();
    if (fullName.isNotEmpty) {
      await _completeProfile(fullName);
    }

    await _upsertVehicle(data);

    if (data.licensePath != null && data.licensePath!.isNotEmpty) {
      await _uploadDocument(
        data.licensePath!,
        'LICENSE',
        webBytes: data.licenseBytes,
        overrideFileName: data.licenseFileName,
      );
    }

    if (data.rcBookPath != null && data.rcBookPath!.isNotEmpty) {
      await _uploadDocument(
        data.rcBookPath!,
        'RC',
        webBytes: data.rcBookBytes,
        overrideFileName: data.rcBookFileName,
      );
    }
  }

  static Future<void> _completeProfile(String fullName) async {
    await _apiClient.patch(
      ApiEndpoints.completeProfile,
      data: {'fullName': fullName},
    );
  }

  static Future<void> _upsertVehicle(SignUpData data) async {
    final hasVehicle =
        data.vehicleType.trim().isNotEmpty ||
        data.vehicleBrand.trim().isNotEmpty ||
        data.vehicleModel.trim().isNotEmpty ||
        data.vehicleNumber.trim().isNotEmpty;

    if (!hasVehicle) return;

    await _apiClient.post(
      ApiEndpoints.driverVehicles,
      data: {
        // Send both modern and fallback keys for backend compatibility.
        'type': data.vehicleType,
        'vehicleType': data.vehicleType,
        'brand': data.vehicleBrand,
        'model': data.vehicleModel,
        'plateNumber': data.vehicleNumber,
        'vehicleNumber': data.vehicleNumber,
        'color': data.vehicleColor,
        'year': data.vehicleYear,
        'isPrimary': true,
      },
    );
  }

  static Future<void> _uploadDocument(
    String path,
    String docType, {
    Uint8List? webBytes,
    String? overrideFileName,
  }) async {
    final fileName = (overrideFileName != null && overrideFileName.isNotEmpty)
        ? overrideFileName
        : _extractFileName(path);
    MultipartFile multipartFile;

    if (kIsWeb) {
      final bytes = webBytes ?? await XFile(path).readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected document is empty: $fileName');
      }
      multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
    } else {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Document file not found: ${file.path}');
      }
      multipartFile = await MultipartFile.fromFile(path, filename: fileName);
    }

    final formData = FormData.fromMap({
      'docType': docType,
      'file': multipartFile,
    });

    await _apiClient.post(
      ApiEndpoints.driverDocumentsUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    ).timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        throw Exception('Document upload timed out. Please try again.');
      },
    );
  }

  static String _extractFileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final last = normalized.split('/').last;
    return last.isEmpty ? 'document.jpg' : last;
  }
}
