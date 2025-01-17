import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:deneme/recipe_service.dart';

class AddRecipePage extends StatefulWidget {
  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isSubmitting = false;
  final RecipeService _recipeService = RecipeService();

  Future<void> _submitRecipe() async {
    if (_titleController.text.isEmpty ||
        _ingredientsController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen eksik yerleri doldurun.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Kullanıcı oturumu kapalı.");
      }

      await _recipeService.addRecipe(
        title: _titleController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        instructions: _instructionsController.text.trim(),
        userId: user.uid,
        imageURL: _imageUrlController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tarif başarıyla eklendi!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tarif ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Tarif adı"),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _ingredientsController,
                decoration: InputDecoration(labelText: "Malzemeler"),
                maxLines: 4,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _instructionsController,
                decoration: InputDecoration(labelText: "Açıklama"),
                maxLines: 4,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _imageUrlController,
                decoration:
                    InputDecoration(labelText: "Resim URL'si (Opsiyonel)"),
              ),
              SizedBox(height: 24),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRecipe,
                      child: Text("Gönder"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
