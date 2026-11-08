/// Application-wide constants for OrderSystem
class AppConstants {
  // Storage keys for SharedPreferences
  static const String keyBoundStoreId = 'ordersystem_bound_store_id';
  static const String keyBoundStoreCode = 'ordersystem_bound_store_code';
  static const String keyBoundTableNumber = 'ordersystem_bound_table_number';
  static const String keyBoundStoreData = 'ordersystem_bound_store_json';
  static const String keyCachedMenuData = 'ordersystem_cached_menu_json';
  static const String keyActiveOrderId = 'ordersystem_active_order_id';

  // Default white-label branding fallback colors
  static const String defaultPrimaryColor = '#1E88E5'; // Vibrant Blue
  static const String defaultSecondaryColor = '#FF9800'; // Amber

  // Allowed Order Types
  static const String orderTypeDineIn = 'dine_in';
  static const String orderTypeDelivery = 'delivery';
  static const String orderTypeTakeaway = 'takeaway';

  // Allowed Order Statuses (Ordered State Machine)
  static const String orderStatusPending = 'pending';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Methods
  static const String paymentMethodCash = 'cash';
  static const String paymentMethodAdvance = 'advance';
}
