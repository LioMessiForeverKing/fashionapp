import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'background.dart';
import 'pages/login_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'utils/constants.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.kSupabaseUrl,
    anonKey: AppConstants.kSupabaseAnonKey,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Closet Fairy',
      theme: ThemeData(
        fontFamily: AppConstants.secondaryFont,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryBlue,
          primary: AppConstants.primaryBlue,
          secondary: AppConstants.accentCoral,
        ),
        useMaterial3: true,
      ),
      home: const Background(child: AuthWrapper()),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Debug: Check initial auth state
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    // Check initial auth state
    Supabase.instance.client.auth.currentSession;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryBlue,
                ),
              ),
            ),
          );
        }

        final session = snapshot.data?.session;
        // Auth state changed - Session: ${session?.user.email ?? "No session"}

        if (session == null) {
          // User is not authenticated
          // No session found, showing login page
          return const LoginPage();
        }

        // User is authenticated - check if they need onboarding
        return FutureBuilder<bool>(
          future: UserService.hasCompletedOnboarding(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryBlue,
                    ),
                  ),
                ),
              );
            }

            final hasCompletedOnboarding = onboardingSnapshot.data ?? false;
            // Onboarding status: $hasCompletedOnboarding

            if (!hasCompletedOnboarding) {
              // User needs onboarding, showing onboarding page
              return const OnboardingPage();
            }

            // User is authenticated and onboarded
            // User completed onboarding, showing homepage
            return const HomePage();
          },
        );
      },
    );
  }
}
