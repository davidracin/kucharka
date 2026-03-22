import 'package:flutter/material.dart';

import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(recipe.name),
        subtitle: Text(
          recipe.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Upravit recept',
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Smazat recept',
            ),
          ],
        ),
      ),
    );
  }
}
