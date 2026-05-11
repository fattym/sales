import 'dart:ui' as ui;
import 'core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'core/config/supabase_config.dart';
import 'features/welcome/welcome_page.dart';
import 'features/welcome/auth/login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'features/welcome/auth/admin_login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const DeHeusApp());
}

class DeHeusApp extends StatelessWidget {
  const DeHeusApp({super.key, this.useRemoteHeroImage = true});

  final bool useRemoteHeroImage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Longhorn Publishers PLC',
      debugShowCheckedModeBanner: false,
      initialRoute: ui.PlatformDispatcher.instance.defaultRouteName,
      routes: {
        '/': (_) => const WelcomePage(),
        '/login': (_) => const DeHeusLogin(),
        '/admin-login': (_) => const AdminLoginPage(),
        '/admin': (_) => const AdminDashboardPage(),
      },

      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: const Color(0xFFF6F3F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.longhornMaroon,
          tertiary: AppColors.sageGreyGreen,
          surface: const Color(0xFFFDFBF9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.charcoalGrey),
          bodyMedium: TextStyle(color: AppColors.charcoalGrey),
        ),
      ),
    );
  }
}
