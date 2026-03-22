import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _customStepLabelController = TextEditingController();
  final TextEditingController _stepTextController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  bool _isSaving = false;
  String _selectedStepLabel = '1';
  final List<Map<String, String>> _steps = <Map<String, String>>[];

  static const String _customLabelOption = 'Vlastní';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _customStepLabelController.dispose();
    _stepTextController.dispose();
    super.dispose();
  }

  void _addStep() {
    final stepText = _stepTextController.text.trim();
    if (stepText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplňte text kroku.')),
      );
      return;
    }

    String label = _selectedStepLabel;
    if (_selectedStepLabel == _customLabelOption) {
      label = _customStepLabelController.text.trim();
      if (label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vyplňte vlastní označení kroku.')),
        );
        return;
      }
    }

    setState(() {
      _steps.add(
        <String, String>{
          'label': label,
          'text': stepText,
        },
      );

      _stepTextController.clear();
      _customStepLabelController.clear();

      // Keep next step adding fast by moving to next number where possible.
      if (_selectedStepLabel != _customLabelOption) {
        final current = int.tryParse(_selectedStepLabel) ?? 1;
        final next = (current + 1).clamp(1, 15);
        _selectedStepLabel = next.toString();
      }
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  String _buildStepsText() {
    return _steps.map((step) => '${step['label']}. ${step['text']}').join('\n');
  }

  Future<void> _saveRecipe() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Přidejte alespoň jeden krok.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestoreService.addRecipe(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        steps: _buildStepsText(),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recept byl přidán')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is FirebaseException && error.code == 'permission-denied'
          ? 'Nemáte oprávnění zapisovat do Firestore. Zkontrolujte Firestore Rules.'
          : 'Uložení selhalo: $error';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Toto pole je povinné';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přidat recept'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Název receptu',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Popis',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredience',
                border: OutlineInputBorder(),
                hintText: 'Např.: mouka, vejce, mléko',
              ),
              maxLines: 4,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 20),
            Text(
              'Kroky receptu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedStepLabel,
              decoration: const InputDecoration(
                labelText: 'Číslo kroku',
                border: OutlineInputBorder(),
              ),
              items: [
                ...List<DropdownMenuItem<String>>.generate(
                  15,
                  (index) => DropdownMenuItem<String>(
                    value: '${index + 1}',
                    child: Text('${index + 1}'),
                  ),
                ),
                const DropdownMenuItem<String>(
                  value: _customLabelOption,
                  child: Text(_customLabelOption),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedStepLabel = value;
                });
              },
            ),
            if (_selectedStepLabel == _customLabelOption) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customStepLabelController,
                decoration: const InputDecoration(
                  labelText: 'Vlastní označení kroku',
                  border: OutlineInputBorder(),
                  hintText: 'Např.: A nebo Příprava',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _stepTextController,
              decoration: const InputDecoration(
                labelText: 'Text kroku',
                border: OutlineInputBorder(),
                hintText: 'Co se má v tomto kroku udělat?',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add),
              label: const Text('Přidat krok'),
            ),
            const SizedBox(height: 12),
            if (_steps.isEmpty)
              const Text('Zatím nejsou přidané žádné kroky.')
            else
              Column(
                children: List<Widget>.generate(_steps.length, (index) {
                  final step = _steps[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${step['label']}. ${step['text']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Smazat krok',
                        onPressed: () => _removeStep(index),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveRecipe,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Ukládání...' : 'Uložit recept'),
            ),
          ],
        ),
      ),
    );
  }
}
