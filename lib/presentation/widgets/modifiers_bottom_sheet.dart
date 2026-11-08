import 'package:flutter/material.dart';
import '../../models/product_model.dart';

/// Modal bottom sheet matching Screen 2 in reference_screen.jpg:
/// "ایڈ آنز منتخب کریں / Select Modifiers & Add-ons"
class ModifiersBottomSheet extends StatefulWidget {
  final ProductModel product;
  final Function(List<ModifierItem> selectedModifiers, int quantity, String? notes) onAddToCart;

  const ModifiersBottomSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ModifiersBottomSheet> createState() => _ModifiersBottomSheetState();
}

class _ModifiersBottomSheetState extends State<ModifiersBottomSheet> {
  final List<ModifierItem> _selectedModifiers = [];
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    double mods = 0;
    for (final m in _selectedModifiers) {
      mods += m.price;
    }
    return widget.product.price + mods;
  }

  double get _totalPrice => _unitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title & Base Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بنیادی قیمت: Rs. ${widget.product.price.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          // Modifiers Header
          Row(
            children: [
              const Icon(Icons.tune, size: 20, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                'ایڈ آنز منتخب کریں / Select Add-ons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.product.modifiers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No additional add-ons available for this item.',
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...widget.product.modifiers.map((modifier) {
              final isSelected = _selectedModifiers.contains(modifier);
              return CheckboxListTile(
                value: isSelected,
                contentPadding: EdgeInsets.zero,
                title: Text(modifier.name),
                subtitle: Text('+ Rs. ${modifier.price.toStringAsFixed(0)}'),
                activeColor: Theme.of(context).primaryColor,
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true) {
                      _selectedModifiers.add(modifier);
                    } else {
                      _selectedModifiers.remove(modifier);
                    }
                  });
                },
              );
            }),
          const SizedBox(height: 12),
          // Special Instructions
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'خاص ہدایات / Special instructions (e.g. No Onion)',
              hintText: 'e.g. Make it extra spicy, No onions',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          // Quantity Stepper & Add to Cart button
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    widget.onAddToCart(
                      _selectedModifiers,
                      _quantity,
                      _notesController.text.trim().isNotEmpty
                          ? _notesController.text.trim()
                          : null,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'کارٹ میں شامل کریں / Add (Rs. ${_totalPrice.toStringAsFixed(0)})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
