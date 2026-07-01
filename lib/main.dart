// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'utils/app_theme.dart';
import 'utils/malaysia_states.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/event_viewmodel.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'viewmodels/marketplace_viewmodel.dart';
import 'views/admin/admin_main.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/location_setup_screen.dart';
import 'views/auth/organizer_approval_screen.dart';
import 'views/organizer/organizer_main.dart';
import 'views/volunteer/volunteer_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JomImpactApp());
}

class JomImpactApp extends StatelessWidget {
  const JomImpactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => MarketplaceViewModel()),
      ],
      child: MaterialApp(
        title: 'JomImpact',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    // Show splash/loading while restoring Firebase session
    if (authVm.isLoading && !authVm.isLoggedIn) {
      return const _SplashScreen();
    }

    if (!authVm.isLoggedIn) return const LoginScreen();

    final user = authVm.currentUser!;

    if (user.role == UserRole.admin) {
      return const AdminMain();
    }

    if (user.role == UserRole.organizer && !user.isOrganizerApproved) {
      return const OrganizerApprovalScreen();
    }

    if ((user.location?.trim().isEmpty ?? true) ||
        !isMalaysiaState(user.state)) {
      return const LocationSetupScreen();
    }

    return user.role == UserRole.organizer
        ? const OrganizerMain()
        : const VolunteerMain();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: AppTheme.primary, size: 52),
            ),
            const SizedBox(height: 20),
            const Text('JomImpact',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
