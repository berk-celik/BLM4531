import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeService {
  final recipesCollection = FirebaseFirestore.instance.collection('recipes');
  final usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> addRecipe({
    required String title,
    required String ingredients,
    required String instructions,
    required String userId,
    String? imageURL,
  }) async {
    try {
      await recipesCollection.add({
        'title': title,
        'ingredients': ingredients,
        'instructions': instructions,
        'userId': userId,
        'imageURL': imageURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Recipe added successfully!");
    } catch (e) {
      print("Error adding recipe: $e");
      rethrow;
    }
  }

  Future<void> addToFavorites(String userId, String recipeId) async {
    try {
      final userDocRef = usersCollection.doc(userId);
      await userDocRef.update({
        'favorites': FieldValue.arrayUnion([recipeId]),
      });
    } catch (e) {
      print("Error adding recipe to favorites: $e");
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String userId, String recipeId) async {
    try {
      final userDocRef = usersCollection.doc(userId);
      await userDocRef.update({
        'favorites': FieldValue.arrayRemove([recipeId]),
      });
    } catch (e) {
      print("$e");
      rethrow;
    }
  }
}
