import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:deneme/recipe_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final String title;
  final String ingredients;
  final String instructions;
  final String userId;
  final String? imageURL;

  RecipeDetailPage({
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.userId,
    this.imageURL,
    Key? key,
  }) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _commentController = TextEditingController();

  Future<String?> _fetchRecipeId() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('recipes')
          .where('title', isEqualTo: widget.title)
          .where('ingredients', isEqualTo: widget.ingredients)
          .where('instructions', isEqualTo: widget.instructions)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
    } catch (e) {
      print('$e');
    }
    return null;
  }

  Stream<bool> _isFavorite(String recipeId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        List<dynamic> favorites = userDoc['favorites'] ?? [];
        return favorites.contains(recipeId);
      }
      return false;
    });
  }

  void _addComment(String recipeId) {
    if (_commentController.text.isNotEmpty) {
      final commentText = _commentController.text.trim();
      FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .collection('comments')
          .add({
        'text': commentText,
        'userId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        _commentController.clear();
      }).catchError((e) {
        print("$e");
      });
    }
  }

  void _deleteComment(String recipeId, String commentId) {
    FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId)
        .delete()
        .then((_) {})
        .catchError((e) {
      print("$e");
    });
  }

  Widget _buildCommentsSection(String recipeId) {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipes')
              .doc(recipeId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('Daha Yorum Yapılmamış.');
            }

            final comments = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final text = comment['text'];
                final commentUserId = comment['userId'];
                final commentId = comment.id;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(commentUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return SizedBox.shrink();
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return SizedBox.shrink();
                    }

                    final username =
                        userSnapshot.data!['username'] ?? 'Unknown User';

                    return ListTile(
                      title: Text(text),
                      leading: Icon(Icons.comment),
                      subtitle: Text('Tarafından: $username'),
                      trailing: commentUserId == widget.userId
                          ? IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteComment(recipeId, commentId);
                              },
                            )
                          : null,
                    );
                  },
                );
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: "Yorum Yazın...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _addComment(recipeId);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<String?>(
        future: _fetchRecipeId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Tarif bulunamadı.'));
          }

          final recipeId = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageURL != null && widget.imageURL!.isNotEmpty)
                  Image.network(widget.imageURL!, fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text("Malzemeler:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.ingredients),
                const SizedBox(height: 16),
                Text("Açıklamalar:",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.instructions),
                const SizedBox(height: 16),
                StreamBuilder<bool>(
                  stream: _isFavorite(recipeId),
                  builder: (context, favoriteSnapshot) {
                    if (favoriteSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return IconButton(
                        icon: Icon(Icons.favorite_border),
                        onPressed: null,
                      );
                    }

                    bool isFavorite = favoriteSnapshot.data ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                            size: 36,
                          ),
                          onPressed: () {
                            if (isFavorite) {
                              _recipeService.removeFromFavorites(
                                  widget.userId, recipeId);
                            } else {
                              _recipeService.addToFavorites(
                                  widget.userId, recipeId);
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                          style: TextStyle(
                            fontSize: 18,
                            color: isFavorite ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildCommentsSection(recipeId),
              ],
            ),
          );
        },
      ),
    );
  }
}
