/// Represents an alert from a customer table requesting a waiter.
class WaiterCallModel {
  final String id;
  final String storeId;
  final String tableNumber;
  final String status; // 'pending', 'resolved'
  final DateTime createdAt;

  WaiterCallModel({
    required this.id,
    required this.storeId,
    required this.tableNumber,
    this.status = 'pending',
    required this.createdAt,
  });

  factory WaiterCallModel.fromJson(Map<String, dynamic> json) {
    return WaiterCallModel(
      id: json['id'] as String? ?? '',
      storeId: json['store_id'] as String? ?? '',
      tableNumber: json['table_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'store_id': storeId,
      'table_number': tableNumber,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
