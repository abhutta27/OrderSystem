import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:order_system/main.dart';
import 'package:order_system/core/services/storage_service.dart';
import 'package:order_system/core/services/supabase_service.dart';
import 'package:order_system/controllers/store_binding_controller.dart';
import 'package:order_system/controllers/products_controller.dart';
import 'package:order_system/controllers/cart_controller.dart';
import 'package:order_system/controllers/orders_controller.dart';

void main() {
  testWidgets('Renders Welcome Screen matching Screen 1 when unbound on initial start',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final supabaseService = SupabaseService();

    final storeBindingController = StoreBindingController(
      storageService: storageService,
      supabaseService: supabaseService,
    );

    await storeBindingController.checkStartupBinding();

    await tester.pumpWidget(
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

    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nOrderSystem'), findsOneWidget);
    expect(find.text('Connect / شروع کریں'), findsOneWidget);
    expect(find.text('QR کوڈ اسکین کریں (Scan QR)'), findsOneWidget);
  });
}
