// edit_products_screen.dart
import 'package:flutter/material.dart';
import 'package:mealsafe/models/product.dart';
import 'package:mealsafe/services/realm_service.dart';

class EditProductsScreen extends StatefulWidget {
  final List<Product> products;

  const EditProductsScreen({super.key, required this.products});

  @override
  _EditProductsScreenState createState() => _EditProductsScreenState();
}

class _EditProductsScreenState extends State<EditProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверьте данные'),
        backgroundColor: Colors.lightGreen[600],
      ),
      body: ListView.builder(
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          final product = widget.products[index];
          return _buildProductCard(product);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveProducts,
        backgroundColor: Colors.lightGreen[600],
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: product.name,
              decoration: const InputDecoration(labelText: 'Название'),
              onChanged: (value) => product.name = value,
            ),
            TextFormField(
              initialValue: product.quantity,
              decoration: const InputDecoration(labelText: 'Количество'),
              onChanged: (value) => product.quantity = value,
            ),
            ListTile(
              title: const Text('Категория'),
              trailing: DropdownButton<String>(
                value: product.category,
                items: ['Fridge', 'Pantry'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => product.category = value!),
              ),
            ),
            ListTile(
              title: const Text('Срок годности'),
              subtitle: Text(
                product.expirationDate?.toString().substring(0, 10) ?? 'Не указан',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, product),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, Product product) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: product.expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => product.expirationDate = picked);
    }
  }

  void _saveProducts() {
    final realmService = RealmService();
    for (var product in widget.products) {
      realmService.addProduct(product);
    }
    realmService.close();

    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
//yayayaya