/// Represents a selectable modifier/add-on for a product (e.g. Extra Cheese Rs. 50)
class ModifierItem {
  final String name;
  final double price;

  const ModifierItem({
    required this.name,
    required this.price,
  });

  factory ModifierItem.fromJson(Map<String, dynamic> json) {
    return ModifierItem(
      name: json['name'] as String? ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => name.hashCode ^ price.hashCode;
}

/// Represents a menu item or product belonging strictly to a single store (store_id).
class ProductModel {
  final String id;
  final String storeId;
  final String title;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final String category;
  final List<ModifierItem> modifiers;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.storeId,
    required this.title,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.category = 'General',
    this.modifiers = const [],
    required this.createdAt,
  });

  /// Factory constructor to parse ProductModel from Supabase JSON response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<ModifierItem> parsedModifiers = [];
    if (json['modifiers'] != null && json['modifiers'] is List) {
      parsedModifiers = (json['modifiers'] as List)
          .map((m) => ModifierItem.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return ProductModel(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      category: json['category'] as String? ?? 'General',
      modifiers: parsedModifiers,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts ProductModel to JSON map for Supabase operations / local cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'title': title,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'category': category,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Immutability helper for product updates
  ProductModel copyWith({
    String? id,
    String? storeId,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    String? category,
    List<ModifierItem>? modifiers,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      modifiers: modifiers ?? this.modifiers,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeId == other.storeId &&
          isAvailable == other.isAvailable &&
          category == other.category;

  @override
  int get hashCode =>
      id.hashCode ^ storeId.hashCode ^ isAvailable.hashCode ^ category.hashCode;
}
