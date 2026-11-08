import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/store_binding_controller.dart';
import '../../models/order_model.dart';
import 'tracking_screen.dart';

/// Screen 3 from reference_screen.jpg:
/// "آپ کا کارٹ / Cart, Simple Billing, Cash/Advance Payment modes, & Call Waiter button"
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showReceiptDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رسید / Order Receipt',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const TrackingScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('Table: ${order.tableNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  'Payment: ${order.paymentMethod.toUpperCase()} (${order.paymentStatus.toUpperCase()})',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    itemBuilder: (_, i) {
                      final itm = order.items[i];
                      final title = itm['title'] ?? 'Item';
                      final qty = itm['quantity'] ?? 1;
                      final price = itm['total_price'] ?? itm['unit_price'] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$qty x $title', style: const TextStyle(fontSize: 13)),
                            Text('Rs. ${(price is num ? price.toDouble() : 0.0).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bill / کل رقم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E88E5)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TrackingScreen()),
                    );
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('آرڈر ٹریک کریں / Track Order Live'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final binding = context.watch<StoreBindingController>();
    final ordersCtrl = context.watch<OrdersController>();
    final store = binding.activeStore;
    final tableNumber = binding.activeTableNumber;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('آپ کا کارٹ / Cart (Table $tableNumber)'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear Cart',
              onPressed: () => cart.clearCart(),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'آپ کا کارٹ خالی ہے\nYour cart is empty',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('مینو دیکھیں / View Menu'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Items Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'منتخب اشیاء / Items (${cart.totalItemCount})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Table $tableNumber',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E88E5)),
                              ),
                            ],
                          ),
                          const Divider(),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cart.items.length,
                            separatorBuilder: (_, __) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (item.selectedModifiers.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.selectedModifiers.map((m) => m.name).join(', '),
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                          ),
                                        ],
                                        if (item.notes != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'نوٹ: ${item.notes}',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E88E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Stepper matching Screen 3: - 1 + and Trash
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () => cart.decrementQuantity(index),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () => cart.incrementQuantity(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => cart.removeItem(index),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bill Summary Card matching Screen 3: Subtotal, Tax, Total
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بل کی تفصیل / Bill Summary',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal / ذیلی کل'),
                              Text('Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax / Service (5%)'),
                              Text('Rs. ${cart.tax.toStringAsFixed(0)}'),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total / کل رقم',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              Text(
                                'Rs. ${cart.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment Mode Selector matching requirements
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'طریقہ ادائیگی / Payment Mode',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<String>(
                            value: 'cash',
                            groupValue: cart.paymentMethod,
                            title: const Text('کاؤنٹر پر نقد ادائیگی (Cash on Table / Counter)'),
                            subtitle: const Text('کھانے کے بعد یا ڈلیوری پر نقد ادا کریں'),
                            onChanged: (val) {
                              if (val != null) cart.setPaymentMethod(val);
                            },
                          ),
                          RadioListTile<String>(
                            value: 'advance',
                            groupValue: cart.paymentMethod,
                            title: const Text('آن لائن / پیشگی ادائیگی (Advance Payment)'),
                            subtitle: const Text('کارڈ یا آن لائن موبائل والٹ سے ادا شدہ'),
                            onChanged: (val) {
                              if (val != null) cart.setPaymentMethod(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Prominent "Call Waiter" Button matching Screen 3: "Call Waiter / ویٹر کو بلائیں 🔔"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (store != null) {
                        final success = await ordersCtrl.triggerWaiterCall(
                          storeId: store.id,
                          tableNumber: tableNumber,
                        );
                        if (context.mounted && success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ٹیبل $tableNumber کے لیے ویٹر کو بلا لیا گیا ہے! 🔔'),
                              backgroundColor: Colors.amber.shade900,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.notifications_active),
                    label: const Text(
                      'Call Waiter / ویٹر کو بلائیں 🔔',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Place Order Button matching Screen 3: "Place Order / آرڈر کی تصدیق کریں"
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: ordersCtrl.isSubmitting
                        ? null
                        : () async {
                            if (store == null) return;
                            final order = await ordersCtrl.placeCartOrder(
                              storeId: store.id,
                              tableNumber: tableNumber,
                              customerName: 'Table $tableNumber Guest',
                              customerPhone: '+923000000000',
                              cartItems: cart.items,
                              totalAmount: cart.total,
                              paymentMethod: cart.paymentMethod,
                            );

                            if (context.mounted && order != null) {
                              cart.clearCart();
                              _showReceiptDialog(context, order);
                            }
                          },
                    child: ordersCtrl.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Place Order / آرڈر کی تصدیق کریں',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
