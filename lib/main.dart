// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:garage_management_system/firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/job_card_controller.dart';
import 'utils/app_router.dart';
import 'utils/app_theme.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on Android
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Guard duplicate-app error (Android native can auto-init Firebase)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Ensure default admin account exists (runs silently on first launch)
  final firebaseService = FirebaseService();
  await firebaseService.ensureAdminExists();

  runApp(GarageManagementApp(firebaseService: firebaseService));
}

class GarageManagementApp extends StatelessWidget {
  final FirebaseService firebaseService;
  const GarageManagementApp({super.key, required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(firebaseService),
        ),
        ChangeNotifierProvider<JobCardController>(
          create: (_) => JobCardController(firebaseService),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
