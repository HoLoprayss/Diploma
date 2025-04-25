import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'fridge_screen.dart';
import 'pantry_screen.dart'; // Добавляем импорт нового экрана
import 'services/realm_service.dart';
import 'models/product.dart';
import 'add_product_screen.dart';
import 'scan_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) { // Кнопка "scan"
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ScanReceiptScreen()),
      );
    }
    if (index == 2) { // "add" - третий элемент (индекс 2)
      Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen()));
    }
  }

  late RealmService realmService;

  @override
  void initState() {
    super.initState();
    realmService = RealmService();
  }

  @override
  void dispose() {
    realmService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Фон экрана
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
        shape: StadiumBorder(), // Овальная форма заголовка
        centerTitle: true, // Центрируем заголовок
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Отступы по краям
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Контент начинается сверху
            crossAxisAlignment: CrossAxisAlignment.center, // Центрируем по горизонтали
            children: [
              // Блоки "FRIGE" и "AMBRY" в одном ряду
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равномерный отступ между блоками
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FridgeScreen()));
                    },
                    child: Container(
                      width: 180,
                      height: 350,
                      decoration: BoxDecoration(color: Colors.lightGreen[600], borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('FRIDGE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                  GestureDetector( // Добавляем GestureDetector для AMBRY
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PantryScreen()));
                    },
                    child: Container(
                      width: 180,
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.lightGreen[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'PANTRY',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10), // Отступ перед блоком "LIST"
            ],
          ),
        ),
      ),
      // Нижняя панель навигации
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'add',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.lightGreen[600],
        onTap: _onItemTapped,
      ),
    );
  }
}