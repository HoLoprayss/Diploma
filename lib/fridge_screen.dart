import 'package:flutter/material.dart';
import '../services/realm_service.dart';
import '../models/product.dart';

class FridgeScreen extends StatefulWidget {
  @override
  _FridgeScreenState createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  late RealmService realmService;
  late List<Product> fridgeProducts;

  @override
  void initState() {
    super.initState();
    realmService = RealmService();
    fridgeProducts = realmService.getProductsByCategory('Fridge').toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'MEALSAFE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightGreen[600],
        elevation: 0,
        shape: StadiumBorder(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: fridgeProducts.length,
            itemBuilder: (context, index) {
              final product = fridgeProducts[index];
              return Container(
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
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
                          child: Text(product.quantity, style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(product.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text('${calculateDaysLeft(product.expirationDate)}', style: TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
                  ],
                ),
              );
            }
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'scan'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'edit'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.lightGreen[600],
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
      ),
    );
  }
}