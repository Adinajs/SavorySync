import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeCategoriesPage extends StatefulWidget {
  const RecipeCategoriesPage({super.key});

  @override
  _RecipeCategoriesPageState createState() => _RecipeCategoriesPageState();
}

class _RecipeCategoriesPageState extends State<RecipeCategoriesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Recipe Categories', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange.shade400,
        centerTitle: true,
        elevation: 6,
        shadowColor: Colors.deepOrangeAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDescription(),
              _buildSectionTitle('Meal Type'),
              _buildCategoryGrid(['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Appetizers', 'Salads', 'Soups']),
              _buildSectionTitle('Cuisine'),
              _buildCategoryGrid(['Italian', 'Indian', 'Mexican','Chinese']),
              _buildSectionTitle('Dietary'),
              _buildCategoryGrid(['Vegetarian', 'Vegan', 'Gluten-Free', 'Keto']),
              _buildSectionTitle('Other'),
              _buildCategoryGrid(['Quick Meals']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() => Column(
    children: [
      Text(
        'Browse our recipes by category and find your next favorite meal!',
        style: TextStyle(fontSize: 16, color: Colors.grey[300], fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 20),
      Divider(thickness: 2, color: Colors.orange.shade700),
      SizedBox(height: 20),
    ],
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade300),
    ),
  );

  Widget _buildCategoryGrid(List<String> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) => _buildCategoryCard(categories[index]),
    );
  }

  Widget _buildCategoryCard(String category) {
    return GestureDetector(
      onTap: () => _navigateToCategoryRecipes(category),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.deepOrange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 8, offset: Offset(3, 3)),
            ],
          ),
          child: Center(
            child: Text(
              '${getEmoji(category)}\n$category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryRecipes(String category) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final querySnapshot = await _firestore.collection('recipes').get();

      List<Recipe> recipes = [];

      for (var doc in querySnapshot.docs) {
        List<dynamic> tags = doc['tags'] ?? [];

        if (tags.any((tag) => tag.toString().toLowerCase() == category.toLowerCase())) {
          recipes.add(Recipe(
            id: doc.id,
            title: doc['title'] ?? 'No Title',
            category: tags.join(', '),
            imageUrl: doc['image'] ?? '',
            prepTime: doc['time'] ?? 'N/A',
          ));
        }
      }

      Navigator.pop(context);

      if (recipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No recipes found for $category.')),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryRecipesPage(
              category: category,
              recipes: recipes,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recipes: $e')),
      );
    }
  }

  String getEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast': return '🍳';
      case 'lunch': return '🥪';
      case 'dinner': return '🍽️';
      case 'dessert': return '🍰';
      case 'appetizers': return '🍢';
      case 'salads': return '🥗';
      case 'soups': return '🍜';
      case 'italian': return '🍝';
      case 'mexican': return '🌮';
      case 'indian': return '🍛';
      case 'vegetarian': return '🥦';
      case 'vegan': return '🌱';
      case 'gluten-free': return '🚫🌾';
      case 'keto': return '🥩';
      case 'quick meals': return '⏳';
      default: return '🍽️';
    }
  }
}

class Recipe {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String prepTime;

  Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.prepTime,
  });
}

class CategoryRecipesPage extends StatefulWidget {
  final String category;
  final List<Recipe> recipes;

  const CategoryRecipesPage({
    super.key,
    required this.category,
    required this.recipes,
  });

  @override
  State<CategoryRecipesPage> createState() => _CategoryRecipesPageState();
}

class _CategoryRecipesPageState extends State<CategoryRecipesPage> {
  String searchQuery = '';
  List<String> favoriteRecipeIds = [];

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = widget.recipes
        .where((r) => r.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.category} Recipes'),
        backgroundColor: Colors.deepOrange.shade400,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: filteredRecipes.isEmpty
                ? Center(child: Text('No recipes found for "$searchQuery".', style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      final isFav = favoriteRecipeIds.contains(recipe.id);

                      return Card(
                        color: Colors.grey[850],
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          leading: Hero(
                            tag: recipe.imageUrl,
                            child: recipe.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      recipe.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(Icons.fastfood, color: Colors.orange, size: 40),
                          ),
                          title: Text(recipe.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Prep Time: ${recipe.prepTime}', style: TextStyle(color: Colors.grey[400])),
                          trailing: IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey),
                            onPressed: () {
                              setState(() {
                                isFav
                                    ? favoriteRecipeIds.remove(recipe.id)
                                    : favoriteRecipeIds.add(recipe.id);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}