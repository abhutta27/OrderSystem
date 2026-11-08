import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../errors/app_exception.dart';
import '../../models/store_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../models/waiter_call_model.dart';

/// Database service handling Supabase operations with multi-tenant filtering,
/// live inventory toggles, KDS kitchen orders, and waiter call alerts.
class SupabaseService {
  /// Queries Supabase 'stores' table by unique store_code for binding.
  Future<StoreModel> fetchStoreByCode(String storeCode) async {
    final sanitizedCode = storeCode.trim().toUpperCase();

    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Using mock seed store for code: $sanitizedCode');
      return _getMockStoreByCode(sanitizedCode);
    }

    try {
      final response = await SupabaseConfig.client
          .from('stores')
          .select()
          .eq('store_code', sanitizedCode)
          .maybeSingle();

      if (response == null) {
        throw StoreNotFoundException(sanitizedCode);
      }

      return StoreModel.fromJson(response);
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching store by code: $e');
      throw DatabaseOperationException('Failed to fetch store details', e);
    }
  }

  /// Queries Supabase 'stores' table by store_id for startup license / suspension check.
  Future<StoreModel> fetchStoreById(String storeId) async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Using mock seed store for id: $storeId');
      return _getMockStoreById(storeId);
    }

    try {
      final response = await SupabaseConfig.client
          .from('stores')
          .select()
          .eq('id', storeId)
          .maybeSingle();

      if (response == null) {
        throw StoreNotFoundException(storeId);
      }

      return StoreModel.fromJson(response);
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[SupabaseService] Error checking store status: $e');
      throw DatabaseOperationException('Failed to verify store status', e);
    }
  }

  /// Updates Busy Mode on a store
  Future<StoreModel> updateStoreBusyMode(String storeId, bool isBusy) async {
    if (!SupabaseConfig.isConfigured) {
      final index = _mockStores.indexWhere((s) => s.id == storeId);
      if (index != -1) {
        final updated = _mockStores[index].copyWith(isBusy: isBusy);
        _mockStores[index] = updated;
        return updated;
      }
      throw StoreNotFoundException(storeId);
    }

    try {
      final response = await SupabaseConfig.client
          .from('stores')
          .update({'is_busy': isBusy})
          .eq('id', storeId)
          .select()
          .single();

      return StoreModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error updating busy mode: $e');
      throw DatabaseOperationException('Failed to update busy mode', e);
    }
  }

  /// Queries 'products' table filtered strictly by store_id (Tenant Isolation).
  Future<List<ProductModel>> fetchProductsByStoreId(String storeId) async {
    if (!SupabaseConfig.isConfigured) {
      return _getMockProductsByStoreId(storeId);
    }

    try {
      final List<dynamic> response = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      return response
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching products: $e');
      throw DatabaseOperationException('Failed to fetch products for store', e);
    }
  }

  /// Live Inventory Toggle: updates is_available for a product in Supabase.
  /// Customer menus immediately reflect "ابھی دستیاب نہیں ہے" badge!
  Future<ProductModel> updateProductAvailability(String productId, bool isAvailable) async {
    if (!SupabaseConfig.isConfigured) {
      final index = _mockProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updated = _mockProducts[index].copyWith(isAvailable: isAvailable);
        _mockProducts[index] = updated;
        return updated;
      }
      throw AppException('Product $productId not found in mock store');
    }

    try {
      final response = await SupabaseConfig.client
          .from('products')
          .update({'is_available': isAvailable})
          .eq('id', productId)
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error toggling product availability: $e');
      throw DatabaseOperationException('Failed to update product availability', e);
    }
  }

  /// Inserts a new customer order scoped to the bound store_id.
  Future<OrderModel> createOrder(OrderModel order) async {
    if (!SupabaseConfig.isConfigured) {
      final orderWithId = order.id.isEmpty
          ? order.copyWith(id: 'order-${DateTime.now().millisecondsSinceEpoch}')
          : order;
      _mockOrders.insert(0, orderWithId);
      return orderWithId;
    }

    try {
      final payload = order.toJson(includeId: false);
      final response = await SupabaseConfig.client
          .from('orders')
          .insert(payload)
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error creating order: $e');
      throw DatabaseOperationException('Failed to submit order', e);
    }
  }

  /// Retrieves orders filtered strictly by store_id (Tenant Isolation).
  Future<List<OrderModel>> fetchOrdersByStoreId(String storeId) async {
    if (!SupabaseConfig.isConfigured) {
      return _mockOrders.where((o) => o.storeId == storeId).toList();
    }

    try {
      final List<dynamic> response = await SupabaseConfig.client
          .from('orders')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      return response
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching orders: $e');
      throw DatabaseOperationException('Failed to fetch orders for store', e);
    }
  }

  /// Fetches a specific order by ID for live order tracking
  Future<OrderModel> fetchOrderById(String orderId) async {
    if (!SupabaseConfig.isConfigured) {
      try {
        return _mockOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        throw AppException('Order $orderId not found');
      }
    }

    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching order by ID: $e');
      throw DatabaseOperationException('Failed to fetch order details', e);
    }
  }

  /// KDS Dashboard status advancement (pending ➔ preparing ➔ ready ➔ delivered)
  Future<OrderModel> updateOrderStatus(String orderId, String newStatus) async {
    if (!SupabaseConfig.isConfigured) {
      final index = _mockOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updated = _mockOrders[index].copyWith(status: newStatus);
        _mockOrders[index] = updated;
        return updated;
      }
      throw AppException('Order $orderId not found');
    }

    try {
      final response = await SupabaseConfig.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error updating order status: $e');
      throw DatabaseOperationException('Failed to update order status', e);
    }
  }

  /// Call Waiter alert creation
  Future<WaiterCallModel> callWaiter(String storeId, String tableNumber) async {
    final alert = WaiterCallModel(
      id: 'call-${DateTime.now().millisecondsSinceEpoch}',
      storeId: storeId,
      tableNumber: tableNumber,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    if (!SupabaseConfig.isConfigured) {
      _mockWaiterCalls.insert(0, alert);
      return alert;
    }

    try {
      final payload = alert.toJson(includeId: false);
      final response = await SupabaseConfig.client
          .from('waiter_calls')
          .insert(payload)
          .select()
          .single();

      return WaiterCallModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error recording waiter call: $e');
      throw DatabaseOperationException('Failed to send waiter call', e);
    }
  }

  /// Fetches pending waiter calls for KDS Merchant Panel
  Future<List<WaiterCallModel>> fetchActiveWaiterCalls(String storeId) async {
    if (!SupabaseConfig.isConfigured) {
      return _mockWaiterCalls
          .where((c) => c.storeId == storeId && c.status == 'pending')
          .toList();
    }

    try {
      final List<dynamic> response = await SupabaseConfig.client
          .from('waiter_calls')
          .select()
          .eq('store_id', storeId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response
          .map((item) => WaiterCallModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching waiter calls: $e');
      return [];
    }
  }

  /// Resolves a waiter call
  Future<void> resolveWaiterCall(String callId) async {
    if (!SupabaseConfig.isConfigured) {
      final index = _mockWaiterCalls.indexWhere((c) => c.id == callId);
      if (index != -1) {
        _mockWaiterCalls.removeAt(index);
      }
      return;
    }

    try {
      await SupabaseConfig.client
          .from('waiter_calls')
          .update({'status': 'resolved'})
          .eq('id', callId);
    } catch (e) {
      debugPrint('[SupabaseService] Error resolving waiter call: $e');
    }
  }

  // ===========================================================================
  // Mock Seed Data (Reflects reference_screen.jpg and seed.sql)
  // ===========================================================================

  static final List<StoreModel> _mockStores = [
    StoreModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Burger & Pizza House',
      slug: 'burger-pizza-house',
      storeCode: 'FAST123',
      logoUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      primaryColor: '#1E88E5',
      secondaryColor: '#FF9800',
      isActive: true,
      isBusy: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    StoreModel(
      id: '22222222-2222-2222-2222-222222222222',
      name: 'Pizza Planet',
      slug: 'pizza-planet',
      storeCode: 'PIZZA01',
      logoUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      primaryColor: '#388E3C',
      secondaryColor: '#FBC02D',
      isActive: true,
      isBusy: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    StoreModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'Suspended Cafe',
      slug: 'suspended-cafe',
      storeCode: 'LOCKED01',
      logoUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      primaryColor: '#616161',
      secondaryColor: '#9E9E9E',
      isActive: false, // Inactive / remote suspended license
      isBusy: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static final List<ProductModel> _mockProducts = [
    ProductModel(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-111111111111',
      storeId: '11111111-1111-1111-1111-111111111111',
      title: 'Zinger Burger (No Onion)',
      description: 'Crispy fried chicken breast fillet with spicy mayo and shredded iceberg.',
      price: 450.00,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      isAvailable: true,
      category: 'Burgers',
      modifiers: const [
        ModifierItem(name: 'ایکسٹرا پنیر (Extra Cheese)', price: 50.0),
        ModifierItem(name: 'کوک (Coke 345ml)', price: 80.0),
        ModifierItem(name: 'فرائیز (Fries)', price: 120.0),
      ],
      createdAt: DateTime.now(),
    ),
    ProductModel(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-222222222222',
      storeId: '11111111-1111-1111-1111-111111111111',
      title: 'Pizza Large',
      description: 'Artisan hand-tossed dough with fresh mozzarella and herb sauce.',
      price: 950.00,
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
      isAvailable: false, // Showcases "ابھی دستیاب نہیں ہے" badge!
      category: 'Pizza',
      modifiers: const [
        ModifierItem(name: 'ایکسٹرا پنیر (Extra Cheese)', price: 100.0),
        ModifierItem(name: 'ڈپ ساس (Dip Sauce)', price: 50.0),
      ],
      createdAt: DateTime.now(),
    ),
    ProductModel(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-333333333333',
      storeId: '11111111-1111-1111-1111-111111111111',
      title: 'Classic Burger',
      description: 'Grilled Angus beef with cheddar slice, pickles, and sauce.',
      price: 450.00,
      imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400',
      isAvailable: true,
      category: 'Burgers',
      modifiers: const [
        ModifierItem(name: 'ایکسٹرا پنیر (Extra Cheese)', price: 50.0),
        ModifierItem(name: 'کوک (Coke 345ml)', price: 80.0),
      ],
      createdAt: DateTime.now(),
    ),
    ProductModel(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-444444444444',
      storeId: '11111111-1111-1111-1111-111111111111',
      title: 'Coke (1.5L)',
      description: 'Chilled 1.5 liter Coca-Cola bottle.',
      price: 180.00,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400',
      isAvailable: false, // "ابھی دستیاب نہیں ہے"
      category: 'Beverages',
      modifiers: const [],
      createdAt: DateTime.now(),
    ),
  ];

  static final List<OrderModel> _mockOrders = [
    OrderModel(
      id: 'ORD-10492',
      storeId: '11111111-1111-1111-1111-111111111111',
      customerName: 'Table 04 Guest',
      customerPhone: '+923001234567',
      deliveryAddress: 'Table 04 - Dine In',
      totalAmount: 1600.00,
      orderType: 'delivery',
      status: 'pending',
      tableNumber: '04',
      items: [
        {
          'title': 'Zinger Burger',
          'quantity': 1,
          'unit_price': 500.0,
          'selected_modifiers': [{'name': 'Extra Cheese', 'price': 50.0}],
        },
        {
          'title': 'Large Pizza',
          'quantity': 1,
          'unit_price': 1050.0,
          'selected_modifiers': [{'name': 'Extra Cheese', 'price': 100.0}],
        },
      ],
      paymentMethod: 'cash',
      paymentStatus: 'unpaid',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  static final List<WaiterCallModel> _mockWaiterCalls = [
    WaiterCallModel(
      id: 'call-1',
      storeId: '11111111-1111-1111-1111-111111111111',
      tableNumber: '04',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  StoreModel _getMockStoreByCode(String code) {
    try {
      return _mockStores.firstWhere((s) => s.storeCode == code);
    } catch (_) {
      throw StoreNotFoundException(code);
    }
  }

  StoreModel _getMockStoreById(String id) {
    try {
      return _mockStores.firstWhere((s) => s.id == id);
    } catch (_) {
      throw StoreNotFoundException(id);
    }
  }

  List<ProductModel> _getMockProductsByStoreId(String storeId) {
    return _mockProducts.where((p) => p.storeId == storeId).toList();
  }
}
