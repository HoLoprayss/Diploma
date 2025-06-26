import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/recipe.dart';
import 'services/recipe_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  void _openRecipeView(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeViewScreen(
          recipe: recipe,
          recipeService: recipeService,
          onRecipeChanged: () => setState(() {}),
        ),
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
                  return GestureDetector(
                    onTap: () => _openRecipeView(recipe),
                    child: Card(
                      color: isDark ? Color(0xFF2D3748) : Colors.white,
                      elevation: 4,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty && File(recipe.imagePath!).existsSync()
                                  ? Image.file(
                                      File(recipe.imagePath!),
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 64,
                                      height: 64,
                                      color: theme.primaryColor.withOpacity(0.08),
                                      child: Icon(Icons.image, color: theme.primaryColor.withOpacity(0.25), size: 32),
                                    ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(recipe.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.primaryColor)),
                                  SizedBox(height: 4),
                                  Text(recipe.description, style: GoogleFonts.poppins(fontSize: 13, color: theme.hintColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.list, size: 14, color: theme.primaryColor),
                                      SizedBox(width: 4),
                                      Text('${recipe.ingredients.length} ингредиентов', style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryColor)),
                                      SizedBox(width: 12),
                                      Icon(Icons.timer, size: 14, color: theme.primaryColor),
                                      SizedBox(width: 4),
                                      Text('${recipe.steps.length} шагов', style: GoogleFonts.poppins(fontSize: 12, color: theme.primaryColor)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                      ),
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
  String? _imagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

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
        imagePath: _imagePath,
      );
      widget.onRecipeAdded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity, height: 140),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 38, color: theme.primaryColor),
                                SizedBox(height: 8),
                                Text('Добавить фото', style: GoogleFonts.poppins(color: theme.primaryColor)),
                              ],
                            ),
                          ),
                  ),
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
      ),
    );
  }
}

class EditRecipeForm extends StatefulWidget {
  final Recipe recipe;
  final RecipeService recipeService;
  final VoidCallback onRecipeUpdated;
  const EditRecipeForm({required this.recipe, required this.recipeService, required this.onRecipeUpdated});

  @override
  State<EditRecipeForm> createState() => _EditRecipeFormState();
}

class _EditRecipeFormState extends State<EditRecipeForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientController;
  late TextEditingController _stepController;
  late List<String> _ingredients;
  late List<String> _steps;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _stepFocusNode = FocusNode();
  String? _imagePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description);
    _ingredientController = TextEditingController();
    _stepController = TextEditingController();
    _ingredients = List<String>.from(widget.recipe.ingredients);
    _steps = List<String>.from(widget.recipe.steps);
    _imagePath = widget.recipe.imagePath;
    _stepFocusNode.addListener(_onStepFocus);
  }

  void _onStepFocus() {
    if (_stepFocusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    _stepFocusNode.removeListener(_onStepFocus);
    _stepFocusNode.dispose();
    _scrollController.dispose();
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
      widget.recipeService.updateRecipe(
        widget.recipe,
        title: title,
        description: description,
        ingredients: List.from(_ingredients),
        steps: List.from(_steps),
        imagePath: _imagePath,
      );
      widget.onRecipeUpdated();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
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
                    Text('Редактировать рецепт', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.hintColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity, height: 140),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 38, color: theme.primaryColor),
                                SizedBox(height: 8),
                                Text('Добавить фото', style: GoogleFonts.poppins(color: theme.primaryColor)),
                              ],
                            ),
                          ),
                  ),
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
                        focusNode: _stepFocusNode,
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
      ),
    );
  }
}

class RecipeViewScreen extends StatefulWidget {
  final Recipe recipe;
  final RecipeService recipeService;
  final VoidCallback onRecipeChanged;
  const RecipeViewScreen({Key? key, required this.recipe, required this.recipeService, required this.onRecipeChanged}) : super(key: key);

  @override
  State<RecipeViewScreen> createState() => _RecipeViewScreenState();
}

class _RecipeViewScreenState extends State<RecipeViewScreen> {
  late Recipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  void _onRecipeEdited() {
    setState(() {
      // Обновляем рецепт из базы (на случай, если он был изменён)
      _recipe = widget.recipeService.realm.find<Recipe>(_recipe.id)!;
    });
    widget.onRecipeChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String? imagePath = _recipe.imagePath;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Рецепт', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            tooltip: 'Редактировать',
            onPressed: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => EditRecipeForm(
                  recipe: _recipe,
                  recipeService: widget.recipeService,
                  onRecipeUpdated: () {},
                ),
              );
              if (result == true) {
                _onRecipeEdited();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade200),
            tooltip: 'Удалить',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Удалить рецепт?'),
                  content: Text('Вы уверены, что хотите удалить этот рецепт?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Удалить', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true) {
                widget.recipeService.deleteRecipe(_recipe);
                Navigator.pop(context);
                widget.onRecipeChanged();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF232B3A) : Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.08),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 260,
                          errorBuilder: (context, error, stackTrace) => _placeholderImage(theme),
                        ),
                      )
                    : _placeholderImage(theme),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _recipe.title,
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
                        ),
                        SizedBox(height: 8),
                        if (_recipe.description.isNotEmpty)
                          Text(
                            _recipe.description,
                            style: GoogleFonts.poppins(fontSize: 15, color: theme.hintColor),
                          ),
                        SizedBox(height: 18),
                        Text('Ингредиенты', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        ..._recipe.ingredients.map((ing) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: theme.primaryColor),
                                  SizedBox(width: 10),
                                  Expanded(child: Text(ing, style: GoogleFonts.poppins(fontSize: 15))),
                                ],
                              ),
                            )),
                        SizedBox(height: 18),
                        Text('Шаги приготовления', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        ..._recipe.steps.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: theme.primaryColor.withOpacity(0.13),
                                    child: Text('${entry.key + 1}', style: GoogleFonts.poppins(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(child: Text(entry.value, style: GoogleFonts.poppins(fontSize: 15))),
                                ],
                              ),
                            )),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: theme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Добавлен: ${_formatDate(_recipe.createdAt)}',
                              style: GoogleFonts.poppins(fontSize: 13, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage(ThemeData theme) {
    return Center(
      child: Icon(Icons.image, size: 80, color: theme.primaryColor.withOpacity(0.18)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
} 