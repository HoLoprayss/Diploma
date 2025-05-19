import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/realm_service.dart';
import 'models/product.dart';
import 'edit_product_screen.dart';

// Adjust these imports based on your actual file names and directory structure
import 'add_product_screen.dart'; // Alternative: 'AddProductScreen.dart' or 'screens/add_product_screen.dart'
import 'scan_screen.dart'; // Alternative: 'ScanReceiptScreen.dart' or 'screens/scan_receipt_screen.dart'

class FridgeScreen extends StatefulWidget {
  @override
  _FridgeScreenState createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> with SingleTickerProviderStateMixin {
  late RealmService realmService;
  late List<Product> fridgeProducts;
  bool isEditMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    realmService = RealmService();
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
    _loadProducts();
    _animationController.forward();
  }

  @override
  void dispose() {
    realmService.close();
    _animationController.dispose();
    super.dispose();
  }

  String calculateDaysLeft(DateTime? expirationDate) {
    if (expirationDate == null) return 'Нет срока';
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'Просрочено ${-difference} дн.';
    } else if (difference == 0) {
      return 'Истекает сегодня!';
    } else if (difference == 1) {
      return 'Остался 1 день';
    } else if (difference < 7) {
      return 'Осталось $difference дн.';
    } else {
      return '${difference ~/ 7} нед. ${difference % 7} дн.';
    }
  }
  
  Color getExpirationColor(DateTime? expirationDate) {
    if (expirationDate == null) return Colors.grey;
    
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 2) {
      return Colors.orange;
    } else if (difference <= 7) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _showProductOptions(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (!isEditMode) return; // Действия доступны только в режиме редактирования
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF2D3748) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                product.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              _buildProductOptionButton(
                icon: Icons.edit_outlined,
                text: 'Редактировать',
                color: Color(0xFF2A9D8F),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen(product: product),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadProducts();
                    }
                  });
                },
              ),
              SizedBox(height: 16),
              _buildProductOptionButton(
                icon: Icons.delete_outline,
                text: 'Удалить',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(product);
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductOptionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 16),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Color(0xFF2D3748) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Удаление продукта',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить "${product.name}"?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Отмена',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                'Удалить',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                realmService.deleteProduct(product);
                Navigator.pop(context);
                _loadProducts();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
    });
    
    // Небольшая задержка для плавности анимации
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        fridgeProducts = realmService.getProductsByCategory('Fridge').toList();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFF2A9D8F),
        elevation: 0,
        title: Text(
          'Холодильник',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Кнопка переключения режима редактирования
          IconButton(
            icon: Icon(
              isEditMode ? Icons.check : Icons.edit_outlined,
              color: Colors.white,
            ),
            tooltip: isEditMode ? 'Завершить' : 'Редактировать',
            onPressed: _toggleEditMode,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A9D8F), Color(0xFF3DB0A2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A9D8F)),
              ),
            )
          : fridgeProducts.isEmpty
              ? _buildEmptyState()
              : SafeArea(
                  bottom: true,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9, // Увеличиваем соотношение для нового дизайна
                          ),
                          itemCount: fridgeProducts.length,
                          itemBuilder: (context, index) {
                            final product = fridgeProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expirationColor = getExpirationColor(product.expirationDate);
    final daysLeft = calculateDaysLeft(product.expirationDate);
    
    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          _showProductOptions(product);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Color(0xFF2D3748).withOpacity(0.7), Color(0xFF2D3748)]
                : [Colors.white, Colors.white.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                // Иконка продукта в цветном круге
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: expirationColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.kitchen,
                    color: expirationColor,
                    size: 26,
                  ),
                ),
                SizedBox(height: 12),
                
                // Название продукта
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Расширяющийся пустой блок
                Expanded(child: SizedBox()),
                
                // Оставшиеся дни
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: expirationColor.withOpacity(0.15),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Text(
                    daysLeft,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: expirationColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            
            // Индикатор режима редактирования
            if (isEditMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF2A9D8F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFF2A9D8F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.kitchen_outlined,
                size: 60,
                color: Color(0xFF2A9D8F),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Холодильник пуст',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Добавьте продукты, чтобы отслеживать их срок годности',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Добавить продукт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2A9D8F),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(initialCategory: 'Fridge'),
                  ),
                ).then((_) => _loadProducts());
              },
            ),
          ],
        ),
      ),
    );
  }
}