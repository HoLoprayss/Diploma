import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/shopping_item.dart';
import 'services/shopping_service.dart';

class ShoppingScreen extends StatefulWidget {
  @override
  _ShoppingScreenState createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final ShoppingService shoppingService = ShoppingService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    shoppingService.close();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    if (name.isNotEmpty && quantity.isNotEmpty) {
      shoppingService.addItem(name: name, quantity: quantity);
      setState(() {
        _nameController.clear();
        _quantityController.clear();
      });
    }
  }

  void _toggleBought(ShoppingItem item) {
    shoppingService.updateItem(item, isBought: !item.isBought);
    setState(() {});
  }

  void _deleteItem(ShoppingItem item) {
    shoppingService.deleteItem(item);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = shoppingService.getAllItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'План покупок',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: isDark ? Color(0xFF2D3748) : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Товар',
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 80,
                      child: TextField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Кол-во',
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 12),
                    Material(
                      color: theme.primaryColor,
                      shape: CircleBorder(),
                      child: InkWell(
                        onTap: _addItem,
                        customBorder: CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 28),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Список покупок пуст',
                        style: GoogleFonts.poppins(fontSize: 16, color: theme.hintColor),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final bought = item.isBought;
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 24),
                            color: Colors.red.shade400,
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteItem(item),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Card(
                              color: bought
                                  ? (isDark ? Color(0xFF232B3A) : Color(0xFFF1F5F9))
                                  : (isDark ? Color(0xFF2D3748) : Colors.white),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                leading: Container(
                                  decoration: BoxDecoration(
                                    color: bought ? theme.primaryColor.withOpacity(0.18) : theme.primaryColor.withOpacity(0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    bought ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: bought ? theme.primaryColor : theme.disabledColor,
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: bought ? TextDecoration.lineThrough : null,
                                    color: bought ? theme.disabledColor : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                subtitle: Text(
                                  item.quantity,
                                  style: GoogleFonts.poppins(fontSize: 14, color: theme.hintColor),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                                  onPressed: () => _deleteItem(item),
                                  tooltip: 'Удалить',
                                ),
                                onTap: () => _toggleBought(item),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 