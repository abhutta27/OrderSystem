/// Represents an order placed against a specific store (store_id) and table.
class OrderModel {
  final String id;
  final String storeId;
  final String customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final double totalAmount;
  final String orderType; // 'delivery' or 'takeaway'
  final String status; // 'pending', 'accepted', 'preparing', 'ready', 'delivered', 'cancelled'
  final String tableNumber; // e.g. '04'
  final List<dynamic> items; // Detailed JSON array of cart items snapshot
  final String paymentMethod; // 'cash' or 'advance'
  final String paymentStatus; // 'unpaid' or 'paid'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.storeId,
    required this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    required this.totalAmount,
    this.orderType = 'delivery',
    this.status = 'pending',
    this.tableNumber = '01',
    this.items = const [],
    this.paymentMethod = 'cash',
    this.paymentStatus = 'unpaid',
    required this.createdAt,
  });

  /// Factory constructor to parse OrderModel from Supabase JSON response
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      storeId: json['store_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'Guest',
      customerPhone: json['customer_phone'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String?,
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : 0.0,
      orderType: json['order_type'] as String? ?? 'delivery',
      status: json['status'] as String? ?? 'pending',
      tableNumber: json['table_number'] as String? ?? '01',
      items: json['items'] is List ? (json['items'] as List) : const [],
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts OrderModel to JSON map for Supabase insertion / query
  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'store_id': storeId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'total_amount': totalAmount,
      'order_type': orderType,
      'status': status,
      'table_number': tableNumber,
      'items': items,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  /// Immutability helper for status transitions
  OrderModel copyWith({
    String? id,
    String? storeId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    double? totalAmount,
    String? orderType,
    String? status,
    String? tableNumber,
    List<dynamic>? items,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeId == other.storeId &&
          status == other.status &&
          tableNumber == other.tableNumber;

  @override
  int get hashCode =>
      id.hashCode ^ storeId.hashCode ^ status.hashCode ^ tableNumber.hashCode;
}
