import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShoppingListContent extends StatefulWidget {
  const ShoppingListContent({super.key});

  @override
  State<ShoppingListContent> createState() => _ShoppingListContentState();
}

class _ShoppingListContentState extends State<ShoppingListContent> {
  final Map<String, bool> _checkedItems = {
    'Olive oil (2 bottles)': false,
    'Salt (1 tsp)': false,
    'Black pepper (1/2 tsp)': false,
    'Garlic (3 cloves)': false,
    'Onions (2)': false,
    'Tomatoes (4)': false,
    'Bell peppers (2)': false,
    'Chicken breast (1 lb)': false,
    'Ground beef (1 lb)': false,
    'Pasta (16 oz)': false,
    'Rice (2 cups)': false,
    'Cheese (8 oz)': false,
    'Eggs (12)': false,
    'Milk (1 carton)': false,
    'Bread (1 loaf)': false,
  };

  final Map<String, String> _itemCategories = {
    'Olive oil (2 bottles)': 'Oil & Condiments',
    'Salt (1 tsp)': 'Spices',
    'Black pepper (1/2 tsp)': 'Spices',
    'Garlic (3 cloves)': 'Vegetables',
    'Onions (2)': 'Vegetables',
    'Tomatoes (4)': 'Vegetables',
    'Bell peppers (2)': 'Vegetables',
    'Chicken breast (1 lb)': 'Meat & Seafood',
    'Ground beef (1 lb)': 'Meat & Seafood',
    'Pasta (16 oz)': 'Grains & Pasta',
    'Rice (2 cups)': 'Grains & Pasta',
    'Cheese (8 oz)': 'Dairy',
    'Eggs (12)': 'Dairy',
    'Milk (1 carton)': 'Dairy',
    'Bread (1 loaf)': 'Bakery',
  };

  bool _isGenerating = false;
  final TextEditingController _itemController = TextEditingController();
  final List<String> _categories = [
    'Oil & Condiments',
    'Spices',
    'Vegetables',
    'Meat & Seafood',
    'Grains & Pasta',
    'Dairy',
    'Bakery',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCheckedItems();
  }

  void _loadCheckedItems() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedItems = prefs.getString('checkedItems');
    String? savedCategories = prefs.getString('itemCategories');
    
    if (savedItems != null) {
      final Map<String, dynamic> decodedMap = json.decode(savedItems);
      setState(() {
        _checkedItems.addAll(Map<String, bool>.from(decodedMap));
      });
    }
    
    if (savedCategories != null) {
      final Map<String, dynamic> decodedCategories = json.decode(savedCategories);
      setState(() {
        _itemCategories.addAll(Map<String, String>.from(decodedCategories));
      });
    }
  }

  void _saveCheckedItems() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedMap = json.encode(_checkedItems);
    String encodedCategories = json.encode(_itemCategories);
    await prefs.setString('checkedItems', encodedMap);
    await prefs.setString('itemCategories', encodedCategories);
  }

  void _clearAllCheckedItems() {
    setState(() {
      for (var key in _checkedItems.keys) {
        _checkedItems[key] = false;
      }
    });
    _saveCheckedItems();
  }

  void _generateShoppingList() {
    setState(() => _isGenerating = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shopping list generated!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepOrange.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _isGenerating = false);
    });
  }

  void _addItem(String item, String category) {
    if (item.trim().isEmpty) return;
    setState(() {
      _checkedItems[item.trim()] = false;
      _itemCategories[item.trim()] = category;
    });
    _itemController.clear();
    _saveCheckedItems();
  }

  void _deleteItem(String item) {
    setState(() {
      _checkedItems.remove(item);
      _itemCategories.remove(item);
    });
    _saveCheckedItems();
  }

  void _editItem(String oldItem, String newItem, String category) {
    if (oldItem == newItem && _itemCategories[oldItem] == category) return;
    
    setState(() {
      bool isChecked = _checkedItems[oldItem] ?? false;
      _checkedItems.remove(oldItem);
      _itemCategories.remove(oldItem);
      _checkedItems[newItem] = isChecked;
      _itemCategories[newItem] = category;
    });
    _saveCheckedItems();
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    String selectedCategory = 'Other';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item', style: TextStyle(color: Colors.deepOrange)),
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.deepOrange, width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Item name',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepOrange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: const TextStyle(color: Colors.deepOrange),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color:Colors.deepOrange),
                ),
              ),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.deepOrange)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addItem(controller.text.trim(), selectedCategory);
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String currentItem) {
    final controller = TextEditingController(text: currentItem);
    String selectedCategory = _itemCategories[currentItem] ?? 'Other';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item', style: TextStyle(color: Colors.deepOrange)),
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color:Colors.deepOrange, width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Item name',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color:Colors.deepOrange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: const TextStyle(color: Colors.deepOrange),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepOrange),
                ),
              ),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.deepOrange)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _editItem(currentItem, controller.text.trim(), selectedCategory);
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.deepOrange.shade400,
        title: const Text('Shopping List', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart,
                color: _isGenerating ? Colors.deepOrange.shade400 : Colors.white),
            onPressed: _generateShoppingList,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.deepOrange),
            onPressed: _clearAllCheckedItems,
            tooltip: 'Clear all checkmarks',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange.shade400,
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.grey[800]!,
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTitleBox(),
              const SizedBox(height: 16),
              ..._buildAllSections(),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.shade400, width: 1),
      ),
      child: const Center(
        child: Text(
          'MY LIST',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAllSections() {
    List<Widget> sections = [];
    
    // Build sections for each category
    for (var category in _categories) {
      List<String> itemsInCategory = _itemCategories.entries
          .where((entry) => entry.value == category)
          .map((entry) => entry.key)
          .where((item) => _checkedItems.containsKey(item))
          .toList();
      
      if (itemsInCategory.isNotEmpty) {
        sections.add(_buildSection(category, itemsInCategory));
      }
    }
    
    return sections;
  }

  Widget _buildSection(String title, List<String> items) {
    IconData? icon;
    switch (title) {
      case 'Oil & Condiments':
        icon = Icons.local_bar;
        break;
      case 'Spices':
        icon = Icons.energy_savings_leaf;
        break;
      case 'Vegetables':
        icon = Icons.eco;
        break;
      case 'Meat & Seafood':
        icon = Icons.set_meal;
        break;
      case 'Grains & Pasta':
        icon = Icons.grain;
        break;
      case 'Dairy':
        icon = Icons.egg;
        break;
      case 'Bakery':
        icon = Icons.breakfast_dining;
        break;
      default:
        icon = Icons.shopping_basket;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepOrange.shade400),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildItemBox(item)),
      ],
    );
  }

  Widget _buildItemBox(String text) {
    return Dismissible(
      key: Key(text),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.red[800],
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Are you sure you want to delete "$text"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteItem(text),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Checkbox(
            value: _checkedItems[text],
            onChanged: (val) {
              setState(() {
                _checkedItems[text] = val ?? false;
              });
              _saveCheckedItems();
            },
            activeColor: Colors.deepOrange.shade400,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              decoration: _checkedItems[text]! 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.deepOrange, size: 20),
            onPressed: () => _showEditDialog(text),
          ),
        ),
      ),
    );
  }
}