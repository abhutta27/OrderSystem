import 'product_model.dart';

/// Represents a line item inside the customer shopping cart.
class CartItemModel {
  final ProductModel product;
  final List<ModifierItem> selectedModifiers;
  int quantity;
  final String? notes;

  CartItemModel({
    required this.product,
    this.selectedModifiers = const [],
    this.quantity = 1,
    this.notes,
  });

  /// Calculates price of a single item including its selected modifiers
  double get unitPrice {
    double modifierTotal = 0.0;
    for (final mod in selectedModifiers) {
      modifierTotal += mod.price;
    }
    return product.price + modifierTotal;
  }

  /// Calculates total price for this cart line item
  double get totalPrice => unitPrice * quantity;

  /// Serialization to JSON map for order snapshot and offline caching
  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'title': product.title,
      'base_price': product.price,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      'notes': notes,
      'selected_modifiers': selectedModifiers.map((m) => m.toJson()).toList(),
    };
  }

  /// Factory constructor to restore from JSON map
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final List<ModifierItem> mods = [];
    if (json['selected_modifiers'] != null && json['selected_modifiers'] is List) {
      for (final m in json['selected_modifiers'] as List) {
        mods.add(ModifierItem.fromJson(m as Map<String, dynamic>));
      }
    }

    final dummyProduct = ProductModel(
      id: json['product_id'] as String? ?? '',
      storeId: '',
      title: json['title'] as String? ?? '',
      price: (json['base_price'] is num)
          ? (json['base_price'] as num).toDouble()
          : (json['unit_price'] is num)
              ? (json['unit_price'] as num).toDouble()
              : 0.0,
      createdAt: DateTime.now(),
    );

    return CartItemModel(
      product: dummyProduct,
      selectedModifiers: mods,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }
}
