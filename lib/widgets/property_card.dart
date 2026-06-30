import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/saved/saved_cubit.dart';
import '../core/utils/auth_guard.dart';
import '../models/property.dart';
import '../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Airbnb-style property cards
// ─────────────────────────────────────────────────────────────────────────────

Widget _img(String url, {required double height, double? width, int? cacheW}) {
  if (url.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: cacheW,
      placeholder: (_, __) => _imgPlaceholder(height),
      errorWidget: (_, __, ___) => _imgPlaceholder(height),
    );
  }
  return Image.asset(url,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      cacheWidth: cacheW,
      errorBuilder: (_, __, ___) => _imgPlaceholder(height));
}

Widget _imgPlaceholder(double h) => Container(
    height: h,
    color: const Color(0xFFE8E8E8),
    child: const Center(
        child: Icon(Icons.home_rounded, color: Color(0xFFBBBBBB), size: 40)));

// ── Full-width Airbnb-style card (used in home feed & lists) ─────────────────
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = property.photos.isNotEmpty ? property.photos.first : null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ──────────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photo != null
                    ? _img(photo, height: 240, cacheW: 800)
                    : _imgPlaceholder(240),
              ),
              // Package badge
              if (property.listingPackage != ListingPackage.basic)
                Positioned(
                  top: 14,
                  left: 14,
                  child: _badge(
                    property.listingPackage == ListingPackage.featured
                        ? '⭐ Featured'
                        : '✦ Premium',
                    property.listingPackage == ListingPackage.featured
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
              // Short-stay badge
              if (property.isShortStay)
                Positioned(
                  top: 14,
                  left: property.listingPackage != ListingPackage.basic ? null : 14,
                  right: property.listingPackage != ListingPackage.basic ? null : null,
                  child: _badge(
                    property.type == 'Airbnb' ? 'Short Stay' : 'Holiday',
                    const Color(0xFFFF5A5F),
                  ),
                ),
              // Save heart — Airbnb style (no background, just white icon)
              Positioned(
                top: 12,
                right: 12,
                child: _SaveButton(propertyId: property.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Info ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                            height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (property.isShortStay && (property.rating ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFF222222), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        property.rating!.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${property.area}, ${property.district}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF717171),
                      fontWeight: FontWeight.w400),
                ),
                if (_specs(property).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _specs(property),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF717171)),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      property.priceLabel,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222)),
                    ),
                    if (property.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 3),
                      const Text('Verified',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2-column compact grid card ────────────────────────────────────────────────
class PropertyCardGrid extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCardGrid({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = property.photos.isNotEmpty ? property.photos.first : null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photo != null
                    ? _img(photo, height: 140, cacheW: 420)
                    : _imgPlaceholder(140),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _SaveButton(propertyId: property.id, size: 30, iconSize: 15),
              ),
              if (property.isShortStay)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _badge('Short Stay', const Color(0xFFFF5A5F), small: true),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            property.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222)),
          ),
          const SizedBox(height: 2),
          Text(
            '${property.area}, ${property.district}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF717171)),
          ),
          if (property.isShortStay && (property.rating ?? 0) > 0) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFF222222), size: 12),
                const SizedBox(width: 2),
                Text(property.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222))),
                const SizedBox(width: 4),
                Text('(${property.reviewCount ?? 0})',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF717171))),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            property.priceLabel,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222)),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal scroll card (for featured row) ─────────────────────────────────
class PropertyCardHorizontal extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCardHorizontal(
      {super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = property.photos.isNotEmpty ? property.photos.first : null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: photo != null
                      ? _img(photo, height: 160, width: 220, cacheW: 440)
                      : _imgPlaceholder(160),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _SaveButton(
                      propertyId: property.id, size: 30, iconSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              property.title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(property.area,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF717171))),
            const SizedBox(height: 4),
            Text(property.priceLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222))),
          ],
        ),
      ),
    );
  }
}

// ── Airbnb-style heart save button — reads from SavedCubit ──────────────────
class _SaveButton extends StatelessWidget {
  final String propertyId;
  final double size;
  final double iconSize;

  const _SaveButton({
    required this.propertyId,
    this.size = 36,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedCubit, Set<String>>(
      builder: (context, savedIds) {
        final saved = savedIds.contains(propertyId);
        return GestureDetector(
          onTap: () async {
            final authed = await ensureAuth(context);
            if (authed && context.mounted) {
              context.read<SavedCubit>().toggle(propertyId);
            }
          },
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Colors.black.withValues(alpha: 0.3),
                    size: iconSize + 2,
                  ),
                  Icon(
                    saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: saved ? const Color(0xFFFF5A5F) : Colors.white,
                    size: iconSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _badge(String label, Color color, {bool small = false}) {
  return Container(
    padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600),
    ),
  );
}

String _specs(Property p) {
  final parts = <String>[];
  if (p.bedrooms != null) parts.add('${p.bedrooms} bed');
  if (p.bathrooms != null) parts.add('${p.bathrooms} bath');
  if (p.floorSize != null) parts.add('${p.floorSize!.toInt()} m²');
  if (p.plotSize != null) parts.add('${p.plotSize!.toInt()} ft² plot');
  return parts.join(' · ');
}
