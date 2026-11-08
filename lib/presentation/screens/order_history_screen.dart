import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/store_binding_controller.dart';

/// Screen displaying the recent orders submitted strictly to the bound restaurant store.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<StoreBindingController>().activeStore;
      if (store != null) {
        context.read<OrdersController>().loadOrdersForStore(store.id);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreBindingController>().activeStore;
    final ordersController = context.watch<OrdersController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${store?.name ?? "Store"} - Orders'),
        backgroundColor: store?.primaryColorObject,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh orders',
            onPressed: () {
              if (store != null) {
                ordersController.loadOrdersForStore(store.id);
              }
            },
          ),
        ],
      ),
      body: ordersController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ordersController.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(ordersController.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (store != null) {
                              ordersController.loadOrdersForStore(store.id);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ordersController.orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders placed yet for this store.\nUse "Quick Order" on a product to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: ordersController.orders.length,
                      itemBuilder: (context, index) {
                        final order = ordersController.orders[index];
                        final statusColor = _getStatusColor(order.status);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.15),
                              child: Icon(
                                order.orderType == 'delivery'
                                    ? Icons.delivery_dining
                                    : Icons.takeout_dining,
                                color: statusColor,
                              ),
                            ),
                            title: Text(
                              '${order.customerName} (${order.orderType.toUpperCase()})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Phone: ${order.customerPhone}'),
                                if (order.deliveryAddress != null &&
                                    order.deliveryAddress!.isNotEmpty)
                                  Text('Address: ${order.deliveryAddress}'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Status: ${order.status.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '\$${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
