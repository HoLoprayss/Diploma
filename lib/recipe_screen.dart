import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/recipe.dart';
import 'services/recipe_service.dart';

class RecipeScreen extends StatefulWidget {
  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final RecipeService recipeService = RecipeService();

  @override
  void dispose() {
    recipeService.close();
    super.dispose();
  }

  void _showAddRecipeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRecipeForm(
        onRecipeAdded: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final recipes = recipeService.getAllRecipes().toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Мои рецепты', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: recipes.isEmpty
            ? Center(
                child: Text('Нет рецептов', style: GoogleFonts.poppins(fontSize: 16, color: theme.hintColor)),
              )
            : ListView.separated(
                itemCount: recipes.length,
                separatorBuilder: (_, __) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Card(
                    color: isDark ? Color(0xFF2D3748) : Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text(recipe.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Text(recipe.description, style: GoogleFonts.poppins(fontSize: 14, color: theme.hintColor)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ингредиенты:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              ...recipe.ingredients.map((ing) => Text('• $ing', style: GoogleFonts.poppins())),
                              SizedBox(height: 10),
                              Text('Шаги:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              ...recipe.steps.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}', style: GoogleFonts.poppins())),
                              SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                                  onPressed: () {
                                    setState(() {
                                      recipeService.deleteRecipe(recipe);
                                    });
                                  },
                                  tooltip: 'Удалить',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecipeModal,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Добавить рецепт',
      ),
    );
  }
}

class AddRecipeForm extends StatefulWidget {
  final VoidCallback onRecipeAdded;
  const AddRecipeForm({required this.onRecipeAdded});

  @override
  State<AddRecipeForm> createState() => _AddRecipeFormState();
}

class _AddRecipeFormState extends State<AddRecipeForm> {
  final RecipeService recipeService = RecipeService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _stepController = TextEditingController();
  List<String> _ingredients = [];
  List<String> _steps = [];

  @override
  void dispose() {
    recipeService.close();
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _ingredients.add(text);
        _ingredientController.clear();
      });
    }
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _steps.add(text);
        _stepController.clear();
      });
    }
  }

  void _saveRecipe() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isNotEmpty && _ingredients.isNotEmpty && _steps.isNotEmpty) {
      recipeService.addRecipe(
        title: title,
        description: description,
        ingredients: List.from(_ingredients),
        steps: List.from(_steps),
      );
      widget.onRecipeAdded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF232B3A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Добавить рецепт', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.hintColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingredientController,
                      decoration: InputDecoration(
                        labelText: 'Ингредиент',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addIngredient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _ingredients.map((ing) => Chip(
                  label: Text(ing, style: GoogleFonts.poppins()),
                  onDeleted: () => setState(() => _ingredients.remove(ing)),
                )).toList(),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stepController,
                      decoration: InputDecoration(
                        labelText: 'Шаг',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _steps.asMap().entries.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.15),
                    child: Text('${entry.key + 1}', style: GoogleFonts.poppins(color: theme.primaryColor)),
                  ),
                  title: Text(entry.value, style: GoogleFonts.poppins()),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                    onPressed: () => setState(() => _steps.removeAt(entry.key)),
                  ),
                )).toList(),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text('Сохранить', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 