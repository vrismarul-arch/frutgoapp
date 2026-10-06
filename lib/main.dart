import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'services/auth_service.dart';

import 'screens/get_started_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart' hide AllOrdersScreen;
import 'screens/checkout_screen.dart';
import 'screens/all_orders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );

  // Google Sign-In v7+ requires this to run once, before the first
  // authenticate()/attemptLightweightAuthentication() call, or you get
  // a StateError('instance not initialized').
  try {
    await AuthService.initializeGoogle();
  } catch (e) {
    debugPrint('AuthService.initializeGoogle failed: $e');
  }

  runApp(
    const FrutgoApp(),
  );
}

class FrutgoApp extends StatelessWidget {
  const FrutgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      child: const _AppInitializer(),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  late Future<void> _initialization;

  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    try {
      final prefs = await SharedPreferences.getInstance();

      final hasSeenGetStarted =
          prefs.getBool('has_seen_get_started') ?? false;

      _isFirstLaunch = !hasSeenGetStarted;
    } catch (e) {
      debugPrint('FRUTGO GET STARTED PREF ERROR: $e');
      _isFirstLaunch = false;
    }

    while (authProvider.loading) {
      await Future.delayed(
        const Duration(milliseconds: 50),
      );
    }

    cartProvider.updateAuth(authProvider);

    if (authProvider.isLoggedIn) {
      debugPrint('================================');
      debugPrint('FRUTGO APP START');
      debugPrint('User authenticated');
      debugPrint('Refreshing cart...');
      debugPrint('================================');

      try {
        await cartProvider.refreshCart();

        debugPrint('FRUTGO: Cart refresh completed');
        debugPrint(
          'FRUTGO: ${cartProvider.itemCount} total items',
        );
      } catch (e) {
        debugPrint(
          'FRUTGO: Cart refresh failed: $e',
        );
      }
    } else {
      debugPrint('================================');
      debugPrint('FRUTGO APP START');
      debugPrint('Guest user');
      debugPrint('Cart API skipped');
      debugPrint('================================');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _InitialLoadingScreen(),
          );
        }

        return _FrutgoMaterialApp(
          isFirstLaunch: _isFirstLaunch,
        );
      },
    );
  }
}

class _InitialLoadingScreen extends StatelessWidget {
  const _InitialLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF65B83D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Frutgo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrutgoMaterialApp extends StatelessWidget {
  const _FrutgoMaterialApp({
    required this.isFirstLaunch,
  });

  final bool isFirstLaunch;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Frutgo',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF65B83D),
        ),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),

      initialRoute:
          isFirstLaunch ? '/get-started' : '/splash',

      routes: {
        '/get-started': (_) =>
            const GetStartedScreen(),

        '/splash': (_) =>
            const SplashScreen(),

        '/login': (_) =>
            const LoginScreen(),

        '/home': (_) =>
            const HomeScreen(),

        '/cart': (_) =>
            const CartScreen(),

        '/profile': (_) =>
            const ProfileScreen(),

        '/orders': (_) =>
            const AllOrdersScreen(),

        '/checkout': (_) =>
            const CheckoutScreen(),
      },
    );
  }
}