import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/store_binding_controller.dart';

/// Screen displayed when the client app has not yet been bound to a restaurant tenant.
/// Allows entering a store_code or tapping quick demo codes.
class StoreLookupScreen extends StatefulWidget {
  const StoreLookupScreen({super.key});

  @override
  State<StoreLookupScreen> createState() => _StoreLookupScreenState();
}

class _StoreLookupScreenState extends State<StoreLookupScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode(String code) {
    if (code.trim().isEmpty) return;
    final controller = context.read<StoreBindingController>();
    controller.bindByStoreCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StoreBindingController>();
    final isChecking = controller.status == StoreBindingStatus.checkingStartup;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrderSystem - Store Binding'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 72,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'White-Label Store Setup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your restaurant store code or scan the QR code to bind this app instance to your business.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Store Code',
                        hintText: 'e.g. BURGER01',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a store code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (controller.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          controller.errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: isChecking
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _submitCode(_codeController.text);
                              }
                            },
                      child: isChecking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Bind Store'),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Quick Demo Codes (From Seed Migration):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.lunch_dining, size: 16),
                          label: const Text('BURGER01 (Active)'),
                          onPressed: isChecking
                              ? null
                              : () => _submitCode('BURGER01'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.local_pizza, size: 16),
                          label: const Text('PIZZA01 (Active)'),
                          onPressed: isChecking
                              ? null
                              : () => _submitCode('PIZZA01'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.lock, size: 16, color: Colors.red),
                          label: const Text('LOCKED01 (Suspended Test)'),
                          onPressed: isChecking
                              ? null
                              : () => _submitCode('LOCKED01'),
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
    );
  }
}
