import 'package:flutter_test/flutter_test.dart';
import 'package:order_system/models/store_model.dart';
import 'package:order_system/models/product_model.dart';
import 'package:order_system/models/cart_item_model.dart';
import 'package:order_system/models/order_model.dart';
import 'package:order_system/models/waiter_call_model.dart';

void main() {
  group('Data Models & JSON Serialization Tests', () {
    test('StoreModel serialization & deserialization with isBusy', () {
      final now = DateTime.parse('2026-11-08T00:00:00.000Z');
      final originalStore = StoreModel(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Burger & Pizza House',
        slug: 'burger-pizza-house',
        storeCode: 'FAST123',
        logoUrl: 'https://example.com/logo.png',
        primaryColor: '#1E88E5',
        secondaryColor: '#FF9800',
        isActive: true,
        isBusy: true,
        createdAt: now,
      );

      final json = originalStore.toJson();
      expect(json['id'], '11111111-1111-1111-1111-111111111111');
      expect(json['store_code'], 'FAST123');
      expect(json['is_active'], true);
      expect(json['is_busy'], true);

      final deserialized = StoreModel.fromJson(json);
      expect(deserialized.id, originalStore.id);
      expect(deserialized.name, originalStore.name);
      expect(deserialized.storeCode, originalStore.storeCode);
      expect(deserialized.isBusy, true);
      expect(deserialized.primaryColorObject.toARGB32(), 0xFF1E88E5);
    });

    test('ProductModel serialization & deserialization with modifiers', () {
      final now = DateTime.parse('2026-11-08T00:00:00.000Z');
      final product = ProductModel(
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-111111111111',
        storeId: '11111111-1111-1111-1111-111111111111',
        title: 'Zinger Burger (No Onion)',
        description: 'Crispy fried chicken',
        price: 450.0,
        imageUrl: 'https://example.com/zinger.png',
        isAvailable: true,
        category: 'Burgers',
        modifiers: const [
          ModifierItem(name: 'Extra Cheese', price: 50.0),
          ModifierItem(name: 'Coke 345ml', price: 80.0),
        ],
        createdAt: now,
      );

      final json = product.toJson();
      expect(json['category'], 'Burgers');
      expect((json['modifiers'] as List).length, 2);

      final deserialized = ProductModel.fromJson(json);
      expect(deserialized.id, product.id);
      expect(deserialized.title, 'Zinger Burger (No Onion)');
      expect(deserialized.category, 'Burgers');
      expect(deserialized.modifiers.length, 2);
      expect(deserialized.modifiers.first.name, 'Extra Cheese');
      expect(deserialized.modifiers.first.price, 50.0);
    });

    test('CartItemModel pricing calculations with modifiers', () {
      final product = ProductModel(
        id: 'p1',
        storeId: 's1',
        title: 'Zinger Burger',
        price: 450.0,
        createdAt: DateTime.now(),
      );

      final cartItem = CartItemModel(
        product: product,
        selectedModifiers: const [
          ModifierItem(name: 'Extra Cheese', price: 50.0),
          ModifierItem(name: 'Coke 345ml', price: 80.0),
        ],
        quantity: 2,
      );

      // Base: 450 + 50 + 80 = 580 unit price
      expect(cartItem.unitPrice, 580.0);
      // Total: 580 * 2 = 1160
      expect(cartItem.totalPrice, 1160.0);
    });

    test('OrderModel serialization & deserialization with table and payment fields', () {
      final now = DateTime.parse('2026-11-08T00:00:00.000Z');
      final order = OrderModel(
        id: 'ord-101',
        storeId: '11111111-1111-1111-1111-111111111111',
        customerName: 'Table 04 Guest',
        customerPhone: '+923001234567',
        deliveryAddress: 'Table 04 - Dine In',
        totalAmount: 1600.0,
        orderType: 'delivery',
        status: 'pending',
        tableNumber: '04',
        items: const [
          {'title': 'Zinger Burger', 'quantity': 1, 'price': 500.0}
        ],
        paymentMethod: 'cash',
        paymentStatus: 'unpaid',
        createdAt: now,
      );

      final json = order.toJson();
      expect(json['table_number'], '04');
      expect(json['payment_method'], 'cash');
      expect(json['payment_status'], 'unpaid');

      final deserialized = OrderModel.fromJson(json);
      expect(deserialized.id, 'ord-101');
      expect(deserialized.tableNumber, '04');
      expect(deserialized.paymentMethod, 'cash');
      expect(deserialized.paymentStatus, 'unpaid');
    });

    test('WaiterCallModel serialization & deserialization', () {
      final now = DateTime.parse('2026-11-08T00:00:00.000Z');
      final call = WaiterCallModel(
        id: 'call-1',
        storeId: '11111111-1111-1111-1111-111111111111',
        tableNumber: '04',
        status: 'pending',
        createdAt: now,
      );

      final json = call.toJson();
      expect(json['table_number'], '04');
      expect(json['status'], 'pending');

      final deserialized = WaiterCallModel.fromJson(json);
      expect(deserialized.id, 'call-1');
      expect(deserialized.tableNumber, '04');
      expect(deserialized.status, 'pending');
    });
  });
}
