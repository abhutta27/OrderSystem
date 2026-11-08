import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'controllers/store_binding_controller.dart';
import 'controllers/products_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/orders_controller.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/menu_screen.dart';
import 'presentation/screens/store_suspended_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Client
  await SupabaseConfig.initialize();

  // 2. Initialize Persistent Local Storage (with offline caching support)
  final storageService = await StorageService.create();

  // 3. Initialize Database Service
  final supabaseService = SupabaseService();

  // 4. Initialize Store Binding Controller and perform remote license/suspension check
  final storeBindingController = StoreBindingController(
    storageService: storageService,
    supabaseService: supabaseService,
  );

  // Trigger app startup check
  await storeBindingController.checkStartupBinding();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StoreBindingController>.value(
          value: storeBindingController,
        ),
        ChangeNotifierProvider<ProductsController>(
          create: (_) => ProductsController(
            supabaseService: supabaseService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider<CartController>(
          create: (_) => CartController(),
        ),
        ChangeNotifierProvider<OrdersController>(
          create: (_) => OrdersController(
            supabaseService: supabaseService,
            storageService: storageService,
          ),
        ),
      ],
      child: const OrderSystemApp(),
    ),
  );
}

class OrderSystemApp extends StatelessWidget {
  const OrderSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bindingController = context.watch<StoreBindingController>();

    return MaterialApp(
      title: 'OrderSystem B2B',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(bindingController.activeStore),
      home: _resolveAppRoot(bindingController),
    );
  }

  /// Evaluates app startup and licensing state machine to determine root screen.
  Widget _resolveAppRoot(StoreBindingController bindingController) {
    switch (bindingController.status) {
      case StoreBindingStatus.checkingStartup:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1E88E5)),
                SizedBox(height: 16),
                Text(
                  'Connecting to OrderSystem & verifying license...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case StoreBindingStatus.suspended:
        // REMOTE SUSPENSION / KILL-SWITCH INTERCEPTION
        // When stores.is_active == false, completely intercept app routing.
        return const StoreSuspendedScreen();

      case StoreBindingStatus.bound:
        // Bound customer menu screen with table indicator, modifiers, and cart
        return const MenuScreen();

      case StoreBindingStatus.unbound:
      case StoreBindingStatus.error:
      case StoreBindingStatus.uninitialized:
        // Screen 1: Welcome Screen & Store/Table QR binding
        return const WelcomeScreen();
    }
  }
}
