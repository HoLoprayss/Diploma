import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'services/realm_service.dart';
import 'models/product.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _quantity = '';
  DateTime? _expirationDate;
  String _category = 'Fridge';

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final product = Product(
        Uuid().v4(),
        _name,
        _quantity,
        _category,
        expirationDate: _expirationDate,
      );
      final realmService = RealmService();
      realmService.addProduct(product);
      realmService.close();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
        backgroundColor: Colors.lightGreen[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
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
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _expirationDate = date);
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Add Product'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}