import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool isFavorite = false;
  late Map<String, dynamic> recipe;
  bool _isLoading = false;

  // For Community Reviews
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    recipe = widget.recipe;
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(recipe['title']);

    final doc = await favoritesRef.get();
    if (mounted) {
      setState(() {
        isFavorite = doc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
      final favoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(recipe['title']);

      if (isFavorite) {
        await favoritesRef.delete();
      } else {
        await favoritesRef.set({
          ...recipe,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          isFavorite = !isFavorite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_userRating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a rating and a comment.')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final reviewRef = FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipe['title'])
          .collection('reviews')
          .doc();

      await reviewRef.set({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'rating': _userRating,
        'comment': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _reviewController.clear();
      setState(() {
        _userRating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          recipe['title'],
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.orange : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroImage(),

            // Recipe Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Description'),
                  SizedBox(height: 8),
                  Text(
                    recipe['description'] ?? 'A delicious ${recipe['title']} recipe.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 24),

                  _buildSectionHeader('Ingredients'),
                  SizedBox(height: 8),
                  ..._buildIngredientsList(),
                  SizedBox(height: 24),

                  _buildSectionHeader('Instructions'),
                  SizedBox(height: 8),
                  ..._buildInstructionsList(),
                  SizedBox(height: 24),

                  _buildSectionHeader('Nutrition Information'),
                  SizedBox(height: 8),
                  _buildNutritionTable(),
                  SizedBox(height: 24),

                  _buildSectionHeader('Community Reviews & Ratings'),
                  SizedBox(height: 16),
                  _buildReviewInput(),
                  SizedBox(height: 24),
                  _buildReviewsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Hero(
      tag: 'recipe-${recipe['title']}',
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(recipe['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (recipe['tags'] as List<dynamic>)
                        .map((tag) => Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(tag.toString()),
                                backgroundColor: Colors.deepOrange,
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '${recipe['rating']} (${recipe['reviews']} reviews)',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.timer, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text(recipe['time'], style: TextStyle(color: Colors.white70)),
                    SizedBox(width: 16),
                    Icon(Icons.people, color: Colors.white70, size: 20),
                    SizedBox(width: 4),
                    Text(recipe['servings'], style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(Icons.restaurant_menu, color: Colors.orange, size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildIngredientsList() {
    List<dynamic> ingredients = recipe['ingredients'] ?? ['No ingredients listed'];

    return ingredients
        .map((ingredient) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4, right: 8),
                    child: Icon(Icons.circle, size: 8, color: Colors.orange),
                  ),
                  Expanded(
                    child: Text(
                      ingredient.toString(),
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  List<Widget> _buildInstructionsList() {
    List<dynamic> instructions = recipe['instructions'] ?? ['No instructions provided'];

    return instructions
        .asMap()
        .map((index, instruction) => MapEntry(
              index,
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction.toString(),
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .values
        .toList();
  }

  Widget _buildNutritionTable() {
    Map<String, dynamic> nutrition = recipe['nutrition'] ?? {
      'Calories': 'Not available',
      'Protein': 'Not available',
      'Carbs': 'Not available',
      'Fat': 'Not available'
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: nutrition.entries
            .map((entry) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Rating:', style: TextStyle(color: Colors.white, fontSize: 18)),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                _userRating > index ? Icons.star : Icons.star_border,
                color: Colors.orange,
              ),
              onPressed: () {
                setState(() {
                  _userRating = (index + 1).toDouble();
                });
              },
            );
          }),
        ),
        TextField(
          controller: _reviewController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write your review...',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Submit Review'),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipe['title'])
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Text('No reviews yet.', style: TextStyle(color: Colors.white70));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: Icon(Icons.person, color: Colors.orange),
              title: Text(
                data['userEmail'] ?? 'Anonymous',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        data['rating'] > index ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 16,
                      );
                    }),
                  ),
                  SizedBox(height: 4),
                  Text(
                    data['comment'] ?? '',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}