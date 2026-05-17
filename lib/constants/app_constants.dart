// lib/constants/app_constants.dart
import 'package:flutter/material.dart';

// ─── Cloudinary Config ────────────────────────────────────────────────────────
// Replace these with your actual Cloudinary credentials
// Go to: https://cloudinary.com → Dashboard → Copy Cloud Name, Upload Preset
class CloudinaryConfig {
  static const String cloudName = 'dckndm1tn'; // e.g. 'dxyz123abc'
  static const String uploadPreset = 'garage'; // unsigned upload preset
  static const String baseUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

// ─── Colors ───────────────────────────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF242424);
  static const Color surfaceElevated = Color(0xFF2E2E2E);
  static const Color cardBg = Color(0xFF2A2A2A);
  static const Color border = Color(0xFF3A3A3A);

  static const Color accent = Color(0xFFFFD600);
  static const Color accentLight = Color(0xFFFFE033);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Color pending = Color(0xFFF44336);
  static const Color paid = Color(0xFF4CAF50);
  static const Color partial = Color(0xFFFF9800);
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
  static const TextStyle accent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );
  static const TextStyle monospace = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    color: AppColors.textPrimary,
  );
}

// ─── Routes ───────────────────────────────────────────────────────────────────
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String customerHistory = '/customer-history';
  static const String vehicleEntry = '/vehicle-entry';
  static const String inventoryChecklist = '/inventory-checklist';
  static const String visualInspection = '/visual-inspection';
  static const String mechanicalChecklist = '/mechanical-checklist';
  static const String demandedJobs = '/demanded-jobs';
  static const String summary = '/summary';
  static const String labourBilling = '/labour-billing';
  static const String emiPayment = '/emi-payment';
  static const String authorization = '/authorization';
  static const String reports = '/reports';
  static const String staffManagement = '/staff-management';
}

// ─── Strings ──────────────────────────────────────────────────────────────────
class AppStrings {
  static const String appName = 'AutoServ Pro';
  static const String tagline = 'Workshop Management';

  static const String dashboard = 'Dashboard';
  static const String customerHistory = 'Customer History';
  static const String newJobCard = 'New Job Card';
  static const String inventoryChecklist = 'Inventory';
  static const String visualInspection = 'Visual Inspection';
  static const String mechanicalChecklist = 'Mechanical Check';
  static const String jobsManagement = 'Jobs';
  static const String labourBilling = 'Billing';
  static const String emiPayments = 'EMI Payments';
  static const String authorization = 'Delivery';
  static const String reports = 'Reports';
  static const String staffManagement = 'Staff';
}

// ─── Dimensions ───────────────────────────────────────────────────────────────
class AppDimensions {
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double inputRadius = 8.0;
  static const double padding = 16.0;
  static const double paddingLg = 20.0;
  static const double paddingSm = 8.0;
}
