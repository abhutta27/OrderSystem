import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/orders_controller.dart';

/// Screen 4 from reference_screen.jpg:
/// "آرڈر ٹریکنگ / Live Order Tracking" with 4-step vertical timeline:
/// 1. آرڈر موصول (Order Received)
/// 2. کچن میں تیار ہو رہا ہے (Preparing in Kitchen)
/// 3. ڈلیوری کے لئے تیار (Ready for Delivery)
/// 4. ڈیلیور ہو گیا (Delivered / Order Complete)
class TrackingScreen extends StatefulWidget {
  final String? orderId;

  const TrackingScreen({super.key, this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersController>().refreshActiveOrder(widget.orderId);
    });
  }

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'accepted':
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersCtrl = context.watch<OrdersController>();
    final order = ordersCtrl.activeOrder ??
        (ordersCtrl.orders.isNotEmpty ? ordersCtrl.orders.first : null);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('آرڈر ٹریکنگ / Order Tracking'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تازہ کریں / Refresh',
            onPressed: () => ordersCtrl.refreshActiveOrder(widget.orderId),
          ),
        ],
      ),
      body: order == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('کوئی فعال آرڈر نہیں ملا / No active order tracked yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('مینو پر جائیں / Back to Menu'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Banner matching Screen 4: "آرڈر مکمل ہو گیا / Order Complete"
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: order.status == 'delivered'
                          ? Colors.green.shade100
                          : const Color(0xFF1E88E5).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: order.status == 'delivered'
                            ? Colors.green.shade300
                            : const Color(0xFF1E88E5).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          order.status == 'delivered'
                              ? 'آرڈر مکمل ہو گیا / Order Complete 🎉'
                              : 'آپ کا آرڈر تیار ہو رہا ہے / In Progress ⏳',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: order.status == 'delivered'
                                ? Colors.green.shade900
                                : const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.id.isNotEmpty ? order.id : "LIVE"} • Table ${order.tableNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Visual Vertical Stepper Timeline matching Screen 4
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      child: Column(
                        children: [
                          _buildTimelineStep(
                            index: 0,
                            currentIndex: _getStatusStepIndex(order.status),
                            titleUrdu: 'آرڈر موصول',
                            titleEng: 'Order Received',
                            icon: Icons.assignment_turned_in,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            index: 1,
                            currentIndex: _getStatusStepIndex(order.status),
                            titleUrdu: 'کچن میں تیار ہو رہا ہے',
                            titleEng: 'Preparing in Kitchen',
                            icon: Icons.kitchen,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            index: 2,
                            currentIndex: _getStatusStepIndex(order.status),
                            titleUrdu: 'ڈلیوری کے لئے تیار',
                            titleEng: 'Ready for Table / Delivery',
                            icon: Icons.delivery_dining,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            index: 3,
                            currentIndex: _getStatusStepIndex(order.status),
                            titleUrdu: 'ڈیلیور ہو گیا',
                            titleEng: 'Order Complete (Delivered)',
                            icon: Icons.check_circle,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Order Items Details matching Screen 4: "آرڈر کی تفصیلات"
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.fastfood, size: 18, color: Color(0xFF1E88E5)),
                              SizedBox(width: 8),
                              Text(
                                'آرڈر کی تفصیلات / Order Summary',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          if (order.items.isEmpty)
                            const Text('1x Standard Menu Items')
                          else
                            ...order.items.map((item) {
                              final title = item['title'] ?? 'Item';
                              final qty = item['quantity'] ?? 1;
                              final price = item['total_price'] ?? item['unit_price'] ?? 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$qty x $title',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${(price is num ? price.toDouble() : 0.0).toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Bill / کل رقم:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ادائیگی: ${order.paymentMethod == 'advance' ? "پیشگی ادا شدہ (Paid Online)" : "کاؤنٹر پر نقد (Cash on Counter)"}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('مزید آرڈر کریں / Order More Items'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required int currentIndex,
    required String titleUrdu,
    required String titleEng,
    required IconData icon,
    required bool isLast,
  }) {
    final isDone = index <= currentIndex;
    final isCurrent = index == currentIndex;

    final color = isDone
        ? (index == 3 ? Colors.green : const Color(0xFF1E88E5))
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator column with icon and vertical connector line
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDone ? Colors.white : color,
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 48,
                color: index < currentIndex ? color : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Step label
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleUrdu,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    color: isDone ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                Text(
                  titleEng,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? Colors.grey.shade700 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
