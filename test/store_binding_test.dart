import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:order_system/core/services/storage_service.dart';
import 'package:order_system/core/services/supabase_service.dart';
import 'package:order_system/controllers/store_binding_controller.dart';
import 'package:order_system/controllers/products_controller.dart';
import 'package:order_system/controllers/cart_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late SupabaseService supabaseService;
  late StoreBindingController bindingController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    supabaseService = SupabaseService();
    bindingController = StoreBindingController(
      storageService: storageService,
      supabaseService: supabaseService,
    );
  });

  group('Store Binding, Table QR & Remote Suspension Tests', () {
    test('Initial startup check with no cache transitions to unbound', () async {
      await bindingController.checkStartupBinding();
      expect(bindingController.status, StoreBindingStatus.unbound);
      expect(bindingController.activeStore, isNull);
    });

    test('Binding with combined QR code (FAST123-T04) extracts store code and table number', () async {
      final success = await bindingController.bindByStoreCode('FAST123-T04');
      expect(success, isTrue);
      expect(bindingController.status, StoreBindingStatus.bound);
      expect(bindingController.activeStore, isNotNull);
      expect(bindingController.activeStore!.storeCode, 'FAST123');
      expect(bindingController.activeStore!.name, 'Burger & Pizza House');
      expect(bindingController.activeTableNumber, '04');
      expect(bindingController.activeStore!.isActive, isTrue);

      // Verify cached in storage
      expect(storageService.getBoundStoreId(), isNotNull);
      expect(storageService.getBoundStoreCode(), 'FAST123');
      expect(storageService.getBoundTableNumber(), '04');
    });

    test('Busy mode toggle updates store state and storage', () async {
      await bindingController.bindByStoreCode('FAST123-T04');
      expect(bindingController.activeStore!.isBusy, isFalse);

      await bindingController.toggleBusyMode(true);
      expect(bindingController.activeStore!.isBusy, isTrue);

      await bindingController.toggleBusyMode(false);
      expect(bindingController.activeStore!.isBusy, isFalse);
    });

    test('Binding with suspended store code (LOCKED01-T01) intercepts and sets status to suspended', () async {
      final success = await bindingController.bindByStoreCode('LOCKED01-T01');
      expect(success, isFalse);
      expect(bindingController.status, StoreBindingStatus.suspended);
      expect(bindingController.activeStore, isNotNull);
      expect(bindingController.activeStore!.storeCode, 'LOCKED01');
      expect(bindingController.activeStore!.isActive, isFalse);
      expect(bindingController.errorMessage, contains('suspended'));
    });

    test('ProductsController loads menu and caches offline', () async {
      final productsCtrl = ProductsController(
        supabaseService: supabaseService,
        storageService: storageService,
      );

      await productsCtrl.loadProductsForStore('11111111-1111-1111-1111-111111111111');
      expect(productsCtrl.products.isNotEmpty, isTrue);
      expect(storageService.getCachedMenu().isNotEmpty, isTrue);
    });

    test('Live Inventory Toggle updates product availability', () async {
      final productsCtrl = ProductsController(
        supabaseService: supabaseService,
        storageService: storageService,
      );

      await productsCtrl.loadProductsForStore('11111111-1111-1111-1111-111111111111');
      final firstProduct = productsCtrl.products.first;
      final initialAvailability = firstProduct.isAvailable;

      final success = await productsCtrl.toggleProductAvailability(firstProduct.id, !initialAvailability);
      expect(success, isTrue);

      final updatedProduct = productsCtrl.products.firstWhere((p) => p.id == firstProduct.id);
      expect(updatedProduct.isAvailable, !initialAvailability);
    });

    test('CartController adds item with modifiers and computes billing', () async {
      final cart = CartController();
      final productsCtrl = ProductsController(
        supabaseService: supabaseService,
        storageService: storageService,
      );

      await productsCtrl.loadProductsForStore('11111111-1111-1111-1111-111111111111');
      final mockProd = productsCtrl.products.firstWhere((p) => p.storeId == '11111111-1111-1111-1111-111111111111');
      cart.addItem(
        product: mockProd,
        selectedModifiers: mockProd.modifiers,
        quantity: 2,
      );

      expect(cart.totalItemCount, 2);
      expect(cart.subtotal > 0, isTrue);
      expect(cart.total > cart.subtotal, isTrue);
    });

    test('Unbinding store clears preferences and resets to unbound', () async {
      await bindingController.bindByStoreCode('FAST123-T04');
      expect(bindingController.isBound, isTrue);

      await bindingController.unbindStore();
      expect(bindingController.status, StoreBindingStatus.unbound);
      expect(bindingController.activeStore, isNull);
      expect(storageService.getBoundStoreId(), isNull);
      expect(storageService.getBoundStoreCode(), isNull);
    });
  });
}
