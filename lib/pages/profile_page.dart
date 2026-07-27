import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User and UI state
  User? _user;
  File? _profileImage;
  bool _isEditingProfile = false;
  bool _isUploading = false;
  String? _base64Image;

  // Controllers
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Services
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login',
            (route) => false,
          );
        });
      } else {
        _nameController.text = _user?.displayName ?? '';
        await _loadProfileImage();
      }
    } catch (e) {
      _showErrorSnackbar('Error initializing user: ${e.toString()}');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final base64String = doc.data()?['profileImage'] as String?;
        if (base64String != null) {
          setState(() {
            _base64Image = base64String;
          });
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load profile image: ${e.toString()}');
    }
  }

  Future<void> _pickAndConvertImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _profileImage = File(pickedFile.path);
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackbar('Name cannot be empty');
      return;
    }

    try {
      setState(() => _isUploading = true);

      // Update display name in Firebase Auth
      await _user?.updateDisplayName(_nameController.text);

      // Save profile image to Firestore if it exists
      if (_base64Image != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({
              'profileImage': _base64Image,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      // Reload user data
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;

      _showSuccessSnackbar('Profile updated successfully!');
    } catch (e) {
      _showErrorSnackbar('Failed to update profile: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
        _isEditingProfile = false;
      });
    }
  }

  Future<void> _addRecipe() async {
    if (_titleController.text.isEmpty || _imageUrlController.text.isEmpty) {
      _showErrorSnackbar('Title and Image URL are required');
      return;
    }

    try {
      setState(() => _isUploading = true);
      
      await FirebaseFirestore.instance
          .collection('saved_recipes')
          .doc(_user!.uid)
          .collection('recipes')
          .add({
        'title': _titleController.text,
        'description': _descController.text,
        'image': _imageUrlController.text,
        'createdAt': Timestamp.now(),
      });

      _titleController.clear();
      _descController.clear();
      _imageUrlController.clear();

      _showSuccessSnackbar('Recipe added successfully!');
    } catch (e) {
      _showErrorSnackbar('Failed to add recipe: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      _showErrorSnackbar('Logout failed: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
    ));
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.deepOrange.shade400,
          title: Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ),
        body: _isUploading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileSection(),
                    SizedBox(height: 30),
                    _buildAddRecipeSection(),
                    SizedBox(height: 30),
                    _buildMyRecipesSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileSection() {
    Uint8List? imageBytes;
    if (_base64Image != null) {
      imageBytes = base64Decode(_base64Image!);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                    : imageBytes != null
                        ? Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            if (_isEditingProfile)
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.orange,
                onPressed: _pickAndConvertImage,
                child: Icon(Icons.camera_alt, size: 20),
              ),
          ],
        ),
        SizedBox(height: 15),
        if (!_isEditingProfile)
          Column(
            children: [
              Text(
                _user?.displayName ?? 'User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                _user?.email ?? 'No email',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => setState(() => _isEditingProfile = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text("Edit Profile"),
              ),
            ],
          )
        else
          Column(
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: Colors.orange),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("Save"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _isEditingProfile = false;
                      _profileImage = null;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        Divider(color: Colors.white24),
      ],
    );
  }

  Widget _buildAddRecipeSection() {
    return Card(
      color: Colors.grey[850],
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add Your Recipe",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _titleController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Recipe Title",
                labelStyle: TextStyle(color: Colors.orange),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: Colors.orange),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _imageUrlController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Image URL",
                labelStyle: TextStyle(color: Colors.orange),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                hintText: "https://example.com/image.jpg",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            SizedBox(height: 15),
            if (_imageUrlController.text.isNotEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _imageUrlController.text,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Text(
                            "Invalid Image URL",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: _addRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Share Recipe",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRecipesSection() {
    return Column(
      children: [
        Text(
          "My Recipes",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('saved_recipes')
              .doc(_user!.uid)
              .collection('recipes')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "You haven't shared any recipes yet!",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        doc['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: Icon(Icons.broken_image, color: Colors.white),
                          );
                        },
                      ),
                    ),
                    title: Text(doc['title'], style: TextStyle(color: Colors.white)),
                    subtitle: Text(doc['description'], style: TextStyle(color: Colors.white70)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}