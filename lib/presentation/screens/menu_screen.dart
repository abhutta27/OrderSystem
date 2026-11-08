import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/products_controller.dart';
import '../../controllers/store_binding_controller.dart';
import '../../models/product_model.dart';
import '../widgets/modifiers_bottom_sheet.dart';
import 'cart_screen.dart';
import 'kds_dashboard_screen.dart';
import 'manage_products_screen.dart';
import 'tracking_screen.dart';

/// Screen 2 from reference_screen.jpg:
/// "ہمارا مینو / Customer Menu & Modifiers" with offline caching (shared_preferences),
/// Table 04 indicator, category selector, modifiers popup, and sticky checkout bar.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenu();
    });
  }

  void _loadMenu() {
    final store = context.read<StoreBindingController>().activeStore;
    if (store != null) {
      context.read<ProductsController>().loadProductsForStore(store.id);
    }
  }

  void _openModifiersSheet(ProductModel product) {
    if (!product.isAvailable) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModifiersBottomSheet(
        product: product,
        onAddToCart: (modifiers, qty, notes) {
          context.read<CartController>().addItem(
                product: product,
                selectedModifiers: modifiers,
                quantity: qty,
                notes: notes,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.title} کارٹ میں شامل کر دیا گیا!'),
              duration: const Duration(milliseconds: 1200),
              backgroundColor: const Color(0xFF1E88E5),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final binding = context.watch<StoreBindingController>();
    final productsCtrl = context.watch<ProductsController>();
    final cart = context.watch<CartController>();
    final store = binding.activeStore;

    if (store == null) {
      return const Scaffold(body: Center(child: Text('No store bound.')));
    }

    final categories = ['All', 'Burgers', 'Pizza', 'Beverages'];
    final allProducts = productsCtrl.products;
    final filteredProducts = _selectedCategory == 'All'
        ? allProducts
        : allProducts.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'ہمارا مینو / Our Menu',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Table indicator matching Screen 2: "ٹیبل: 04"
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white70),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_restaurant, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'ٹیبل: ${binding.activeTableNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          // Active order tracking shortcut
          IconButton(
            icon: const Icon(Icons.local_shipping_outlined),
            tooltip: 'آرڈر ٹریکنگ / Track Order',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrackingScreen()),
              );
            },
          ),
          // Merchant tools popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'kds') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KdsDashboardScreen()));
              } else if (val == 'inventory') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManageProductsScreen()));
              } else if (val == 'waiter') {
                context.read<OrdersController>().triggerWaiterCall(
                      storeId: store.id,
                      tableNumber: binding.activeTableNumber,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ویٹر کو مطلع کر دیا گیا ہے! / Waiter called!')),
                );
              } else if (val == 'unbind') {
                binding.unbindStore();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'waiter', child: Text('🔔 Call Waiter / ویٹر بلائیں')),
              const PopupMenuItem(value: 'kds', child: Text('👨‍🍳 Kitchen KDS Dashboard')),
              const PopupMenuItem(value: 'inventory', child: Text('📦 Manage Products (Live Toggle)')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'unbind', child: Text('🚪 Exit Store')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Busy Mode Warning Banner if isBusy == true
          if (store.isBusy)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بزی موڈ فعال ہے: کچن میں رش کی وجہ سے آرڈر میں کچھ وقت لگ سکتا ہے۔',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => productsCtrl.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'مصنوعات تلاش کریں / Search menu items...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          // Category Selector Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1E88E5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Product List
          Expanded(
            child: productsCtrl.isLoading && allProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'کوئی پروڈکٹ دستیاب نہیں ہے\nNo products found',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadMenu(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90, top: 4),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Sticky Bottom Cart Bar matching Screen 2: "کل کارٹ / Checkout / Rs. 1,000"
      bottomSheet: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cart.totalItemCount} آئٹمز',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text(
                        'کل کارٹ / Checkout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rs. ${cart.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: Colors.grey),
                      )
                    : const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      // Availability or Add Button
                      if (!product.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'ابھی دستیاب نہیں ہے',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _openModifiersSheet(product),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
