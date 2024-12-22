import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partyplanner/core/constants/app_constants.dart';
import 'package:partyplanner/models/item.dart';
import 'package:partyplanner/models/party.dart';
import 'package:partyplanner/views/widgets/custom_button.dart';

class PartyCard extends StatelessWidget {
  final Party party;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final String? currentUserId;
  final bool showActions;
  final bool isDetailed;

  const PartyCard({
    super.key,
    required this.party,
    this.onTap,
    this.onJoin,
    this.onLeave,
    this.currentUserId,
    this.showActions = true,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppConstants.smallSpacing / 2),
                        Text(
                          _formatDate(party.date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: AppConstants.defaultSpacing),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: AppConstants.defaultIconSize,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.location,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (party.locationDetails != null &&
                            party.locationDetails!.isNotEmpty)
                          Text(
                            party.locationDetails!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultSpacing),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: AppConstants.defaultIconSize,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Text(
                    '${party.participantsIds.length}/${party.maxParticipants} participants',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (isDetailed) ...[
                const SizedBox(height: AppConstants.defaultSpacing),
                _buildItemsSummary(theme),
              ],
              if (isDetailed && party.description.isNotEmpty) ...[
                const SizedBox(height: AppConstants.defaultSpacing),
                Text(
                  party.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (showActions) ...[
                const SizedBox(height: AppConstants.defaultSpacing),
                _buildActions(),
              ],
              if (party.isPrivate) ...[
                const SizedBox(height: AppConstants.smallSpacing),
                Row(
                  children: [
                    Icon(
                      Icons.lock,
                      size: AppConstants.defaultIconSize,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: AppConstants.smallSpacing),
                    Text(
                      'Soirée privée',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (party.status) {
      case PartyStatus.planning:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        label = "En préparation";
        break;
      case PartyStatus.confirmed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        label = "Confirmée";
        break;
      case PartyStatus.ongoing:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        label = "En cours";
        break;
      case PartyStatus.completed:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[900]!;
        label = "Terminée";
        break;
      case PartyStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        label = "Annulée";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildItemsSummary(ThemeData theme) {
    final totalItems = party.items.length;
    final assignedItems = party.items
        .where((item) =>
            item.status == ItemStatus.assigned ||
            item.status == ItemStatus.brought)
        .length;
    final broughtItems =
        party.items.where((item) => item.status == ItemStatus.brought).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.checklist,
              size: AppConstants.defaultIconSize,
              color: Colors.grey[600],
            ),
            const SizedBox(width: AppConstants.smallSpacing),
            Text(
              'Items: $assignedItems/$totalItems assignés, $broughtItems apportés',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        if (isDetailed) ...[
          const SizedBox(height: AppConstants.smallSpacing),
          _buildItemsProgress(
            assigned: assignedItems,
            brought: broughtItems,
            total: totalItems,
          ),
        ],
      ],
    );
  }

  Widget _buildItemsProgress({
    required int assigned,
    required int brought,
    required int total,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: total > 0 ? assigned / total : 0,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            brought == total ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final bool isParticipant = party.participantsIds.contains(currentUserId);
    final bool isOrganizer = party.organizerId == currentUserId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isParticipant && !party.isFull && onJoin != null)
          CustomButton(
            text: 'Participer',
            onPressed: onJoin,
            variant: CustomButtonVariant.primary,
            size: CustomButtonSize.small,
            leftIcon: Icons.person_add,
          ),
        if (isParticipant && !isOrganizer && onLeave != null) ...[
          const SizedBox(width: AppConstants.smallSpacing),
          CustomButton(
            text: 'Quitter',
            onPressed: onLeave,
            variant: CustomButtonVariant.outline,
            size: CustomButtonSize.small,
            leftIcon: Icons.exit_to_app,
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateFormatter = DateFormat.yMMMd('fr_FR');
    final timeFormatter = DateFormat.Hm('fr_FR');

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "Aujourd'hui à ${timeFormatter.format(date)}";
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return "Demain à ${timeFormatter.format(date)}";
    } else {
      return '${dateFormatter.format(date)} à ${timeFormatter.format(date)}';
    }
  }
}
