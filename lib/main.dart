import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/introduction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/register_screen.dart';
import 'screens/salon_onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final loggedIn = await apiService.isLoggedIn();
  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowDew Partner',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AppRouter(loggedIn: loggedIn),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/salon-onboarding': (context) => const SalonOnboardingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}

class AppRouter extends StatelessWidget {
  final bool loggedIn;
  const AppRouter({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return loggedIn ? const DashboardScreen() : const IntroductionScreen();
  }
}
