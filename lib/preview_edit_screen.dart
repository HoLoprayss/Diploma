// edit_products_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mealsafe/models/product.dart';
import 'package:mealsafe/services/realm_service.dart';

class EditProductsScreen extends StatefulWidget {
  final List<Product> products;

  const EditProductsScreen({super.key, required this.products});

  @override
  _EditProductsScreenState createState() => _EditProductsScreenState();
}

class _EditProductsScreenState extends State<EditProductsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isSaving = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Product> _products;
  
  // Основной акцентный цвет приложения
  Color get primaryColor => Color(0xFF2A9D8F);
  
  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildSaveButton(),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Проверьте данные',
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
            colors: [primaryColor, Color(0xFF264653)],
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
  
  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Stack(
      children: [
        _buildBackgroundDecoration(isDark),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Отредактируйте информацию о продуктах перед сохранением',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    SizedBox(height: 16),
                    _products.isEmpty
                        ? SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Продуктов в списке: ${_products.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ),
                    Expanded(
                      child: _products.isEmpty
                          ? _buildEmptyState()
                          : AnimatedList(
                              key: _listKey,
                              physics: BouncingScrollPhysics(),
                              initialItemCount: _products.length,
                              itemBuilder: (context, index, animation) {
                                return SizeTransition(
                                  sizeFactor: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: _buildProductCard(_products[index], index),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isSaving) _buildSavingIndicator(),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 50,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Список товаров пуст',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Все товары были удалены из списка',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('Вернуться назад'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
              color: primaryColor.withOpacity(isDark ? 0.15 : 0.1),
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
              color: Color(0xFF264653).withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSavingIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              SizedBox(height: 24),
              Text(
                'Сохранение продуктов...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final categoryDisplayNames = {
      'Fridge': 'Холодильник',
      'Pantry': 'Кладовая'
    };
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Продукт ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      padding: EdgeInsets.only(left: 8),
                      constraints: BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () => _showDeleteConfirmation(product, index),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    categoryDisplayNames[product.category] ?? product.category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Название',
              initialValue: product.name,
              icon: Icons.shopping_basket_outlined,
              onChanged: (value) => product.name = value,
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Количество',
              initialValue: product.quantity,
              icon: Icons.format_list_numbered,
              onChanged: (value) => product.quantity = value,
            ),
            SizedBox(height: 16),
            _buildCategoryDropdown(product),
            SizedBox(height: 16),
            _buildDatePicker(product),
          ],
        ),
      ),
    );
  }
  
  void _removeProduct(Product product, int index) {
    final removedProduct = _products[index];
    
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: _buildProductCard(removedProduct, index),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
    
    setState(() {
      _products.removeAt(index);
    });
    
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'Продукт удален из списка',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'ОТМЕНА',
          textColor: Colors.white,
          onPressed: () {
            int insertIndex = index;
            if (insertIndex > _products.length) {
              insertIndex = _products.length;
            }
            
            setState(() {
              _products.insert(insertIndex, removedProduct);
            });
            
            _listKey.currentState?.insertItem(
              insertIndex,
              duration: const Duration(milliseconds: 300),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Product product, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Удаление продукта',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить "${product.name}" из списка?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1E2937) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeProduct(product, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Удалить',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),
        filled: true,
        fillColor: isDark ? Color(0xFF2D3748) : Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Color(0xFF4A5568) : Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildCategoryDropdown(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D3748) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF4A5568) : Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: product.category,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: theme.textTheme.bodyLarge?.color,
          ),
          dropdownColor: isDark ? Color(0xFF2D3748) : Colors.white,
          items: <String>['Fridge', 'Pantry'].map<DropdownMenuItem<String>>((String value) {
            final categoryDisplayNames = {
              'Fridge': 'Холодильник',
              'Pantry': 'Кладовая'
            };
            
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    value == 'Fridge' ? Icons.kitchen_outlined : Icons.kitchen_outlined,
                    color: primaryColor,
                  ),
                  SizedBox(width: 16),
                  Text(categoryDisplayNames[value]!),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              product.category = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: product.expirationDate ?? DateTime.now().add(Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365 * 5)),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  onSurface: theme.textTheme.bodyLarge!.color!,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          setState(() {
            product.expirationDate = picked;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2D3748) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Color(0xFF4A5568) : Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: primaryColor),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Срок годности',
                  style: GoogleFonts.poppins(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  product.expirationDate != null
                      ? '${product.expirationDate!.day.toString().padLeft(2, '0')}.${product.expirationDate!.month.toString().padLeft(2, '0')}.${product.expirationDate!.year}'
                      : 'Не указан',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    if (_products.isEmpty) return SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: _saveProducts,
      backgroundColor: Color(0xFF2A9D8F),
      label: Text(
        'Сохранить все',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(Icons.check),
    );
  }
  
  void _saveProducts() async {
    if (_products.isEmpty) {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Нет продуктов для сохранения',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final realmService = RealmService();
      
      for (var product in _products) {
        realmService.addProduct(
          name: product.name,
          quantity: product.quantity,
          expirationDate: product.expirationDate,
          category: product.category,
        );
      }
      
    realmService.close();

      // Добавляем небольшую задержку для визуального эффекта
      await Future.delayed(Duration(milliseconds: 800));
      
      // Показываем сообщение об успехе
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Продукты успешно сохранены',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: primaryColor,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Возвращаемся на предыдущий экран с небольшой задержкой
      await Future.delayed(Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка при сохранении: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
          duration: Duration(seconds: 3),
        ),
      );
      
      setState(() {
        _isSaving = false;
      });
    }
  }
}