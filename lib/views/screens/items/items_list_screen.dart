import 'package:flutter/material.dart';
import 'package:partyplanner/config/routes.dart';
import 'package:provider/provider.dart';
import '../../../models/item.dart';
import '../../../viewmodels/items_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../widgets/item_card.dart';
import '../../widgets/custom_button.dart';

class ItemsListScreen extends StatelessWidget {
  const ItemsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items de la soirée'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildBody() {
    return Consumer2<ItemsViewModel, AuthViewModel>(
      builder: (context, itemsViewModel, authViewModel, child) {
        if (itemsViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (itemsViewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  itemsViewModel.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Réessayer',
                  onPressed: () {
                    // Recharger les items
                  },
                  variant: CustomButtonVariant.outline,
                ),
              ],
            ),
          );
        }

        final items = itemsViewModel.items;
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Recharger les items
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Pour le FAB
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ItemCard(
                item: item,
                currentUserId: authViewModel.user?.id,
                onTap: () => _showItemDetails(context, item),
                onAssign: () => _assignItem(context, item),
                onUnassign: () => _unassignItem(context, item),
                onMarkAsBrought: () => _markItemAsBrought(context, item),
                showActions: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun item pour le moment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par ajouter des items à la soirée',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Ajouter un item',
            onPressed: () => Navigator.pushNamed(context, Routes.addItem),
            variant: CustomButtonVariant.primary,
            leftIcon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/add-item'),
      icon: const Icon(Icons.add),
      label: const Text('Ajouter un item'),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _FilterBottomSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  void _showItemDetails(BuildContext context, Item item) {
    // Navigation vers les détails de l'item
  }

  void _assignItem(BuildContext context, Item item) async {
    final itemsViewModel = context.read<ItemsViewModel>();
    final success = await itemsViewModel.assignItemToSelf(item.id);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(itemsViewModel.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _unassignItem(BuildContext context, Item item) async {
    final itemsViewModel = context.read<ItemsViewModel>();
    final success = await itemsViewModel.unassignItem(item.id);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(itemsViewModel.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markItemAsBrought(BuildContext context, Item item) async {
    final itemsViewModel = context.read<ItemsViewModel>();
    final success = await itemsViewModel.markItemAsBrought(item.id);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(itemsViewModel.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context) {
    final itemsViewModel = context.watch<ItemsViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer les items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Barre de recherche
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un item...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: itemsViewModel.setSearchQuery,
          ),
          const SizedBox(height: 16),

          // Filtres de catégorie
          Text(
            'Catégories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ItemCategory.values.map((category) {
              final isSelected = itemsViewModel.selectedCategory == category;
              return FilterChip(
                label: Text(_getCategoryLabel(category)),
                selected: isSelected,
                onSelected: (selected) {
                  itemsViewModel.setCategory(selected ? category : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Switches pour les filtres additionnels
          SwitchListTile(
            title: const Text('Items non assignés uniquement'),
            value: itemsViewModel.showOnlyUnassigned,
            onChanged: (value) => itemsViewModel.toggleShowOnlyUnassigned(),
          ),
          SwitchListTile(
            title: const Text('Mes items uniquement'),
            value: itemsViewModel.showOnlyMyItems,
            onChanged: (value) => itemsViewModel.toggleShowOnlyMyItems(),
          ),
        ],
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
