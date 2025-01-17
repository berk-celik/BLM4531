import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:deneme/recipe_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deneme/pages/recipe_page.dart';

class RecipeListPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RecipeService _recipeService = RecipeService();

  Stream<List<Map<String, dynamic>>> _fetchRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'title': doc['title'],
              'ingredients': doc['ingredients'],
              'instructions': doc['instructions'],
              'userId': doc['userId'],
              'imageURL': doc['imageURL'],
            };
          }).toList(),
        );
  }

  Future<String> _getUsername(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc['username'];
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Stream<bool> _isFavorite(String currentUserId, String recipeId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        List<dynamic> favorites = userDoc['favorites'] ?? [];
        return favorites.contains(recipeId);
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Tarifler"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Henüz tarif eklenmemiş."));
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final recipeId = recipe['id'];
              return FutureBuilder<String>(
                future: _getUsername(recipe['userId']),
                builder: (context, usernameSnapshot) {
                  if (usernameSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text(recipe['title']),
                      subtitle: Text('Yazar: yükleniyor...'),
                    );
                  }

                  final username = usernameSnapshot.data ?? 'Unknown';
                  return ListTile(
                    title: Text(recipe['title']),
                    subtitle: Text('Yazar: $username'),
                    // ignore: unnecessary_null_comparison
                    trailing: currentUserId != null
                        ? StreamBuilder<bool>(
                            stream: _isFavorite(currentUserId, recipeId),
                            builder: (context, isFavoriteSnapshot) {
                              if (isFavoriteSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Icon(Icons.favorite_border);
                              }

                              bool isFavorite =
                                  isFavoriteSnapshot.data ?? false;

                              return IconButton(
                                icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : null),
                                onPressed: () async {
                                  if (isFavorite) {
                                    await _recipeService.removeFromFavorites(
                                        currentUserId, recipeId);
                                  } else {
                                    await _recipeService.addToFavorites(
                                        currentUserId, recipeId);
                                  }
                                },
                              );
                            },
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailPage(
                            title: recipe['title'],
                            ingredients: recipe['ingredients'],
                            instructions: recipe['instructions'],
                            userId: currentUserId,
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
