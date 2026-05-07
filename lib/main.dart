import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'config/supabase_config.dart';
import 'config/api_config.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_devices_screen.dart';
import 'screens/register_device_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/dev_tools_screen.dart';
import 'screens/officer_dashboard_screen.dart';
import 'screens/device_detail_screen.dart';
import 'widgets/main_wrapper.dart';

void main() async {
  // STEP 1: Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 2: Initialize Storage Service FIRST (uses shared_preferences)
  await StorageService.instance.init();

  // STEP 3: Initialize Supabase AFTER storage
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // STEP 4: Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // STEP 5: Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create services
    final supabaseService = SupabaseService();
    final authService = AuthService(supabaseService);
    final authProvider = AuthProvider(authService);
    
    // API service with platform-specific URL
    // Android emulator: uses 10.0.2.2
    // iOS simulator: uses localhost
    // Physical device: update ApiConfig.baseUrl to your computer's IP
    final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider.value(value: supabaseService),
        Provider.value(value: authService),
        Provider.value(value: apiService),
      ],
      child: MaterialApp.router(
        title: 'SecureGate AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _createRouter(authProvider),
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final currentPath = state.uri.path;
        final userRole = authProvider.currentUser?.role;

        // Public routes
        if (currentPath == '/' ||
            currentPath == '/login' ||
            currentPath == '/register') {
          return null;
        }

        // Profile route - require authentication
        if (currentPath == '/profile' && !isAuthenticated) {
          return '/login';
        }

        // Protected routes - require authentication
        if (!isAuthenticated) {
          return '/login';
        }

        // Role-based routing
        if (currentPath.startsWith('/dashboard') && userRole != 'admin') {
          return '/my-devices';
        }

        if (currentPath.startsWith('/scan') &&
            userRole != 'officer' &&
            userRole != 'admin') {
          return '/my-devices';
        }

        if ((currentPath.startsWith('/my-devices') ||
                currentPath.startsWith('/register-device')) &&
            userRole == 'officer') {
          return '/scan';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainWrapper(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/my-devices',
              builder: (context, state) => const MyDevicesScreen(),
            ),
            GoRoute(
              path: '/register-device',
              builder: (context, state) => const RegisterDeviceScreen(),
            ),
            GoRoute(
              path: '/officer-home',
              builder: (context, state) => const OfficerDashboardScreen(),
            ),
            GoRoute(
              path: '/scan',
              builder: (context, state) => const ScanScreen(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/dev-tools',
              builder: (context, state) => const DevToolsScreen(),
            ),
            GoRoute(
              path: '/device-detail/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return DeviceDetailScreen(deviceId: id);
              },
            ),
          ],
        ),
      ],
    );
  }
}
