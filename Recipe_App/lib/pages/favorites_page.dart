import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deneme/pages/recipe_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<String>> _fetchFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        List<dynamic> favoriteIds = userDoc['favorites'] ?? [];
        return favoriteIds.cast<String>();
      }
      return <String>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        body: Center(child: Text("Kullanıcı giriş yapmamış.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoriler"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<String>>(
        stream: _fetchFavorites(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Favorileriniz boş"));
          }

          final favoriteRecipeIds = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('recipes')
                .where(FieldPath.documentId,
                    whereIn: favoriteRecipeIds.length > 10
                        ? favoriteRecipeIds.sublist(0, 10)
                        : favoriteRecipeIds)
                .snapshots(),
            builder: (context, recipesSnapshot) {
              if (recipesSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final recipes = recipesSnapshot.data!.docs;

              return ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final imageUrl = recipe['imageURL'];

                  return ListTile(
                    leading: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image_not_supported),
                    title: Text(recipe['title']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailPage(
                            title: recipe['title'],
                            ingredients: recipe['ingredients'],
                            instructions: recipe['instructions'],
                            userId: userId,
                            imageURL: recipe['imageURL'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
