import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String ingredients;
  final String steps;
  final DateTime? createdAt;

  factory Recipe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];

    return Recipe(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      ingredients: (data['ingredients'] as String?) ?? '',
      steps: (data['steps'] as String?) ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
    };
  }
}
