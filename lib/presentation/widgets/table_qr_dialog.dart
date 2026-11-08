import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/store_binding_controller.dart';
import '../../models/store_model.dart';

/// Modal dialog for generating and previewing automated Table QR codes using qr_flutter.
class TableQrDialog extends StatefulWidget {
  final StoreModel store;

  const TableQrDialog({super.key, required this.store});

  @override
  State<TableQrDialog> createState() => _TableQrDialogState();
}

class _TableQrDialogState extends State<TableQrDialog> {
  int _selectedTable = 4;

  String get _tableString => _selectedTable < 10 ? '0$_selectedTable' : '$_selectedTable';
  String get _qrPayload => '${widget.store.storeCode}-T$_tableString';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Table QR Generator\nٹیبل کیو آر کوڈ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Restaurant: ${widget.store.name} (${widget.store.storeCode})',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Table selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Select Table / ٹیبل نمبر: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<int>(
                    value: _selectedTable,
                    items: List.generate(20, (i) => i + 1).map((tableNo) {
                      final str = tableNo < 10 ? '0$tableNo' : '$tableNo';
                      return DropdownMenuItem<int>(
                        value: tableNo,
                        child: Text('Table $str'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTable = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // QR Display Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _qrPayload,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                      embeddedImage: null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _qrPayload,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Scan to bind to Table $_tableString',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Simulate Scan'),
                      onPressed: () {
                        context.read<StoreBindingController>().bindByStoreCode(_qrPayload);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Simulated scan for Table $_tableString!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
