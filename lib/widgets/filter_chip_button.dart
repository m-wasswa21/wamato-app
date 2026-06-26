import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A Jiji-style filter dropdown button.
/// Shows active value in primary color, inactive in border style.
class FilterChipButton extends StatelessWidget {
  final String label;
  final String? activeValue;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.label,
    this.activeValue,
    required this.onTap,
  });

  bool get _active => activeValue != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _active ? AppColors.primaryLight : AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
            color:
                _active ? AppColors.primary : AppColors.border,
            width: _active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeValue ?? label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _active
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _active
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
