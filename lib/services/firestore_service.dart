import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

class FirestoreService {
  FirestoreService();

  final CollectionReference<Map<String, dynamic>> _recipesRef =
      FirebaseFirestore.instance.collection('recipes');

  Stream<List<Recipe>> getRecipes() {
    return _recipesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(Recipe.fromFirestore).toList();
    });
  }

  Future<void> addRecipe({
    required String name,
    required String description,
    required String ingredients,
    required String steps,
  }) async {
    await _recipesRef.add({
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRecipe(String id) async {
    await _recipesRef.doc(id).delete();
  }

  Future<void> updateRecipe({
    required String id,
    required String name,
    required String description,
    required String ingredients,
    required String steps,
  }) async {
    await _recipesRef.doc(id).update({
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
    });
  }
}
