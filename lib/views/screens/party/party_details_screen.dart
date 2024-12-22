import 'package:flutter/material.dart';
import 'package:partyplanner/config/routes.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/party.dart';
import '../../../viewmodels/party_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';

class PartyDetailsScreen extends StatefulWidget {
  const PartyDetailsScreen({super.key});

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  Future<void> _showAccessCodeDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code d\'accès requis'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Code d\'accès',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _joinParty(result);
    }
  }

  Future<void> _joinParty(String? accessCode) async {
    final viewModel = context.read<PartyViewModel>();
    final party = viewModel.selectedParty;
    if (party == null) return;

    final success = await viewModel.joinParty(party.id, accessCode: accessCode);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez rejoint la soirée !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error ?? AppConstants.defaultErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveParty() async {
    final viewModel = context.read<PartyViewModel>();
    final party = viewModel.selectedParty;
    if (party == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la soirée'),
        content: const Text('Êtes-vous sûr de vouloir quitter cette soirée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final success = await viewModel.leaveParty(party.id);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error ?? AppConstants.defaultErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context, Party party) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    party.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (party.isPrivate) const Icon(Icons.lock, color: Colors.grey),
              ],
            ),
            if (party.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                party.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDateChip(context, party.date),
                const SizedBox(width: 8),
                _buildTimeChip(context, party.date),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('d MMMM yyyy', 'fr_FR').format(date),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('HH:mm').format(date),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerInfo(BuildContext context, Party party) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                party.organizerName?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Organisé par',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    party.organizerName ?? 'Utilisateur inconnu',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context, Party party) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lieu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              party.location,
              style: const TextStyle(fontSize: 16),
            ),
            if (party.locationDetails?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                party.locationDetails!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList(BuildContext context, Party party) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${party.participantsIds.length}/${party.maxParticipants}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: party.participantsIds.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final participantId = party.participantsIds[index];
              final participantName = party.participantsNames?[participantId] ??
                  'Utilisateur inconnu';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    participantName[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(participantName),
                subtitle: participantId == party.organizerId
                    ? Text(
                        'Organisateur',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PartyViewModel>(
      builder: (context, viewModel, child) {
        final party = viewModel.selectedParty;
        if (party == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentUserId = context.read<AuthViewModel>().user?.id;
        final isParticipant = party.participantsIds.contains(currentUserId);
        final isOrganizer = party.organizerId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: Text(party.title),
            actions: [
              if (isOrganizer)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.editParty,
                    arguments: party.id,
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, party),
                const SizedBox(height: 16),
                _buildOrganizerInfo(context, party),
                const SizedBox(height: 16),
                _buildLocationInfo(context, party),
                const SizedBox(height: 16),
                _buildParticipantsList(context, party),
                if (!isParticipant) ...[
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Rejoindre la soirée',
                    onPressed: () => party.isPrivate
                        ? _showAccessCodeDialog()
                        : _joinParty(null),
                    variant: CustomButtonVariant.primary,
                    leftIcon: Icons.group_add,
                    isFullWidth: true,
                  ),
                ],
                if (isParticipant && !isOrganizer) ...[
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Quitter la soirée',
                    onPressed: _leaveParty,
                    variant: CustomButtonVariant.danger,
                    leftIcon: Icons.exit_to_app,
                    isFullWidth: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
