import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  _FavouritesPageState createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser"; 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade400,
        title: Text("Favorites", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .orderBy('savedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.white54),
                  SizedBox(height: 20),
                  Text("No favorites yet", 
                      style: TextStyle(color: Colors.white70, fontSize: 18)),
                  Text("Tap the heart icon on recipes to save them here",
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          final favorites = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final data = favorites[index].data() as Map<String, dynamic>;
              return _buildFavoriteRecipeCard(
                image: data['image'],
                title: data['title'],
                time: data['time'],
                servings: data['servings'],
                rating: data['rating'],
                reviews: data['reviews'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteRecipeCard({
    required String image,
    required String title,
    required String time,
    required String servings,
    required String rating,
    required String reviews,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
                bottomLeft: Radius.circular(12),
              ),
              image: DecorationImage(
                image: NetworkImage(image), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "$time • $servings servings", 
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(
                        " $rating ($reviews reviews)", 
                        style: TextStyle(color: Colors.white54),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.favorite, color: Colors.orangeAccent),
                        onPressed: () async {
                          final userId = FirebaseAuth.instance.currentUser?.uid ?? "testUser";
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('favorites')
                              .doc(title)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}