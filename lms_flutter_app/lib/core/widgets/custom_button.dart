import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final ButtonType type;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.borderRadius = 8,
    this.padding,
    this.icon,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color getBackgroundColor() {
      if (!isEnabled) return Colors.grey.shade300;
      if (backgroundColor != null) return backgroundColor!;

      switch (type) {
        case ButtonType.primary:
          return AppConstants.primaryColor;
        case ButtonType.secondary:
          return theme.colorScheme.secondary;
        case ButtonType.outline:
          return Colors.transparent;
        case ButtonType.text:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (!isEnabled) return Colors.grey.shade600;
      if (textColor != null) return textColor!;

      switch (type) {
        case ButtonType.primary:
        case ButtonType.secondary:
          return Colors.white;
        case ButtonType.outline:
        case ButtonType.text:
          return AppConstants.primaryColor;
      }
    }

    Border? getBorder() {
      if (type == ButtonType.outline) {
        return Border.all(
          color: isEnabled ? AppConstants.primaryColor : Colors.grey.shade300,
          width: 1,
        );
      }
      return null;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: getTextColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: getBorder()?.top ?? BorderSide.none,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          elevation: type == ButtonType.text || type == ButtonType.outline ? 0 : 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: getTextColor(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}