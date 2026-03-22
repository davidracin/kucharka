import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../widgets/recipe_card.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _openAddRecipe() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddRecipeScreen(),
      ),
    );
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Smazat recept?'),
          content: Text('Opravdu chcete smazat "${recipe.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Smazat'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestoreService.deleteRecipe(recipe.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recept byl smazán')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is FirebaseException && error.code == 'permission-denied'
          ? 'Nemáte oprávnění mazat ve Firestore. Zkontrolujte Firestore Rules.'
          : 'Mazání selhalo: $error';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuchařka'),
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: _firestoreService.getRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            final hasPermissionError =
                error is FirebaseException && error.code == 'permission-denied';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  hasPermissionError
                      ? 'Chyba oprávnění ve Firestore. Otevřete Firestore Rules a povolte čtení/zápis pro kolekci recipes.'
                      : 'Nastala chyba: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data ?? <Recipe>[];

          if (recipes.isEmpty) {
            return const Center(
              child: Text('Zatím tu nejsou žádné recepty. Přidejte první přes +.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                    ),
                  );
                },
                onDelete: () => _deleteRecipe(recipe),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddRecipe,
        child: const Icon(Icons.add),
      ),
    );
  }
}
