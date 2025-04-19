import 'package:flutter/material.dart';
import 'package:mealsafe/services/realm_service.dart';
import 'package:mealsafe/models/product.dart';
import 'package:realm/realm.dart';
import 'package:uuid/uuid.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  EditProductScreen({required this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _quantity;
  late DateTime? _expirationDate;
  late String _category;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _quantity = widget.product.quantity;
    _expirationDate = widget.product.expirationDate;
    _category = widget.product.category;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) { // Проверка валидации формы
      _formKey.currentState!.save(); // Сохранение данных из формы
      final realmService = RealmService();
      // Получаем управляемый объект из Realm по id
      final managedProduct = realmService.realm.all<Product>().query('id == \$0', [widget.product.id]).first;
      realmService.updateProduct(
        managedProduct,
        name: _name,
        quantity: _quantity,
        expirationDate: _expirationDate,
        category: _category,
      );
      realmService.close(); // Закрытие Realm
      Navigator.pop(context); // Возврат на предыдущий экран
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        backgroundColor: Colors.lightGreen[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _quantity,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (value) => value!.isEmpty ? 'Please enter a quantity' : null,
                onSaved: (value) => _quantity = value!,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: ['Fridge', 'Pantry'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              ListTile(
                title: Text('Expiration Date'),
                subtitle: Text(_expirationDate == null
                    ? 'Not set'
                    : _expirationDate!.toString().substring(0, 10)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _expirationDate = date);
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}