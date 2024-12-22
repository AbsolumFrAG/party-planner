import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/item.dart';
import '../../../viewmodels/items_viewmodel.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/custom_button.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  ItemCategory _selectedCategory = ItemCategory.food;
  String? _selectedUnit;
  bool _isRequired = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<ItemsViewModel>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await viewModel.addItem(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      quantity: int.parse(_quantityController.text),
      unit: _selectedUnit,
      isRequired: _isRequired,
    );

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Item ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } else if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ItemsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom de l'item
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nom de l'item",
                  hintText: "Ex: Chips, Boissons, etc.",
                  prefixIcon: Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Le nom de l'item est requis";
                  }
                  return null;
                },
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Détails supplémentaires',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
                enabled: !viewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<ItemCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: ItemCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryLabel(category)),
                  );
                }).toList(),
                onChanged: viewModel.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),

              // Quantité et unité
              Row(
                children: [
                  // Quantité
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Invalide';
                        }
                        return null;
                      },
                      enabled: !viewModel.isLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Unité
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unité',
                        prefixIcon: Icon(Icons.straighten),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Aucune'),
                        ),
                        ...AppConstants.itemUnits.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text('${entry.key} (${entry.value})'),
                          );
                        }),
                      ],
                      onChanged: viewModel.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedUnit = value;
                              });
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Option "Requis"
              SwitchListTile(
                title: const Text('Item requis'),
                subtitle: const Text(
                  'Cochez si cet item est nécessaire pour la soirée',
                ),
                value: _isRequired,
                onChanged: viewModel.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isRequired = value;
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Bouton d'ajout
              CustomButton(
                text: 'Ajouter',
                onPressed: viewModel.isLoading ? null : _addItem,
                isLoading: viewModel.isLoading,
                variant: CustomButtonVariant.primary,
                leftIcon: Icons.add,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(ItemCategory category) {
    switch (category) {
      case ItemCategory.food:
        return 'Nourriture';
      case ItemCategory.drink:
        return 'Boisson';
      case ItemCategory.alcoholicDrink:
        return 'Alcool';
      case ItemCategory.dessert:
        return 'Dessert';
      case ItemCategory.snack:
        return 'Snack';
      case ItemCategory.utensil:
        return 'Ustensile';
      case ItemCategory.decoration:
        return 'Décoration';
      case ItemCategory.other:
        return 'Autre';
    }
  }
}
