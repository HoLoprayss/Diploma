import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/product_filter.dart';
import 'services/filter_service.dart';

/// Экран фильтрации продуктов
class FilterScreen extends StatefulWidget {
  final ProductFilter? initialFilter;
  final Function(ProductFilter) onFilterApplied;

  const FilterScreen({
    Key? key,
    this.initialFilter,
    required this.onFilterApplied,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late ProductFilter _currentFilter;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customDaysController = TextEditingController();
  final TextEditingController _filterNameController = TextEditingController();
  
  String _selectedUnit = 'кг';
  bool _isLoading = false;
  Map<String, ProductFilter> _savedFilters = {};

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter ?? ProductFilter();
    _loadSavedFilters();
    _initializeControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _customDaysController.dispose();
    _filterNameController.dispose();
    super.dispose();
  }

  /// Инициализирует контроллеры значениями из текущего фильтра
  void _initializeControllers() {
    _nameController.text = _currentFilter.nameFilter ?? '';
    
    if (_currentFilter.quantityFilter != null) {
      _quantityController.text = _currentFilter.quantityFilter!.value.toString();
      _selectedUnit = _currentFilter.quantityFilter!.unit;
    }
    
    if (_currentFilter.expirationFilter?.type == ExpirationFilterType.customDays) {
      _customDaysController.text = _currentFilter.expirationFilter!.days?.toString() ?? '';
    }
  }

  /// Загружает сохраненные фильтры
  Future<void> _loadSavedFilters() async {
    setState(() => _isLoading = true);
    try {
      final savedFilters = await FilterService.loadSavedFilters();
      setState(() {
        _savedFilters = savedFilters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Применяет фильтр
  void _applyFilter() {
    final filter = _buildFilter();
    widget.onFilterApplied(filter);
    Navigator.pop(context);
  }

  /// Создает объект фильтра из текущих настроек
  ProductFilter _buildFilter() {
    ExpirationFilter? expirationFilter;
    QuantityFilter? quantityFilter;
    
    // Создаем фильтр по сроку годности
    if (_currentFilter.expirationFilter != null) {
      expirationFilter = _currentFilter.expirationFilter;
    }
    
    // Создаем фильтр по количеству
    if (_quantityController.text.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text);
      if (quantity != null) {
        quantityFilter = QuantityFilter(
          comparisonType: _currentFilter.quantityFilter?.comparisonType ?? 
                         QuantityComparisonType.greaterThan,
          value: quantity,
          unit: _selectedUnit,
        );
      }
    }
    
    return ProductFilter(
      expirationFilter: expirationFilter,
      quantityFilter: quantityFilter,
      nameFilter: _nameController.text.isNotEmpty ? _nameController.text : null,
    );
  }

  /// Сбрасывает фильтр
  void _resetFilter() {
    setState(() {
      _currentFilter = ProductFilter();
      _nameController.clear();
      _quantityController.clear();
      _customDaysController.clear();
      _selectedUnit = 'кг';
    });
  }

  /// Сохраняет текущий фильтр
  Future<void> _saveFilter() async {
    final filterName = await _showSaveFilterDialog();
    if (filterName != null && filterName.isNotEmpty) {
      final filter = _buildFilter().copyWith(filterName: filterName);
      await FilterService.saveCustomFilter(filter);
      await _loadSavedFilters();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Фильтр "$filterName" сохранен'),
            backgroundColor: Color(0xFF2A9D8F),
          ),
        );
      }
    }
  }

  /// Показывает диалог сохранения фильтра
  Future<String?> _showSaveFilterDialog() async {
    _filterNameController.clear();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сохранить фильтр'),
        content: TextField(
          controller: _filterNameController,
          decoration: InputDecoration(
            labelText: 'Название фильтра',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _filterNameController.text),
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
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
          'Фильтры',
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
          IconButton(
            icon: Icon(Icons.save_outlined, color: Colors.white),
            onPressed: _saveFilter,
            tooltip: 'Сохранить фильтр',
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameFilter(),
                  SizedBox(height: 24),
                  _buildExpirationFilter(),
                  SizedBox(height: 24),
                  _buildQuantityFilter(),
                  SizedBox(height: 24),
                  _buildSavedFilters(),
                  SizedBox(height: 100), // Отступ для кнопок
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  /// Виджет фильтра по названию
  Widget _buildNameFilter() {
    return _buildFilterSection(
      title: 'Поиск по названию',
      icon: Icons.search,
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Введите название продукта...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _currentFilter = _currentFilter.copyWith(nameFilter: value);
          });
        },
      ),
    );
  }

  /// Виджет фильтра по сроку годности
  Widget _buildExpirationFilter() {
    return _buildFilterSection(
      title: 'Срок годности',
      icon: Icons.schedule,
      child: Column(
        children: [
          ...ExpirationFilterType.values.map((type) {
            return RadioListTile<ExpirationFilterType>(
              title: Text(
                FilterService.getExpirationFilterDisplayName(type),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              value: type,
              groupValue: _currentFilter.expirationFilter?.type,
              onChanged: (value) {
                setState(() {
                  if (value == ExpirationFilterType.customDays) {
                    _currentFilter = _currentFilter.copyWith(
                      expirationFilter: ExpirationFilter(
                        type: value!,
                        days: 7,
                      ),
                    );
                  } else {
                    _currentFilter = _currentFilter.copyWith(
                      expirationFilter: ExpirationFilter(type: value!),
                    );
                  }
                });
              },
              activeColor: Color(0xFF2A9D8F),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            );
          }),
          if (_currentFilter.expirationFilter?.type == ExpirationFilterType.customDays)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _customDaysController,
                decoration: InputDecoration(
                  labelText: 'Количество дней',
                  border: OutlineInputBorder(),
                  suffixText: 'дней',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null) {
                    setState(() {
                      _currentFilter = _currentFilter.copyWith(
                        expirationFilter: ExpirationFilter(
                          type: ExpirationFilterType.customDays,
                          days: days,
                        ),
                      );
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Виджет фильтра по количеству
  Widget _buildQuantityFilter() {
    return _buildFilterSection(
      title: 'Количество',
      icon: Icons.scale,
      child: Column(
        children: [
          // Условие сравнения
          DropdownButtonFormField<QuantityComparisonType>(
            value: _currentFilter.quantityFilter?.comparisonType ?? 
                   QuantityComparisonType.greaterThan,
            decoration: InputDecoration(
              labelText: 'Условие',
              border: OutlineInputBorder(),
            ),
            items: QuantityComparisonType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  FilterService.getQuantityComparisonDisplayName(type),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentFilter = _currentFilter.copyWith(
                    quantityFilter: QuantityFilter(
                      comparisonType: value,
                      value: _currentFilter.quantityFilter?.value ?? 1.0,
                      unit: _selectedUnit,
                    ),
                  );
                });
              }
            },
          ),
          SizedBox(height: 16),
          // Значение и единица измерения
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Значение',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final quantity = double.tryParse(value);
                    if (quantity != null) {
                      setState(() {
                        _currentFilter = _currentFilter.copyWith(
                          quantityFilter: QuantityFilter(
                            comparisonType: _currentFilter.quantityFilter?.comparisonType ?? 
                                           QuantityComparisonType.greaterThan,
                            value: quantity,
                            unit: _selectedUnit,
                          ),
                        );
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Ед.',
                    border: OutlineInputBorder(),
                  ),
                  items: FilterService.getSupportedUnits().map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(
                        unit,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnit = value;
                        if (_currentFilter.quantityFilter != null) {
                          _currentFilter = _currentFilter.copyWith(
                            quantityFilter: QuantityFilter(
                              comparisonType: _currentFilter.quantityFilter!.comparisonType,
                              value: _currentFilter.quantityFilter!.value,
                              unit: value,
                            ),
                          );
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Виджет сохраненных фильтров
  Widget _buildSavedFilters() {
    if (_savedFilters.isEmpty) {
      return SizedBox.shrink();
    }

    return _buildFilterSection(
      title: 'Сохраненные фильтры',
      icon: Icons.bookmark,
      child: Column(
        children: _savedFilters.entries.map((entry) {
          final filter = entry.value;
          return ListTile(
            title: Text(
              entry.key,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _getFilterDescription(filter),
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteSavedFilter(entry.key),
            ),
            onTap: () => _loadSavedFilter(filter),
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          );
        }).toList(),
      ),
    );
  }

  /// Получает описание фильтра для отображения
  String _getFilterDescription(ProductFilter filter) {
    final parts = <String>[];
    
    if (filter.nameFilter != null && filter.nameFilter!.isNotEmpty) {
      parts.add('Название: ${filter.nameFilter}');
    }
    
    if (filter.expirationFilter != null) {
      parts.add('Срок: ${FilterService.getExpirationFilterDisplayName(filter.expirationFilter!.type)}');
    }
    
    if (filter.quantityFilter != null) {
      parts.add('Количество: ${FilterService.getQuantityComparisonDisplayName(filter.quantityFilter!.comparisonType)} ${filter.quantityFilter!.value} ${filter.quantityFilter!.unit}');
    }
    
    return parts.join(', ');
  }

  /// Загружает сохраненный фильтр
  void _loadSavedFilter(ProductFilter filter) {
    setState(() {
      _currentFilter = filter;
      _initializeControllers();
    });
  }

  /// Удаляет сохраненный фильтр
  Future<void> _deleteSavedFilter(String filterName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить фильтр'),
        content: Text('Вы уверены, что хотите удалить фильтр "$filterName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FilterService.deleteSavedFilter(filterName);
      await _loadSavedFilters();
    }
  }

  /// Виджет секции фильтра
  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2D3748).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF2A9D8F), size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  /// Виджет нижних кнопок действий
  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetFilter,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Color(0xFF2A9D8F)),
                ),
                child: Text(
                  'Сбросить',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2A9D8F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Применить фильтр',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 