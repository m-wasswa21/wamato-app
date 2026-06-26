import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CategoryTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final int count;
  final VoidCallback onTap;
  final Color? accentColor;

  const CategoryTile({
    super.key,
    required this.label,
    required this.imagePath,
    required this.count,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: accentColor?.withOpacity(0.15) ??
                    AppColors.accent,
              ),
            ),
            // gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count ${count == 1 ? 'property' : 'properties'}',
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
}

// ── Status / subcategory row card ─────────────────────────────────────────────
class SubcategoryCard extends StatelessWidget {
  final String label;
  final String imagePath;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const SubcategoryCard({
    super.key,
    required this.label,
    required this.imagePath,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: const [
            BoxShadow(
                color: AppColors.darkShadowMd,
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: Image.asset(
                imagePath,
                width: 90,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 80,
                  color: color.withOpacity(0.15),
                  child: Icon(Icons.home_rounded,
                      color: color, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'property' : 'properties'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
