// lib/utils/app_router.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../views/login_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/customer_history_screen.dart';
import '../views/vehicle_entry_screen.dart';
import '../views/inventory_checklist_screen.dart';
import '../views/visual_inspection_screen.dart';
import '../views/mechanical_checklist_screen.dart';
import '../views/demanded_jobs_screen.dart';
import '../views/labour_billing_screen.dart';
import '../views/emi_payment_screen.dart';
import '../views/authorization_screen.dart';
import '../views/reports_screen.dart';
import '../views/staff_management_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings s) {
    final page = switch (s.name) {
      AppRoutes.login              => const LoginScreen(),
      AppRoutes.dashboard          => const DashboardScreen(),
      AppRoutes.customerHistory    => const CustomerHistoryScreen(),
      AppRoutes.vehicleEntry       => const VehicleEntryScreen(),
      AppRoutes.inventoryChecklist => const InventoryChecklistScreen(),
      AppRoutes.visualInspection   => const VisualInspectionScreen(),
      AppRoutes.mechanicalChecklist=> const MechanicalChecklistScreen(),
      AppRoutes.demandedJobs       => const DemandedJobsScreen(),
      AppRoutes.labourBilling      => const LabourBillingScreen(),
      AppRoutes.emiPayment         => const EmiPaymentScreen(),
      AppRoutes.authorization      => const AuthorizationScreen(),
      AppRoutes.reports            => const ReportsScreen(),
      AppRoutes.staffManagement    => const StaffManagementScreen(),
      _                            => const DashboardScreen(),
    };

    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
