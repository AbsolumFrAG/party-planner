import 'package:flutter/material.dart';
import 'package:partyplanner/core/constants/app_constants.dart';
import 'package:partyplanner/models/item.dart';
import 'package:partyplanner/views/widgets/custom_button.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onUnassign;
  final VoidCallback? onMarkAsBrought;
  final bool isAssignable;
  final bool isEditable;
  final bool showActions;
  final String? currentUserId;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAssign,
    this.onUnassign,
    this.onMarkAsBrought,
    this.isAssignable = true,
    this.isEditable = false,
    this.showActions = true,
    this.currentUserId,
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
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildCategoryBadge(),
                ],
              ),
              const SizedBox(height: AppConstants.smallSpacing),
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    size: AppConstants.defaultIconSize,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: AppConstants.smallSpacing),
                  Text(
                    '${item.quantity} ${item.unit ?? ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (item.isRequired)
                    Container(
                      margin: const EdgeInsets.only(
                          left: AppConstants.smallSpacing),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Requis',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                ],
              ),
              if (item.assignedToUserId != null) ...[
                const SizedBox(height: AppConstants.smallSpacing),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: AppConstants.defaultIconSize,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: AppConstants.smallSpacing),
                    Text(
                      'Assigné à: ${item.assignedToUserId}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (showActions) ...[
                const SizedBox(height: AppConstants.defaultSpacing),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (item.status) {
      case ItemStatus.needed:
        icon = Icons.error_outline;
        color = Colors.orange;
        break;
      case ItemStatus.assigned:
        icon = Icons.assignment_ind;
        color = Colors.blue;
        break;
      case ItemStatus.brought:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ItemStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: AppConstants.largeIconSize,
    );
  }

  Widget _buildCategoryBadge() {
    Color backgroundColor;
    Color textColor;

    switch (item.category) {
      case ItemCategory.food:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      case ItemCategory.drink:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case ItemCategory.alcoholicDrink:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[900]!;
        break;
      case ItemCategory.dessert:
        backgroundColor = Colors.pink[100]!;
        textColor = Colors.pink[900]!;
        break;
      case ItemCategory.snack:
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[900]!;
        break;
      case ItemCategory.utensil:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[900]!;
        break;
      case ItemCategory.decoration:
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[900]!;
        break;
      case ItemCategory.other:
        backgroundColor = Colors.blueGrey[100]!;
        textColor = Colors.blueGrey[900]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getCategoryLabel(item.category),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActions() {
    final isAssignedToCurrentUser = item.assignedToUserId == currentUserId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (item.status == ItemStatus.needed && isAssignable)
          CustomButton(
            text: 'Je ramène',
            onPressed: onAssign,
            variant: CustomButtonVariant.primary,
            size: CustomButtonSize.small,
            leftIcon: Icons.add,
          ),
        if (item.status == ItemStatus.assigned && isAssignedToCurrentUser)
          CustomButton(
            text: 'Annuler',
            onPressed: onUnassign,
            variant: CustomButtonVariant.outline,
            size: CustomButtonSize.small,
            leftIcon: Icons.remove,
          ),
        if (item.status == ItemStatus.assigned &&
            isAssignedToCurrentUser &&
            onMarkAsBrought != null) ...[
          const SizedBox(width: AppConstants.smallSpacing),
          CustomButton(
            text: 'Apporté',
            onPressed: onMarkAsBrought,
            variant: CustomButtonVariant.success,
            size: CustomButtonSize.small,
            leftIcon: Icons.check,
          ),
        ],
      ],
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
