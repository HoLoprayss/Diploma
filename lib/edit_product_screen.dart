import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _EditProductScreenState extends State<EditProductScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _quantity;
  late DateTime? _expirationDate;
  late String _category;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _quantity = widget.product.quantity;
    _expirationDate = widget.product.expirationDate;
    _category = widget.product.category;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final realmService = RealmService();
      final managedProduct = realmService.realm.all<Product>().query('id == \$0', [widget.product.id]).first;
      realmService.updateProduct(
        managedProduct,
        name: _name,
        quantity: _quantity,
        expirationDate: _expirationDate,
        category: _category,
      );
      realmService.close();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC), // Soft neutral background
      appBar: AppBar(
        title: Text(
          'Редактировать продукт',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A9D8F), Color(0xFF56C4A8)],
            ),
          ),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFormField(
                      label: 'Название',
                      initialValue: _name,
                      validator: (value) => value!.isEmpty ? 'Пожалуйста, введите название' : null,
                      onSaved: (value) => _name = value!,
                    ),
                    SizedBox(height: 16),
                    _buildTextFormField(
                      label: 'Количество',
                      initialValue: _quantity,
                      validator: (value) => value!.isEmpty ? 'Пожалуйста, введите количество' : null,
                      onSaved: (value) => _quantity = value!,
                    ),
                    SizedBox(height: 16),
                    _buildDropdownFormField(),
                    SizedBox(height: 16),
                    _buildDatePicker(),
                    SizedBox(height: 24),
                    Center(
                      child: _buildSaveButton(),
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

  Widget _buildTextFormField({
    required String label,
    required String initialValue,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.poppins(
            color: Color(0xFF2A9D8F), // Primary teal
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 16),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdownFormField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _category,
        decoration: InputDecoration(
          hintText: 'Категория',
          hintStyle: GoogleFonts.poppins(
            color: Color(0xFF2A9D8F), // Primary teal
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
        items: ['Fridge', 'Pantry'].map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category, style: GoogleFonts.poppins(fontSize: 16)),
          );
        }).toList(),
        onChanged: (value) => setState(() => _category = value!),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF2A9D8F)),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _expirationDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF2A9D8F), // Primary teal
                  onPrimary: Colors.white,
                  surface: Color(0xFFF8FAFC),
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _expirationDate = date);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Срок годности',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF2A9D8F), // Primary teal
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _expirationDate == null
                      ? 'Не задано'
                      : _expirationDate!.toString().substring(0, 10),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today,
              color: Color(0xFF2A9D8F), // Primary teal
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF4A261), // Warm coral
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        child: Text(
          'Сохранить изменения',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}