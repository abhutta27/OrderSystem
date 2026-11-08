import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/products_controller.dart';
import '../../controllers/store_binding_controller.dart';
import '../../models/product_model.dart';

/// Screen from reference_screen.jpg:
/// "Merchant - Inventory Status (Manage Products)" with live "ابھی دستیاب نہیں ہے" Supabase toggle.
class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsCtrl = context.watch<ProductsController>();
    final binding = context.watch<StoreBindingController>();
    final store = binding.activeStore;
    final products = productsCtrl.products;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('مصنوعات کی دستیابی (Inventory)'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (store != null) {
                productsCtrl.loadProductsForStore(store.id);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ٹاکل سوئچ سے کسی بھی آئٹم کو لائیو دستیاب یا "ابھی دستیاب نہیں ہے" سیٹ کریں۔ یہ تبدیلیاں فوری طور پر تمام صارفین کے مینو پر لاگو ہوں گی۔',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Search Bar matching reference screen: "مصنوعات تلاش کریں"
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => productsCtrl.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'مصنوعات تلاش کریں / Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          productsCtrl.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          // Products list with live switches
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'کوئی مصنوعات نہیں ملیں / No items found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final item = products[index];
                      return _buildInventoryRow(context, item, productsCtrl);
                    },
                  ),
          ),
          // Bottom Status Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمام تبدیلیاں لائیو ڈیٹا بیس سے منسلک اور محفوظ ہیں۔'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'حتمی دستیابی محفوظ کریں / Save & Close',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(
    BuildContext context,
    ProductModel item,
    ProductsController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isAvailable ? Colors.grey.shade200 : Colors.red.shade200,
        ),
      ),
      elevation: 0,
      color: item.isAvailable ? Colors.white : Colors.red.shade50.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: Colors.grey),
                      )
                    : const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 14),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: item.isAvailable ? Colors.black87 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E88E5)),
                  ),
                  const SizedBox(height: 4),
                  // Availability label matching reference: "دستیاب" vs "ابھی دستیاب نہیں ہے"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isAvailable ? Colors.green.shade50 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isAvailable ? 'دستیاب (Available)' : 'ابھی دستیاب نہیں ہے (Unavailable)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? Colors.green.shade800 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Live Toggle Switch
            Switch(
              value: item.isAvailable,
              activeColor: const Color(0xFF1E88E5),
              activeTrackColor: const Color(0xFF1E88E5).withValues(alpha: 0.4),
              inactiveThumbColor: Colors.red.shade400,
              inactiveTrackColor: Colors.red.shade100,
              onChanged: (bool newVal) async {
                final success = await controller.toggleProductAvailability(item.id, newVal);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newVal
                            ? '${item.title} اب دستیاب ہے! (Available)'
                            : '${item.title} کو "ابھی دستیاب نہیں ہے" نشان زد کر دیا گیا۔',
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: newVal ? Colors.green : Colors.red.shade800,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
