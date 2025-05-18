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

  @override
  void initState() {
    super.initState();
    realmService = RealmService();
    fridgeProducts = realmService.getProductsByCategory('Fridge').toList();
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
    realmService.close();
    _animationController.dispose();
    super.dispose();
  }

  String calculateDaysLeft(DateTime? expirationDate) {
    if (expirationDate == null) return 'N/A';
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    return difference >= 0 ? '$difference дней осталось' : 'Просрочено';
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _showProductOptions(Product product) {
    if (!isEditMode) return; // Действия доступны только в режиме редактирования
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Color(0xFF2A9D8F)),
              title: Text('Редактировать', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: product),
                  ),
                ).then((_) {
                  setState(() {
                    fridgeProducts = realmService.getProductsByCategory('Fridge').toList();
                  });
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Color(0xFF2A9D8F)),
              title: Text('Удалить', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
              onTap: () {
                realmService.deleteProduct(product);
                setState(() {
                  fridgeProducts.remove(product);
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC), // Soft neutral background
      appBar: AppBar(
        title: Text(
          'MEALSAFE',
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
        actions: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            child: IconButton(
              icon: Icon(isEditMode ? Icons.done : Icons.edit, color: Color(0xFFF4A261), size: 24),
              onPressed: _toggleEditMode,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: fridgeProducts.length,
            itemBuilder: (context, index) {
              final product = fridgeProducts[index];
              return GestureDetector(
                onTap: () => _showProductOptions(product),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A9D8F), Color(0xFF56C4A8).withOpacity(0.9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Icon(Icons.fastfood, color: Colors.white, size: 28)),
                          ),
                          Container(
                            color: Colors.black54,
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              product.quantity,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        calculateDaysLeft(product.expirationDate),
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            label: 'Главная',
            activeIcon: Icon(Icons.home, size: 24, color: Color(0xFFF4A261)),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 24),
            label: 'Сканировать',
            activeIcon: Icon(Icons.camera_alt, size: 24, color: Color(0xFFF4A261)),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 24),
            label: 'Добавить',
            activeIcon: Icon(Icons.add, size: 24, color: Color(0xFFF4A261)),
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Color(0xFFF4A261), // Warm coral
        unselectedItemColor: Colors.white70,
        backgroundColor: Color(0xFF2A9D8F), // Primary teal
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => ScanReceiptScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen()));
        },
      ),
    );
  }
}