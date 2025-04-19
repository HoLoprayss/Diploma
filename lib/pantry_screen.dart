import 'package:flutter/material.dart';
import 'services/realm_service.dart';
import 'models/product.dart';
import 'edit_product_screen.dart';

class PantryScreen extends StatefulWidget {
  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  late RealmService realmService;
  late List<Product> pantryProducts;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    realmService = RealmService();
    pantryProducts = realmService.getProductsByCategory('Pantry').toList();
  }

  @override
  void dispose() {
    realmService.close();
    super.dispose();
  }

  String calculateDaysLeft(DateTime? expirationDate) {
    if (expirationDate == null) return 'N/A';
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    return difference >= 0 ? '$difference days left' : 'Expired';
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _showProductOptions(Product product) {
    if (!isEditMode) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: product),
                  ),
                ).then((_) {
                  setState(() {
                    pantryProducts = realmService.getProductsByCategory('Pantry').toList();
                  });
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                realmService.deleteProduct(product);
                setState(() {
                  pantryProducts.remove(product);
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('MEALSAFE'),
        backgroundColor: Colors.lightGreen[600],
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.done : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: pantryProducts.length,
          itemBuilder: (context, index) {
            final product = pantryProducts[index];
            return GestureDetector(
              onTap: () => _showProductOptions(product),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[400],
                          child: Center(child: Icon(Icons.fastfood, color: Colors.white)),
                        ),
                        Container(
                          color: Colors.black54,
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            product.quantity,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(product.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                      calculateDaysLeft(product.expirationDate),
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'scan'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'add'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.lightGreen[600],
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
          // Другие действия для "scan" и "add" можно добавить позже
        },
      ),
    );
  }
}