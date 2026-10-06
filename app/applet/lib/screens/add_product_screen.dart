import 'package:flutter/material.dart';

import '../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  String selectedMethod = '';
  String selectedUnit = 'Piece';
  bool isLoose = false;
  bool isSaving = false;

  final productNameController = TextEditingController();
  final categoryController = TextEditingController();
  final quantityController = TextEditingController();
  final costPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();

  @override
  void dispose() {
    productNameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    super.dispose();
  }

  void selectMethod(String method) {
    setState(() {
      selectedMethod = method;
    });
  }

  Future<void> addToStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity =
        double.tryParse(quantityController.text.trim()) ?? 0;

    final costPrice =
        double.tryParse(costPriceController.text.trim()) ?? 0;

    final sellingPrice =
        double.tryParse(sellingPriceController.text.trim()) ?? 0;

    // Current Django backend supports UNIT and KG.
    final sellingType =
    selectedUnit == 'Kg' ? 'KG' : 'UNIT';

    setState(() {
      isSaving = true;
    });

    try {
      final product = await ProductService().registerProduct(
        name: productNameController.text.trim(),
        category: categoryController.text.trim(),
        sellingType: sellingType,
        costPrice: costPrice,
        pricePerUnit: sellingPrice,
        quantity: quantity,
        isLoose: isLoose,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} added to stock successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, product);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add product: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Product to Stock',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Add a new product using camera, manual entry, or voice.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Choose Input Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _InputMethodCard(
                icon: Icons.camera_alt_outlined,
                title: 'Scan with ESP32-CAM',
                subtitle:
                'Identify the product using the ESP32 camera',
                selected: selectedMethod == 'esp32',
                onTap: () => selectMethod('esp32'),
              ),

              const SizedBox(height: 12),

              _InputMethodCard(
                icon: Icons.edit_outlined,
                title: 'Add Manually',
                subtitle:
                'Enter product details yourself',
                selected: selectedMethod == 'manual',
                onTap: () => selectMethod('manual'),
              ),

              const SizedBox(height: 12),

              _InputMethodCard(
                icon: Icons.mic_none_outlined,
                title: 'Add by Voice',
                subtitle:
                'Speak the product details',
                selected: selectedMethod == 'voice',
                onTap: () => selectMethod('voice'),
              ),

              const SizedBox(height: 28),

              if (selectedMethod == 'esp32')
                _buildEsp32Section(),

              if (selectedMethod == 'manual')
                _buildProductForm(),

              if (selectedMethod == 'voice')
                _buildVoiceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEsp32Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'ESP32-CAM Product Scanner',
          subtitle:
          'Place the product in front of the ESP32-CAM.',
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 12),
              const Text(
                'ESP32-CAM Preview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Camera recognition will be connected here.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // ESP32-CAM connection will be implemented later.
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan Product'),
          ),
        ),

        const SizedBox(height: 24),

        _buildProductForm(),
      ],
    );
  }

  Widget _buildVoiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Voice Product Entry',
          subtitle:
          'Speak the product name, quantity and prices.',
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.grey.shade100,
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 38,
                child: Icon(
                  Icons.mic_none_outlined,
                  size: 38,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Tap the microphone and speak',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Example: "Add 20 kilograms rice, '
                    'cost price 42 rupees per kg, '
                    'selling price 50 rupees per kg."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  // Voice recognition will be connected later.
                },
                icon: const Icon(Icons.mic),
                label: const Text('Start Voice Entry'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildProductForm(),
      ],
    );
  }

  Widget _buildProductForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Product Details',
          subtitle:
          'Review the details before adding the product to stock.',
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: productNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Product Name',
            hintText: 'Example: Rice',
            prefixIcon:
            Icon(Icons.inventory_2_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Enter product name';
            }
            return null;
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: categoryController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Category',
            hintText: 'Example: Grocery',
            prefixIcon:
            Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null ||
                value.trim().isEmpty) {
              return 'Enter category';
            }
            return null;
          },
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          value: selectedUnit,
          decoration: const InputDecoration(
            labelText: 'Unit',
            prefixIcon:
            Icon(Icons.scale_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Piece',
              child: Text('Piece'),
            ),
            DropdownMenuItem(
              value: 'Packet',
              child: Text('Packet'),
            ),
            DropdownMenuItem(
              value: 'Kg',
              child: Text('Kilogram (kg)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedUnit = value;
              });
            }
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: quantityController,
          keyboardType:
          const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: 'Stock Quantity',
            hintText: selectedUnit == 'Kg'
                ? 'Example: 20'
                : 'Example: 100',
            prefixIcon:
            const Icon(Icons.inventory_outlined),
            suffixText: selectedUnit,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final number =
            double.tryParse(value ?? '');

            if (number == null || number < 0) {
              return 'Enter a valid quantity';
            }

            if (selectedUnit != 'Kg' &&
                number % 1 != 0) {
              return 'Quantity must be a whole number';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: costPriceController,
          keyboardType:
          const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: 'Cost Price',
            hintText: 'Example: 42',
            prefixIcon:
            const Icon(Icons.currency_rupee),
            suffixText: '/ $selectedUnit',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final number =
            double.tryParse(value ?? '');

            if (number == null || number < 0) {
              return 'Enter a valid cost price';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: sellingPriceController,
          keyboardType:
          const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: 'Selling Price',
            hintText: 'Example: 50',
            prefixIcon:
            const Icon(Icons.sell_outlined),
            suffixText: '/ $selectedUnit',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final number =
            double.tryParse(value ?? '');

            if (number == null || number <= 0) {
              return 'Enter a valid selling price';
            }

            return null;
          },
        ),

        const SizedBox(height: 8),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Loose Product',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: const Text(
            'Enable for loose commodities such as rice or sugar.',
          ),
          value: isLoose,
          onChanged: (value) {
            setState(() {
              isLoose = value;
            });
          },
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isSaving ? null : addToStock,
            icon: isSaving
                ? const SizedBox(
              width: 21,
              height: 21,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.add_box_outlined,
            ),
            label: Text(
              isSaving
                  ? 'Saving to Stock...'
                  : 'Add to Stock',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _InputMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _InputMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 3 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                child: Icon(
                  icon,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}