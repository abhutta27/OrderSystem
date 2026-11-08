import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/store_binding_controller.dart';
import '../../models/order_model.dart';
import '../widgets/table_qr_dialog.dart';
import 'manage_products_screen.dart';

/// Screen 5 from reference_screen.jpg:
/// "Kitchen Display (KDS) & Merchant Panel (KdsDashboard)" with "Busy Mode" toggle,
/// automated table QR generator (qr_flutter), active orders queue, and waiter call alerts.
class KdsDashboardScreen extends StatefulWidget {
  const KdsDashboardScreen({super.key});

  @override
  State<KdsDashboardScreen> createState() => _KdsDashboardScreenState();
}

class _KdsDashboardScreenState extends State<KdsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKds();
    });
  }

  void _refreshKds() {
    final store = context.read<StoreBindingController>().activeStore;
    if (store != null) {
      context.read<OrdersController>().loadOrdersForStore(store.id);
    }
  }

  void _openQrGenerator() {
    final store = context.read<StoreBindingController>().activeStore;
    if (store != null) {
      showDialog(
        context: context,
        builder: (_) => TableQrDialog(store: store),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = context.watch<StoreBindingController>();
    final ordersCtrl = context.watch<OrdersController>();
    final store = binding.activeStore;

    if (store == null) {
      return const Scaffold(body: Center(child: Text('No active store bound.')));
    }

    final isBusy = store.isBusy;
    final activeOrders = ordersCtrl.orders;
    final waiterCalls = ordersCtrl.activeWaiterCalls;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${store.name} - KDS کچن ڈسپلے'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          // Table QR Generator matching requirements
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Table QR Generator (کیو آر جنریٹر)',
            onPressed: _openQrGenerator,
          ),
          // Manage Inventory Shortcut
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Manage Inventory',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshKds,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Control Bar matching Screen 5: "بزی موڈ (Busy Mode)" Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isBusy ? Colors.amber.shade100 : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Icon(
                  isBusy ? Icons.local_fire_department : Icons.kitchen,
                  color: isBusy ? Colors.red.shade700 : const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBusy ? 'بزی موڈ فعال ہے (Busy Mode ON)' : 'بزی موڈ (Busy Mode)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isBusy ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                      Text(
                        isBusy
                            ? 'کچن میں غیر معمولی رش ہے۔ صارفین کو وارننگ دکھائی جا رہی ہے۔'
                            : 'معمول کا وقت۔ آرڈرز بروقت تیار ہو رہے ہیں۔',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                // Switch matching Screen 5: "بزی موڈ (Busy Mode) [ OFF / ON ]"
                Switch(
                  value: isBusy,
                  activeColor: Colors.red.shade700,
                  activeTrackColor: Colors.red.shade200,
                  onChanged: (val) {
                    binding.toggleBusyMode(val);
                  },
                ),
              ],
            ),
          ),
          // Waiter Call Notification Ribbon
          if (waiterCalls.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade200,
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.black87),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ویٹر کی کال: ٹیبل ${waiterCalls.map((c) => c.tableNumber).join(', ')} کو ویٹر درکار ہے!',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () {
                      for (final call in waiterCalls) {
                        ordersCtrl.resolveWaiterCall(call.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ویٹر کال حل ہو گئی۔ / Waiter call resolved!')),
                      );
                    },
                    child: const Text('حل کریں / Resolve All'),
                  ),
                ],
              ),
            ),
          // Active Orders Display Grid / Columns matching Screen 5
          Expanded(
            child: activeOrders.isEmpty
                ? const Center(
                    child: Text(
                      'فی الحال کوئی نیا آرڈر موجود نہیں ہے\nNo incoming orders right now',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptively choose 1 or 2 columns based on screen width (tablet vs mobile)
                      final isWide = constraints.maxWidth >= 700;
                      final crossAxisCount = isWide ? 3 : (constraints.maxWidth >= 500 ? 2 : 1);

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return _buildKdsOrderCard(context, order, ordersCtrl);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKdsOrderCard(
    BuildContext context,
    OrderModel order,
    OrdersController controller,
  ) {
    final isDelivered = order.status == 'delivered';
    final isReady = order.status == 'ready';
    final isPreparing = order.status == 'preparing' || order.status == 'accepted';
    final isPending = order.status == 'pending';

    Color headerColor = const Color(0xFF1E88E5);
    if (isPreparing) headerColor = Colors.purple.shade700;
    if (isReady) headerColor = Colors.teal.shade700;
    if (isDelivered) headerColor = Colors.green.shade700;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header matching Screen 5: "Table 04 | New Order" / "ٹیبل 04 نیا آرڈر"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: headerColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Table ${order.tableNumber} | ${order.status.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  if (order.items.isEmpty)
                    const Text('1x Fast Food Combo')
                  else
                    ...order.items.map((item) {
                      final title = item['title'] ?? 'Item';
                      final qty = item['quantity'] ?? 1;
                      final mods = (item['selected_modifiers'] is List)
                          ? (item['selected_modifiers'] as List)
                              .map((m) => m is Map ? (m['name'] ?? '') : m.toString())
                              .where((s) => s.isNotEmpty)
                              .join(', ')
                          : '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$qty x $title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (mods.isNotEmpty)
                              Text(
                                '($mods)',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Text(
                    'ادائیگی: ${order.paymentMethod.toUpperCase()} (${order.paymentStatus.toUpperCase()})',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Action Buttons matching Screen 5:
          // "قبول کریں (Accept)" -> "تیار ہو گیا ہے (Ready)" -> "ڈیلیور (Deliver)"
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isPending
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('قبول کریں / Accept'),
                    onPressed: () {
                      controller.advanceOrderStatus(order.id, 'preparing');
                    },
                  )
                : isPreparing
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('تیار ہو گیا ہے / Ready'),
                        onPressed: () {
                          controller.advanceOrderStatus(order.id, 'ready');
                        },
                      )
                    : isReady
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('ڈیلیور / Deliver'),
                            onPressed: () {
                              controller.advanceOrderStatus(order.id, 'delivered');
                            },
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: const Text(
                              'مکمل شدہ / Completed ✅',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
