import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
import '../models/product_model.dart';

/// Controller managing product catalog fetching strictly for the bound store tenant,
/// offline menu caching (shared_preferences), and live inventory availability toggles.
class ProductsController extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final StorageService? _storageService;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  ProductsController({
    required SupabaseService supabaseService,
    StorageService? storageService,
  })  : _supabaseService = supabaseService,
        _storageService = storageService;

  List<ProductModel> get products {
    if (_searchQuery.trim().isEmpty) {
      return _products;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _products.where((p) {
      return p.title.toLowerCase().contains(q) ||
          (p.description != null && p.description!.toLowerCase().contains(q)) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Loads products filtered strictly by the bound store_id.
  /// Uses offline cache first if available for instantaneous UX.
  Future<void> loadProductsForStore(String storeId) async {
    // 1. Instant offline cache population
    if (_storageService != null && _products.isEmpty) {
      final cached = _storageService.getCachedMenu();
      if (cached.isNotEmpty) {
        _products = cached.where((p) => p.storeId == storeId || p.storeId.isEmpty).toList();
        notifyListeners();
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteProducts = await _supabaseService.fetchProductsByStoreId(storeId);
      _products = remoteProducts;

      // 2. Persist to offline cache
      if (_storageService != null) {
        await _storageService.saveCachedMenu(remoteProducts);
      }
    } catch (e) {
      debugPrint('[ProductsController] Error fetching products: $e');
      if (_products.isEmpty) {
        _errorMessage = 'Failed to load products: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Live Inventory Toggle: updates availability in Supabase and locally.
  /// When set to false, displays "ابھی دستیاب نہیں ہے" and locks customer addition.
  Future<bool> toggleProductAvailability(String productId, bool isAvailable) async {
    try {
      final updated = await _supabaseService.updateProductAvailability(productId, isAvailable);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updated;
        if (_storageService != null) {
          await _storageService.saveCachedMenu(_products);
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[ProductsController] Error toggling product availability: $e');
      return false;
    }
  }

  /// Clears products when switching or unbinding stores
  void clear() {
    _products = [];
    _isLoading = false;
    _errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }
}
