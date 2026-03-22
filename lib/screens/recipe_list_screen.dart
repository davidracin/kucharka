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
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Recipe recipe) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return recipe.ingredients.toLowerCase().contains(query) ||
        recipe.name.toLowerCase().contains(query) ||
        recipe.description.toLowerCase().contains(query);
  }

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
          final filteredRecipes = recipes.where(_matchesSearch).toList();

          if (recipes.isEmpty) {
            return const Center(
              child: Text('Zatím tu nejsou žádné recepty. Přidejte první přes +.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Vyhledat podle ingredience',
                    hintText: 'Např. vejce, mouka, mléko',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Vymazat hledání',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: filteredRecipes.isEmpty
                    ? const Center(
                        child: Text('Žádný recept neodpovídá hledání.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: filteredRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = filteredRecipes[index];
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
                      ),
              ),
            ],
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
