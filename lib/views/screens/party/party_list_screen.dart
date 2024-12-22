import 'package:flutter/material.dart';
import 'package:partyplanner/config/routes.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/party_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../widgets/party_card.dart';
import '../../widgets/custom_button.dart';

class PartyListScreen extends StatelessWidget {
  const PartyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes soirées'),
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
    return Consumer2<PartyViewModel, AuthViewModel>(
      builder: (context, partyViewModel, authViewModel, child) {
        if (partyViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (partyViewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  partyViewModel.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Réessayer',
                  onPressed: () {
                    // Recharger les soirées
                  },
                  variant: CustomButtonVariant.outline,
                ),
              ],
            ),
          );
        }

        final parties = partyViewModel.parties;
        if (parties.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => partyViewModel.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Pour le FAB
            itemCount: parties.length,
            itemBuilder: (context, index) {
              final party = parties[index];
              return PartyCard(
                party: party,
                currentUserId: authViewModel.user?.id,
                onTap: () {
                  partyViewModel.selectParty(party);
                  Routes.navigateToPartyDetails(context, party.id);
                },
                onJoin: () => _handleJoinParty(context, party.id),
                onLeave: () => _handleLeaveParty(context, party.id),
                isDetailed: false,
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
            Icons.celebration_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune soirée pour le moment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par créer une soirée ou rejoignez-en une',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Créer une soirée',
            onPressed: () => Navigator.pushNamed(context, Routes.createParty),
            variant: CustomButtonVariant.primary,
            leftIcon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, Routes.createParty),
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle soirée'),
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

  Future<void> _handleJoinParty(BuildContext context, String partyId) async {
    final partyViewModel = context.read<PartyViewModel>();
    final success = await partyViewModel.joinParty(partyId);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(partyViewModel.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLeaveParty(BuildContext context, String partyId) async {
    final partyViewModel = context.read<PartyViewModel>();
    final success = await partyViewModel.leaveParty(partyId);

    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(partyViewModel.error ?? 'Une erreur est survenue'),
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
    final partyViewModel = context.watch<PartyViewModel>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtres',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  partyViewModel.setSelectedDate(null);
                  partyViewModel.setSearchQuery('');
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barre de recherche
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher une soirée...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: partyViewModel.setSearchQuery,
          ),
          const SizedBox(height: 16),

          // Filtres par date
          Text(
            'Période',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Toutes'),
                selected: partyViewModel.selectedDate == null,
                onSelected: (_) => partyViewModel.setSelectedDate(null),
              ),
              FilterChip(
                label: const Text('Ce mois-ci'),
                selected: _isCurrentMonth(partyViewModel.selectedDate),
                onSelected: (selected) {
                  if (selected) {
                    partyViewModel.setSelectedDate(DateTime.now());
                  }
                },
              ),
              FilterChip(
                label: const Text('Mois prochain'),
                selected: _isNextMonth(partyViewModel.selectedDate),
                onSelected: (selected) {
                  if (selected) {
                    final nextMonth =
                        DateTime.now().add(const Duration(days: 31));
                    partyViewModel.setSelectedDate(nextMonth);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtres additionnels
          SwitchListTile(
            title: const Text('Mes soirées organisées'),
            value: partyViewModel.showOnlyOrganized,
            onChanged: (_) => partyViewModel.toggleShowOnlyOrganized(),
          ),
          SwitchListTile(
            title: const Text('Inclure les soirées passées'),
            value: partyViewModel.showPastParties,
            onChanged: (_) => partyViewModel.toggleShowPastParties(),
          ),
        ],
      ),
    );
  }

  bool _isCurrentMonth(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  bool _isNextMonth(DateTime? date) {
    if (date == null) return false;
    final nextMonth = DateTime.now().add(const Duration(days: 31));
    return date.year == nextMonth.year && date.month == nextMonth.month;
  }
}
