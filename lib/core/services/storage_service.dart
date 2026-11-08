import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/store_model.dart';
import '../../models/product_model.dart';

/// Service abstraction for persisting local device binding state and offline caching.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Factory creator that obtains the SharedPreferences singleton.
  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  /// Persists active store data and store ID to local device storage.
  Future<void> saveBoundStore(StoreModel store, {String? tableNumber}) async {
    final jsonString = jsonEncode(store.toJson());
    await _prefs.setString(AppConstants.keyBoundStoreId, store.id);
    await _prefs.setString(AppConstants.keyBoundStoreCode, store.storeCode);
    await _prefs.setString(AppConstants.keyBoundStoreData, jsonString);
    if (tableNumber != null && tableNumber.isNotEmpty) {
      await _prefs.setString(AppConstants.keyBoundTableNumber, tableNumber);
    }
  }

  /// Saves table number
  Future<void> saveBoundTableNumber(String tableNumber) async {
    await _prefs.setString(AppConstants.keyBoundTableNumber, tableNumber);
  }

  /// Retrieves the bound table number, defaulting to '01'
  String getBoundTableNumber() {
    return _prefs.getString(AppConstants.keyBoundTableNumber) ?? '01';
  }

  /// Retrieves the bound store ID from cache if present.
  String? getBoundStoreId() {
    return _prefs.getString(AppConstants.keyBoundStoreId);
  }

  /// Retrieves the bound store code from cache if present.
  String? getBoundStoreCode() {
    return _prefs.getString(AppConstants.keyBoundStoreCode);
  }

  /// Loads and parses the cached StoreModel if present.
  StoreModel? getBoundStore() {
    final jsonString = _prefs.getString(AppConstants.keyBoundStoreData);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      return StoreModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Offline caching for Menu Screen products
  Future<void> saveCachedMenu(List<ProductModel> products) async {
    final list = products.map((p) => p.toJson()).toList();
    await _prefs.setString(AppConstants.keyCachedMenuData, jsonEncode(list));
  }

  /// Loads cached menu products when offline
  List<ProductModel> getCachedMenu() {
    final jsonString = _prefs.getString(AppConstants.keyCachedMenuData);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Stores currently tracked active order ID
  Future<void> saveActiveOrderId(String orderId) async {
    await _prefs.setString(AppConstants.keyActiveOrderId, orderId);
  }

  String? getActiveOrderId() {
    return _prefs.getString(AppConstants.keyActiveOrderId);
  }

  Future<void> clearActiveOrderId() async {
    await _prefs.remove(AppConstants.keyActiveOrderId);
  }

  /// Clears stored restaurant binding information (unbind / reset).
  Future<void> clearBoundStore() async {
    await _prefs.remove(AppConstants.keyBoundStoreId);
    await _prefs.remove(AppConstants.keyBoundStoreCode);
    await _prefs.remove(AppConstants.keyBoundStoreData);
    await _prefs.remove(AppConstants.keyBoundTableNumber);
    await _prefs.remove(AppConstants.keyCachedMenuData);
    await _prefs.remove(AppConstants.keyActiveOrderId);
  }
}
