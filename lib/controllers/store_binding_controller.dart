import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
import '../models/store_model.dart';

/// State of restaurant binding on this client device
enum StoreBindingStatus {
  uninitialized,
  checkingStartup,
  unbound,
  bound,
  suspended,
  error,
}

/// Controller managing tenant binding, table binding, local persistence,
/// and remote suspension verification.
class StoreBindingController extends ChangeNotifier {
  final StorageService _storageService;
  final SupabaseService _supabaseService;

  StoreModel? _activeStore;
  String _activeTableNumber = '01';
  StoreBindingStatus _status = StoreBindingStatus.uninitialized;
  String? _errorMessage;

  StoreBindingController({
    required StorageService storageService,
    required SupabaseService supabaseService,
  })  : _storageService = storageService,
        _supabaseService = supabaseService;

  StoreModel? get activeStore => _activeStore;
  String get activeTableNumber => _activeTableNumber;
  StoreBindingStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isBound => _status == StoreBindingStatus.bound && _activeStore != null;
  bool get isSuspended => _status == StoreBindingStatus.suspended;

  /// Phase 1/2 Startup Check:
  /// Queries the cached store_id against the Supabase database.
  /// If is_active == false, immediately intercepts routing and locks into suspended mode.
  Future<void> checkStartupBinding() async {
    _status = StoreBindingStatus.checkingStartup;
    _errorMessage = null;
    notifyListeners();

    try {
      final cachedStore = _storageService.getBoundStore();
      final cachedStoreId = _storageService.getBoundStoreId();
      _activeTableNumber = _storageService.getBoundTableNumber();

      if (cachedStoreId == null || cachedStore == null) {
        // No restaurant bound on this device yet
        _status = StoreBindingStatus.unbound;
        _activeStore = null;
        notifyListeners();
        return;
      }

      // Query database remotely to verify store status & license state
      debugPrint('[StoreBindingController] Checking remote status for store_id: $cachedStoreId');
      final remoteStore = await _supabaseService.fetchStoreById(cachedStoreId);
      _activeStore = remoteStore;

      // Update local cache with latest branding, busy mode, and status
      await _storageService.saveBoundStore(remoteStore, tableNumber: _activeTableNumber);

      if (!remoteStore.isActive) {
        // License inactive or store suspended!
        debugPrint('[StoreBindingController] Store "${remoteStore.name}" is marked INACTIVE. Suspending.');
        _status = StoreBindingStatus.suspended;
        _errorMessage = 'Store license has been suspended or deactivated.';
      } else {
        _status = StoreBindingStatus.bound;
      }
    } on StoreNotFoundException catch (e) {
      debugPrint('[StoreBindingController] Store no longer exists: $e');
      await _storageService.clearBoundStore();
      _activeStore = null;
      _status = StoreBindingStatus.unbound;
      _errorMessage = 'Previous store was not found in database.';
    } catch (e) {
      debugPrint('[StoreBindingController] Error during startup license check: $e');
      // If network fails, inspect local cached store state
      final cachedStore = _storageService.getBoundStore();
      if (cachedStore != null) {
        _activeStore = cachedStore;
        if (!cachedStore.isActive) {
          _status = StoreBindingStatus.suspended;
          _errorMessage = 'Store license is suspended.';
        } else {
          _status = StoreBindingStatus.bound;
        }
      } else {
        _status = StoreBindingStatus.unbound;
      }
    } finally {
      notifyListeners();
    }
  }

  /// Binds the app to a specific restaurant and table using store_code or combined QR code (e.g. FAST123-T04).
  Future<bool> bindByStoreCode(String inputCode, {String? explicitTable}) async {
    final sanitizedInput = inputCode.trim();
    if (sanitizedInput.isEmpty) {
      _errorMessage = 'براہ کرم اسٹور کوڈ درج کریں۔ / Please enter a valid store code.';
      notifyListeners();
      return false;
    }

    _status = StoreBindingStatus.checkingStartup;
    _errorMessage = null;
    notifyListeners();

    // Parse combined QR code format: STORECODE-TXX or STORECODE-XX
    String parsedStoreCode = sanitizedInput;
    String tableNum = explicitTable?.trim().isNotEmpty == true
        ? explicitTable!.trim()
        : _activeTableNumber;

    if (sanitizedInput.contains('-')) {
      final parts = sanitizedInput.split('-');
      parsedStoreCode = parts[0].trim();
      if (parts.length > 1) {
        tableNum = parts[1].replaceAll(RegExp(r'[^\d]'), '');
        if (tableNum.isEmpty) tableNum = parts[1];
        if (tableNum.length == 1) tableNum = '0$tableNum';
      }
    }

    try {
      final store = await _supabaseService.fetchStoreByCode(parsedStoreCode);
      _activeStore = store;
      _activeTableNumber = tableNum.isEmpty ? '01' : tableNum;

      await _storageService.saveBoundStore(store, tableNumber: _activeTableNumber);

      if (!store.isActive) {
        _status = StoreBindingStatus.suspended;
        _errorMessage = 'Store "${store.name}" is currently suspended.';
        notifyListeners();
        return false;
      }

      _status = StoreBindingStatus.bound;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on StoreNotFoundException catch (e) {
      _status = StoreBindingStatus.unbound;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = StoreBindingStatus.unbound;
      _errorMessage = 'Failed to bind store: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Updates active table number (e.g. from QR scan or table selector)
  Future<void> setTableNumber(String table) async {
    _activeTableNumber = table;
    await _storageService.saveBoundTableNumber(table);
    notifyListeners();
  }

  /// Toggles Busy Mode on the store (for KDS Merchant)
  Future<void> toggleBusyMode(bool isBusy) async {
    if (_activeStore == null) return;
    try {
      final updated = await _supabaseService.updateStoreBusyMode(_activeStore!.id, isBusy);
      _activeStore = updated;
      await _storageService.saveBoundStore(updated, tableNumber: _activeTableNumber);
      notifyListeners();
    } catch (e) {
      debugPrint('[StoreBindingController] Error toggling busy mode: $e');
    }
  }

  /// Refreshes store active status (e.g. from retry button on suspended screen).
  Future<void> refreshStoreStatus() async {
    if (_activeStore == null) {
      await checkStartupBinding();
      return;
    }

    try {
      final remoteStore = await _supabaseService.fetchStoreById(_activeStore!.id);
      _activeStore = remoteStore;
      await _storageService.saveBoundStore(remoteStore, tableNumber: _activeTableNumber);

      if (!remoteStore.isActive) {
        _status = StoreBindingStatus.suspended;
        _errorMessage = 'Store license remains suspended.';
      } else {
        _status = StoreBindingStatus.bound;
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Could not contact database server: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Unbinds the current restaurant, wiping local device cache.
  Future<void> unbindStore() async {
    await _storageService.clearBoundStore();
    _activeStore = null;
    _activeTableNumber = '01';
    _status = StoreBindingStatus.unbound;
    _errorMessage = null;
    notifyListeners();
  }
}
