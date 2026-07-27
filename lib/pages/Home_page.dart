import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:savorysync/pages/categories_page.dart';
import 'package:savorysync/pages/profile_page.dart';
import 'package:savorysync/pages/meal_planner_page.dart';
import 'package:savorysync/pages/favorites_page.dart';
import 'package:savorysync/pages/recipe_Details.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _heroRecipeTimer;
  Map<String, dynamic>? _currentHeroRecipe;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showSearchBar = false;
  List<Map<String, dynamic>> _allRecipes = [];
  List<Map<String, dynamic>> _displayedRecipes = [];
  
  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  final List<Map<String, dynamic>> hardcodedRecipes = [
    {
      'title': 'Avocado Toast with Poached Egg',
      'tags': ['Breakfast', 'Vegetarian', 'Quick Meals'],
      'time': '10 min',
      'servings': '1',
      'rating': '4.8',
      'reviews': '124',
      'image': 'https://bing.com/th?id=OSK.83bf884c6911082e8069f3e461cf84a4',
      'description': 'A delicious and healthy breakfast option.',
      'ingredients': [
        '1 ripe avocado',
        '2 eggs',
        '2 slices whole grain bread'
      ],
      'instructions': [
        'Toast the bread',
        'Prepare avocado',
        'Poach eggs'
      ],
      'nutrition': {
        'Calories': '350 kcal',
        'Protein': '14 g'
      }
    },
    {
      'title': 'Grilled Salmon',
      'tags': ['Dinner', 'Gluten-Free'],
      'time': '25 min',
      'servings': '2',
      'rating': '4.7',
      'reviews': '156',
      'image': 'https://bing.com/th?id=OSK.e252216053836f09c360d04b789439af',
      'description': 'Perfectly grilled salmon fillets.',
      'ingredients': [
        '2 salmon fillets',
        '2 tbsp olive oil',
        '1 lemon'
      ],
      'instructions': [
        'Preheat grill',
        'Season salmon',
        'Grill for 4-5 minutes'
      ],
      'nutrition': {
        'Calories': '320 kcal',
        'Protein': '34 g'
      }
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndAddData();
    _startHeroRecipeTimer();
    _searchController.addListener(_handleSearchChange);
    _initSpeech();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) => print('Error: $error'),
      );
      print('Speech available: $available');
    } catch (e) {
      print('Speech init error: $e');
    }
  }

  void _handleSearchChange() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _displayedRecipes = List.from(_allRecipes);
      });
    } else {
      _filterRecipes();
    }
  }

  void _filterRecipes() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      _displayedRecipes = _allRecipes.where((recipe) {
        return recipe['title'].toLowerCase().contains(searchText) ||
               (recipe['tags'] as List).any((tag) => tag.toLowerCase().contains(searchText)) ||
               recipe['description'].toLowerCase().contains(searchText);
      }).toList();
      _isSearching = searchText.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _heroRecipeTimer?.cancel();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initializeFirebaseAndAddData() async {
    await Firebase.initializeApp();
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    if (snapshot.docs.isEmpty) {
      for (var recipe in hardcodedRecipes) {
        await FirebaseFirestore.instance.collection('recipes').add(recipe);
      }
    }
  }

 Future<Map<String, dynamic>?> _getRandomHeroRecipe() async {
  final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
  if (snapshot.docs.isEmpty) return null;
  final randomDoc = snapshot.docs[DateTime.now().millisecondsSinceEpoch % snapshot.docs.length];
  return randomDoc.data();
}

  void _startHeroRecipeTimer() async {
    _currentHeroRecipe = await _getRandomHeroRecipe();
    setState(() {});
    _heroRecipeTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final newRecipe = await _getRandomHeroRecipe();
      if (mounted && newRecipe != null) {
        setState(() => _currentHeroRecipe = newRecipe);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _isSearching = false;
      }
    });
  }

  Future<void> _listen() async {
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
      if (!await Permission.microphone.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission required')));
        return;
      }
    }

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            if (result.finalResult) {
              _searchController.text = _lastWords;
              _filterRecipes();
            }
          });
        },
        listenFor: Duration(seconds: 10),
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.orange),
                SizedBox(width: 10),
                Text('SavorySync', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
          _buildDrawerItem(Icons.grid_view, 'Categories', () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeCategoriesPage()))),
          _buildDrawerItem(Icons.favorite, 'Favorite', () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavouritesPage()))),
          _buildDrawerItem(Icons.calendar_month, 'Meal Calendar', () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlannerPage()))),
          _buildDrawerItem(Icons.person, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()))),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: _showSearchBar 
          ? TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            )
          : Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.orange),
                SizedBox(width: 10),
                Text("SavorySync", style: TextStyle(color: Colors.white)),
              ],
            ),
      actions: [
        if (_showSearchBar)
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: _isListening ? Colors.red : Colors.white),
            onPressed: _listen,
          ),
        IconButton(
          icon: Icon(_showSearchBar ? Icons.close : Icons.search, color: Colors.white),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showSearchBar) _buildHeroSection(),
          if (!_showSearchBar) SizedBox(height: 20),
          _buildSearchSection(),
          SizedBox(height: 30),
          _buildRecipeList(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return _currentHeroRecipe != null
        ? _buildHeroRecipeCard(MediaQuery.of(context).size.height, _currentHeroRecipe!)
        : Center(child: CircularProgressIndicator());
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showSearchBar) Text("Find a Recipe", style: TextStyle(color: Colors.white, fontSize: 20)),
        if (!_showSearchBar) SizedBox(height: 10),
        if (!_showSearchBar)
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: Icon(Icons.search, color: Colors.white),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () => _searchController.clear(),
                    ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: _isListening ? Colors.red : Colors.white),
                    onPressed: _listen,
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintStyle: TextStyle(color: Colors.white70),
            ),
            style: TextStyle(color: Colors.white),
          ),
        if (!_showSearchBar) SizedBox(height: 20),
        if (!_showSearchBar)
          Wrap(
            spacing: 10,
            children: ['Breakfast', 'Lunch', 'Dinner', 'Dessert'].map((cat) => _buildCategoryChip(cat)).toList(),
          ),
      ],
    );
  }

  Widget _buildRecipeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        _allRecipes = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        if (_searchController.text.isEmpty) {
          _displayedRecipes = List.from(_allRecipes);
        }

        return Column(
          children: [
            if (_isSearching)
              Text('Found ${_displayedRecipes.length} recipes', style: TextStyle(color: Colors.white70)),
            if (_isSearching && _displayedRecipes.isEmpty)
              Text('No recipes found', style: TextStyle(color: Colors.white70)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _displayedRecipes.length,
              itemBuilder: (context, index) => _buildRecipeCard(_displayedRecipes[index]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildCategoryChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.deepOrange,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  Widget _buildHeroRecipeCard(double height, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: data))),
      child: Container(
        height: height * 0.35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: NetworkImage(data['image']), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: (data['tags'] as List).map((tag) => _buildCategoryChip(tag)).toList(),
              ),
              SizedBox(height: 10),
              Text(data['title'], style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(data['description'], style: TextStyle(color: Colors.white70), maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> data) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(data['title']);

    return FutureBuilder<DocumentSnapshot>(
      future: favoritesRef.get(),
      builder: (context, snapshot) {
        final isFavorite = snapshot.hasData && snapshot.data!.exists;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: data))),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12)),
                    image: DecorationImage(image: NetworkImage(data['image']), fit: BoxFit.cover),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: (data['tags'] as List).map((tag) => _buildCategoryChip(tag)).toList(),
                        ),
                        Text(data['title'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("${data['time']} • ${data['servings']} servings", style: TextStyle(color: Colors.white70)),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 16),
                            Text(" ${data['rating']} (${data['reviews']} reviews)", style: TextStyle(color: Colors.white54)),
                            Spacer(),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.orangeAccent : Colors.white54,
                              ),
                              onPressed: () async {
                                if (isFavorite) {
                                  await favoritesRef.delete();
                                } else {
                                  await favoritesRef.set({
                                    ...data,
                                    'savedAt': FieldValue.serverTimestamp(),
                                  });
                                }
                                if (mounted) setState(() {});
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 40, horizontal: 25),
    color: Colors.grey[850],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.orangeAccent, size: 30),
            SizedBox(width: 10),
            Text(
              "SavorySync",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        Text(
          "Discover delicious recipes based on the ingredients you have at home.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 25),
        Row(
          children: [
            Icon(Icons.email, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              "Contact us",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.copyright, color: Colors.orangeAccent, size: 16),
            SizedBox(width: 6),
            Text(
              "2025 SavorySync. All rights reserved.",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

}