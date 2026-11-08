import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

/// Controller managing customer cart state, modifiers, line item pricing,
/// billing totals, and selected payment method.
class CartController extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  String _paymentMethod = 'cash'; // 'cash' or 'advance'
  String _customerName = 'Table Guest';
  String _customerPhone = '';
  final double _taxRate = 0.05; // 5% tax

  List<CartItemModel> get items => List.unmodifiable(_items);
  String get paymentMethod => _paymentMethod;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  double get taxRate => _taxRate;

  int get totalItemCount {
    int count = 0;
    for (final item in _items) {
      count += item.quantity;
    }
    return count;
  }

  double get subtotal {
    double sum = 0.0;
    for (final item in _items) {
      sum += item.totalPrice;
    }
    return sum;
  }

  double get tax => subtotal * _taxRate;

  double get total => subtotal + tax;

  bool get isEmpty => _items.isEmpty;

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setCustomerDetails({required String name, required String phone}) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  /// Adds a product with its selected modifiers into the cart.
  /// If identical product and modifier combination exists, increments quantity.
  void addItem({
    required ProductModel product,
    List<ModifierItem> selectedModifiers = const [],
    int quantity = 1,
    String? notes,
  }) {
    // Check if duplicate exists with same modifiers
    int existingIndex = -1;
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.product.id == product.id && _modifiersMatch(item.selectedModifiers, selectedModifiers)) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        CartItemModel(
          product: product,
          selectedModifiers: List.from(selectedModifiers),
          quantity: quantity,
          notes: notes,
        ),
      );
    }
    notifyListeners();
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool _modifiersMatch(List<ModifierItem> a, List<ModifierItem> b) {
    if (a.length != b.length) return false;
    final aNames = a.map((m) => m.name).toSet();
    final bNames = b.map((m) => m.name).toSet();
    return aNames.containsAll(bNames) && bNames.containsAll(aNames);
  }
}
