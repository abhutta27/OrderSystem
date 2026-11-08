import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/products_controller.dart';
import '../../controllers/store_binding_controller.dart';
import '../../models/product_model.dart';
import '../widgets/product_card.dart';
import 'order_history_screen.dart';

/// Main screen displaying the bound restaurant catalog and tenant controls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final store = context.read<StoreBindingController>().activeStore;
    if (store != null) {
      context.read<ProductsController>().loadProductsForStore(store.id);
    }
  }

  void _showOrderDialog(ProductModel product) {
    final nameController = TextEditingController(text: 'John Doe');
    final phoneController = TextEditingController(text: '+1 555-0199');
    final addressController =
        TextEditingController(text: '123 Market Street, Apt 4B');
    String selectedOrderType = 'delivery';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Order: ${product.title}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price: \$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedOrderType,
                      decoration: const InputDecoration(
                        labelText: 'Order Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'delivery',
                          child: Text('Delivery'),
                        ),
                        DropdownMenuItem(
                          value: 'takeaway',
                          child: Text('Takeaway'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedOrderType = val;
                          });
                        }
                      },
                    ),
                    if (selectedOrderType == 'delivery') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final store =
                        context.read<StoreBindingController>().activeStore;
                    if (store == null) return;

                    Navigator.of(dialogContext).pop();

                    final order =
                        await context.read<OrdersController>().placeOrder(
                              storeId: store.id,
                              customerName: nameController.text.trim(),
                              customerPhone: phoneController.text.trim(),
                              deliveryAddress: selectedOrderType == 'delivery'
                                  ? addressController.text.trim()
                                  : null,
                              totalAmount: product.price,
                              orderType: selectedOrderType,
                            );

                    if (!context.mounted) return;

                    if (order != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order placed successfully for ${store.name}!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      final error = context.read<OrdersController>().errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Failed to place order'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bindingController = context.watch<StoreBindingController>();
    final productsController = context.watch<ProductsController>();
    final store = bindingController.activeStore;

    if (store == null) {
      return const Scaffold(
        body: Center(child: Text('No store bound.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
        backgroundColor: store.primaryColorObject,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialThemePageRoute(
                  builder: (_) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Verify License / Status',
            onPressed: () {
              bindingController.refreshStoreStatus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Unbind Store',
            onPressed: () {
              bindingController.unbindStore();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tenant Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: store.primaryColorObject.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: store.primaryColorObject.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Store Code: ${store.storeCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active License',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Slug: /${store.slug} | Tenant ID: ${store.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Product Catalog List
          Expanded(
            child: productsController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productsController.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(productsController.errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : productsController.products.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found for this store.\nCheck database seed or add items.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadData(),
                            child: ListView.builder(
                              itemCount: productsController.products.length,
                              itemBuilder: (context, index) {
                                final product =
                                    productsController.products[index];
                                return ProductCard(
                                  product: product,
                                  onOrderPressed: () =>
                                      _showOrderDialog(product),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class MaterialThemePageRoute<T> extends MaterialPageRoute<T> {
  MaterialThemePageRoute({required super.builder});
}
