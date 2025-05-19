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
  late Animation<Offset> _slideAnimation;
  bool _isSubmitting = false;

  // Маппинг для перевода категорий
  final Map<String, String> _categoryMap = {
    'Fridge': 'Холодильник',
    'Pantry': 'Кладовая'
  };
  
  final Map<String, String> _reverseCategoryMap = {
    'Холодильник': 'Fridge',
    'Кладовая': 'Pantry'
  };

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _quantity = widget.product.quantity;
    _expirationDate = widget.product.expirationDate;
    _category = _categoryMap[widget.product.category] ?? 'Холодильник';
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      _formKey.currentState!.save();
      
      // Перевод категории обратно на английский для сохранения в БД
      String dbCategory = _reverseCategoryMap[_category] ?? 'Fridge';
      
      final realmService = RealmService();
      final managedProduct = realmService.realm.all<Product>().query('id == \$0', [widget.product.id]).first;
      
      realmService.updateProduct(
        managedProduct,
        name: _name,
        quantity: _quantity,
        expirationDate: _expirationDate,
        category: dbCategory,
      );
      
      realmService.close();
      
      // Небольшая анимация перед закрытием
      await Future.delayed(Duration(milliseconds: 300));
      
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundDecoration(isDark),
          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 100.0),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Информация о продукте'),
                          SizedBox(height: 20),
                          _buildTextFormField(
                            label: 'Название',
                            icon: Icons.shopping_cart_outlined,
                            initialValue: _name,
                            validator: (value) => value!.isEmpty ? 'Пожалуйста, введите название' : null,
                            onSaved: (value) => _name = value!,
                          ),
                          SizedBox(height: 16),
                          _buildTextFormField(
                            label: 'Количество',
                            icon: Icons.straighten_outlined,
                            initialValue: _quantity,
                            validator: (value) => value!.isEmpty ? 'Пожалуйста, введите количество' : null,
                            onSaved: (value) => _quantity = value!,
                          ),
                          SizedBox(height: 24),
                          _buildSectionHeader('Дополнительно'),
                          SizedBox(height: 20),
                          _buildDropdownFormField(),
                          SizedBox(height: 16),
                          _buildDatePicker(),
                          SizedBox(height: 40),
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
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    Color primaryColor = Color(0xFF2A9D8F);
    Color lightColor = Color(0xFF56C4A8);
    
    return AppBar(
      title: Text(
        'Редактировать продукт',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor, // Primary teal
              lightColor, // Soft teal
            ],
          ),
        ),
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBackgroundDecoration(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Color(0xFF2A9D8F).withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFFF4A261).withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData icon,
    required String initialValue,
    required String? Function(String?) validator,
    required Function(String?) onSaved,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF2A9D8F),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdownFormField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonFormField<String>(
          value: _category,
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF2A9D8F)),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: theme.textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            labelText: 'Категория',
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              Icons.category_outlined,
              color: Color(0xFF2A9D8F),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) {
            setState(() {
              _category = value!;
            });
          },
          items: <String>['Холодильник', 'Кладовая']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          dropdownColor: isDark ? Color(0xFF2D3748) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: Color(0xFF2A9D8F)),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Срок годности',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _expirationDate != null
                        ? '${_expirationDate!.day}.${_expirationDate!.month}.${_expirationDate!.year}'
                        : 'Не указан',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2A9D8F),
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF2A9D8F),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2A9D8F),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isSubmitting
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Сохранить',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.save_outlined, size: 20),
              ],
            ),
    );
  }
}