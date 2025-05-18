import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'fridge_screen.dart';
import 'pantry_screen.dart';
import 'services/realm_service.dart';
import 'models/product.dart';
import 'add_product_screen.dart';
import 'scan_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    realmService = RealmService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    realmService.close();
    super.dispose();
  }

  late RealmService realmService;

  void _navigateToScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanReceiptScreen()),
    );
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductScreen()),
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
            fontSize: 26,
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
                Color(0xFF2A9D8F), // Primary teal
                Color(0xFF56C4A8), // Soft teal
              ],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCard(
                      context: context,
                      title: 'FRIDGE',
                      icon: Icons.kitchen,
                      gradientColors: [Color(0xFF2A9D8F), Color(0xFF56C4A8)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FridgeScreen()),
                      ),
                    ),
                    _buildCard(
                      context: context,
                      title: 'PANTRY',
                      icon: Icons.storage,
                      gradientColors: [Color(0xFF56C4A8), Color(0xFF2A9D8F).withOpacity(0.8)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PantryScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: MediaQuery.of(context).size.width * 0.42,
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 12,
              offset: Offset(-4, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white.withOpacity(0.9),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFab() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: FloatingActionButton(
        backgroundColor: Color(0xFFF4A261), // Warm coral accent
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, size: 28, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.qr_code_scanner, color: Color(0xFF2A9D8F)), // Primary teal
                      title: Text(
                        'Scan Receipt',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToScan();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.add_circle, color: Color(0xFF2A9D8F)), // Primary teal
                      title: Text(
                        'Add Product',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToAdd();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}