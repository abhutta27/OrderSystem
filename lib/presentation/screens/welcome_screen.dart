import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/store_binding_controller.dart';
import 'kds_dashboard_screen.dart';
import 'manage_products_screen.dart';

/// Screen 1 from reference_screen.jpg:
/// "Welcome to OrderSystem" - binds store code and table number via text or QR.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _codeController = TextEditingController(text: 'FAST123-T04');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode(String code) {
    if (code.trim().isEmpty) return;
    context.read<StoreBindingController>().bindByStoreCode(code);
  }

  void _showQrPresetsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'کیو آر کوڈ اسکین کریں / Scan QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a simulated Table QR Code from the seed restaurants:',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.lunch_dining)),
                title: const Text('Burger & Pizza House (Table 04)'),
                subtitle: const Text('Code: FAST123-T04 (Active)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _codeController.text = 'FAST123-T04';
                  _submitCode('FAST123-T04');
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.local_pizza)),
                title: const Text('Pizza Planet (Table 02)'),
                subtitle: const Text('Code: PIZZA01-T02 (Busy Mode On)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _codeController.text = 'PIZZA01-T02';
                  _submitCode('PIZZA01-T02');
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.lock, color: Colors.white)),
                title: const Text('Suspended Cafe (Table 01)'),
                subtitle: const Text('Code: LOCKED01-T01 (Remote License Suspended)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _codeController.text = 'LOCKED01-T01';
                  _submitCode('LOCKED01-T01');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StoreBindingController>();
    final isChecking = controller.status == StoreBindingStatus.checkingStartup;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand / Logo Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Header text matching Screen 1
                    const Text(
                      'Welcome to\nOrderSystem',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'خوش آمدید! اپنے ٹیبل کا کیو آر کوڈ اسکین کریں یا اسٹور کوڈ درج کریں۔',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    // Input matching reference
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'FAST123-T04',
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'براہ کرم کوڈ درج کریں / Enter store/table code';
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
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Primary Connect Button matching Screen 1: "Connect / شروع کریں"
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Connect / شروع کریں',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Secondary QR Scan Button matching Screen 1: "QR کوڈ اسکین کریں"
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                        'QR کوڈ اسکین کریں (Scan QR)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: isChecking ? null : _showQrPresetsDialog,
                    ),
                    const SizedBox(height: 36),
                    const Divider(),
                    // Direct access to Merchant Tools for testing
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.dashboard, size: 16),
                          label: const Text('Merchant KDS', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const KdsDashboardScreen()),
                            );
                          },
                        ),
                        const Text('|', style: TextStyle(color: Colors.grey)),
                        TextButton.icon(
                          icon: const Icon(Icons.inventory_2, size: 16),
                          label: const Text('Live Inventory', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                            );
                          },
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
