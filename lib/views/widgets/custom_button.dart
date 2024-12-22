import 'package:flutter/material.dart';

enum CustomButtonVariant { primary, secondary, outline, text, danger, success }

enum CustomButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final bool disabled;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leftIcon,
    this.rightIcon,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dimensions = _getDimensions();

    final colors = _getColors(theme);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: dimensions.height,
      child: ElevatedButton(
        onPressed: (disabled || isLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          disabledBackgroundColor: colors.disabledBackground,
          disabledForegroundColor: colors.disabledForeground,
          padding: dimensions.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimensions.borderRadius),
            side: _getBorderSide(colors),
          ),
          elevation: variant == CustomButtonVariant.text ? 0 : 2,
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: _getLoadingSize(),
        width: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == CustomButtonVariant.outline ? Colors.blue : Colors.white,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leftIcon != null) ...[
          Icon(leftIcon, size: _getIconSize()),
          SizedBox(width: size == CustomButtonSize.small ? 4 : 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (rightIcon != null) ...[
          SizedBox(width: size == CustomButtonSize.small ? 4 : 8),
          Icon(rightIcon, size: _getIconSize()),
        ],
      ],
    );
  }

  ({double height, EdgeInsets padding, double borderRadius}) _getDimensions() {
    switch (size) {
      case CustomButtonSize.small:
        return (
          height: 32.0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: 6.0
        );
      case CustomButtonSize.large:
        return (
          height: 48.0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          borderRadius: 10.0,
        );
      case CustomButtonSize.medium:
        return (
          height: 48.0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: 8.0
        );
    }
  }

  ({
    Color background,
    Color foreground,
    Color disabledBackground,
    Color disabledForeground,
    Color? border
  }) _getColors(ThemeData theme) {
    switch (variant) {
      case CustomButtonVariant.secondary:
        return (
          background: theme.colorScheme.secondary,
          foreground: Colors.white,
          disabledBackground: Colors.grey.shade300,
          disabledForeground: Colors.grey.shade500,
          border: null,
        );
      case CustomButtonVariant.outline:
        return (
          background: Colors.transparent,
          foreground: theme.colorScheme.primary,
          disabledBackground: Colors.transparent,
          disabledForeground: Colors.grey.shade400,
          border: theme.colorScheme.primary,
        );
      case CustomButtonVariant.text:
        return (
          background: Colors.transparent,
          foreground: theme.colorScheme.primary,
          disabledBackground: Colors.transparent,
          disabledForeground: Colors.grey.shade400,
          border: null,
        );
      case CustomButtonVariant.danger:
        return (
          background: Colors.red.shade600,
          foreground: Colors.white,
          disabledBackground: Colors.red.shade200,
          disabledForeground: Colors.white70,
          border: null,
        );
      case CustomButtonVariant.success:
        return (
          background: Colors.green.shade600,
          foreground: Colors.white,
          disabledBackground: Colors.green.shade200,
          disabledForeground: Colors.white70,
          border: null,
        );
      case CustomButtonVariant.primary:
        return (
          background: theme.colorScheme.primary,
          foreground: Colors.white,
          disabledBackground: Colors.grey.shade300,
          disabledForeground: Colors.grey.shade500,
          border: null,
        );
    }
  }

  BorderSide _getBorderSide(
      ({
        Color background,
        Color foreground,
        Color disabledBackground,
        Color disabledForeground,
        Color? border
      }) colors) {
    if (variant == CustomButtonVariant.outline) {
      return BorderSide(
        color: disabled
            ? Colors.grey.shade300
            : colors.border ?? Colors.transparent,
        width: 1.5,
      );
    }
    return BorderSide.none;
  }

  double _getFontSize() {
    switch (size) {
      case CustomButtonSize.small:
        return 14;
      case CustomButtonSize.large:
        return 16;
      case CustomButtonSize.medium:
        return 15;
    }
  }

  double _getIconSize() {
    switch (size) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.large:
        return 24;
      case CustomButtonSize.medium:
        return 20;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.large:
        return 24;
      case CustomButtonSize.medium:
        return 20;
    }
  }
}
