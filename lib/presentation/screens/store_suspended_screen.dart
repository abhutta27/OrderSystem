import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/store_binding_controller.dart';

/// Screen displayed when the restaurant's license is suspended (is_active == false).
/// Intercepts all routing and operations until reactivated by backend administrator.
class StoreSuspendedScreen extends StatelessWidget {
  const StoreSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StoreBindingController>();
    final storeName = controller.activeStore?.name ?? 'This Store';
    final storeCode = controller.activeStore?.storeCode ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.block,
                          size: 64,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Store Access Suspended',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Store: $storeName ($storeCode)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The ordering license for this restaurant tenant has been suspended or is currently inactive on the central cloud server. All catalog queries and order processing are temporarily halted.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade900),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Set "is_active = true" in the stores table in Supabase to restore live access.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller.unbindStore();
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Change Store'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                controller.refreshStoreStatus();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Verify Status'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
