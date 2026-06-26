import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/property_repository.dart';
import '../core/utils/auth_guard.dart';
import '../models/property.dart';
import '../core/theme/app_theme.dart';

// Pre-computed — never recreated on rebuild
const _kCardShadow = [
  BoxShadow(color: AppColors.darkShadow, blurRadius: 12, offset: Offset(0, 4)),
];
const _kGridShadow = [
  BoxShadow(color: AppColors.darkShadowMd, blurRadius: 10, offset: Offset(0, 3)),
];
const _kSaveShadow = [
  BoxShadow(color: Color(0x26020617), blurRadius: 6, offset: Offset(0, 2)),
];
const _kSaveShadowSm = [
  BoxShadow(color: AppColors.darkShadowMd, blurRadius: 4),
];
const _kVerifiedDecoration = BoxDecoration(
  color: AppColors.successFaint,
  borderRadius: BorderRadius.all(Radius.circular(20)),
);
const _kSaveDecoration = BoxDecoration(
  color: AppColors.white,
  shape: BoxShape.circle,
  boxShadow: _kSaveShadow,
);
const _kSaveDecorationSm = BoxDecoration(
  color: AppColors.white,
  shape: BoxShape.circle,
  boxShadow: _kSaveShadowSm,
);
const _kGradientDecoration = BoxDecoration(
  gradient: LinearGradient(
      colors: [AppColors.gradientStart, AppColors.gradientEnd]),
  borderRadius: BorderRadius.all(Radius.circular(20)),
);
const _kStatusBgDecoration = BoxDecoration(
  color: Color(0xA6020617),
  borderRadius: BorderRadius.all(Radius.circular(20)),
);
const _kDetailsBtnDecoration = BoxDecoration(
  color: AppColors.primaryFaint,
  borderRadius: BorderRadius.all(Radius.circular(20)),
);
const _kDivider = ColoredBox(color: Color(0x80E2E8F0));

Widget _propertyImage(String url,
    {required double height, double? width, int? cacheWidth}) {
  if (url.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: cacheWidth,
      placeholder: (_, __) =>
          ColoredBox(color: AppColors.accent, child: SizedBox(height: height, width: width ?? double.infinity)),
      errorWidget: (_, __, ___) =>
          ColoredBox(color: AppColors.accent, child: SizedBox(height: height, width: width ?? double.infinity)),
    );
  }
  return Image.asset(
    url,
    height: height,
    width: width ?? double.infinity,
    fit: BoxFit.cover,
    cacheWidth: cacheWidth,
    errorBuilder: (_, __, ___) =>
        SizedBox(height: height, child: const ColoredBox(color: AppColors.accent)),
  );
}

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: _kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImage(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: _buildInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final photo = property.photos.isNotEmpty ? property.photos.first : null;
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          child: photo != null
              ? _propertyImage(photo, height: 168, cacheWidth: 536)
              : const SizedBox(
                  height: 168,
                  child: ColoredBox(color: AppColors.accent),
                ),
        ),
        if (property.listingPackage != ListingPackage.basic)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: _kGradientDecoration,
              child: Text(
                property.listingPackage == ListingPackage.featured
                    ? '⭐ Featured'
                    : '✦ Premium',
                style: T.badgeWhite,
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: _kStatusBgDecoration,
            child: Text(property.statusLabel, style: T.badgeWhite),
          ),
        ),
        if (property.isShortStay)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: property.type == 'Airbnb'
                    ? AppColors.error
                    : AppColors.secondary,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    property.type == 'Airbnb'
                        ? FontAwesomeIcons.airbnb
                        : FontAwesomeIcons.umbrellaBeach,
                    size: 11,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    property.type == 'Airbnb' ? 'Airbnb' : 'Holiday',
                    style: T.badgeWhite,
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 10,
          right: 10,
          child: _SaveButton(propertyId: property.id, decoration: _kSaveDecoration, size: 34, iconSize: 18),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final hasSpecs = property.bedrooms != null ||
        property.bathrooms != null ||
        property.floorSize != null ||
        property.plotSize != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                property.title,
                style: T.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (property.isVerified)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: _kVerifiedDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.success, size: 11),
                    const SizedBox(width: 2),
                    Text('Verified', style: T.verified),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.secondary, size: 13),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '${property.area}, ${property.district}',
                style: T.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (hasSpecs) ...[
          const SizedBox(height: 8),
          const SizedBox(height: 1, child: _kDivider),
          const SizedBox(height: 8),
          _buildSpecsGrid(),
          const SizedBox(height: 6),
          const SizedBox(height: 1, child: _kDivider),
        ],
        if (property.isShortStay && property.rating != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.solidStar,
                  size: 11, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(property.rating!.toStringAsFixed(1),
                  style: T.ratingNumSm),
              const SizedBox(width: 4),
              Text('(${property.reviewCount ?? 0} reviews)',
                  style: T.locationSm),
              const Spacer(),
              const FaIcon(FontAwesomeIcons.userGroup,
                  size: 11, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Up to ${property.maxGuests} guests',
                  style: T.locationSm),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                property.priceLabel,
                style: T.priceLg,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: _kDetailsBtnDecoration,
              child: Text('Details', style: T.detailsBtn),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecsGrid() {
    final items = <(IconData, String)>[];
    if (property.bedrooms != null)
      items.add((Icons.bed_rounded, '${property.bedrooms} Beds'));
    if (property.bathrooms != null)
      items.add((Icons.bathtub_rounded, '${property.bathrooms} Baths'));
    if (property.floorSize != null)
      items.add(
          (Icons.square_foot_rounded, '${property.floorSize!.toInt()} m²'));
    if (property.plotSize != null)
      items
          .add((Icons.landscape_rounded, '${property.plotSize!.toInt()} ft²'));

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 5));
      rows.add(Row(children: [
        Expanded(child: _spec(items[i].$1, items[i].$2)),
        if (i + 1 < items.length)
          Expanded(child: _spec(items[i + 1].$1, items[i + 1].$2)),
      ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _spec(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 13),
        const SizedBox(width: 3),
        Text(label, style: T.specText),
      ],
    );
  }
}

// ── Compact 2-column grid card ────────────────────────────────────────────────
class PropertyCardGrid extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCardGrid({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          boxShadow: _kGridShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: property.photos.isNotEmpty
                      ? _propertyImage(property.photos.first, height: 120, cacheWidth: 420)
                      : const SizedBox(height: 120, child: ColoredBox(color: AppColors.accent)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          217,
                          _statusColor.red,
                          _statusColor.green,
                          _statusColor.blue),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(property.statusLabel,
                        style: T.badgeWhiteXs),
                  ),
                ),
                if (property.isShortStay)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: property.type == 'Airbnb'
                            ? AppColors.error
                            : AppColors.secondary,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: FaIcon(
                        property.type == 'Airbnb'
                            ? FontAwesomeIcons.airbnb
                            : FontAwesomeIcons.umbrellaBeach,
                        size: 10,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _SaveButton(propertyId: property.id, decoration: _kSaveDecorationSm, size: 28, iconSize: 14),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.cardTitleSm,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.secondary, size: 11),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property.area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.locationSm,
                        ),
                      ),
                      if (property.isVerified)
                        const Icon(Icons.verified_rounded,
                            color: AppColors.success, size: 12),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (property.isShortStay && property.rating != null)
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.solidStar,
                            size: 10, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(property.rating!.toStringAsFixed(1),
                            style: T.ratingNum),
                        const SizedBox(width: 2),
                        Text('(${property.reviewCount ?? 0})',
                            style: T.ratingCount),
                      ],
                    ),
                  const SizedBox(height: 3),
                  Text(property.priceLabel, style: T.priceMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (property.status) {
      case PropertyStatus.forRent:
        return AppColors.secondary;
      case PropertyStatus.forSale:
        return AppColors.primary;
      case PropertyStatus.forLease:
        return AppColors.success;
    }
  }
}

class PropertyCardHorizontal extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCardHorizontal(
      {super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: _kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: property.photos.isNotEmpty
                      ? _propertyImage(property.photos.first, height: 140, width: 220, cacheWidth: 440)
                      : const SizedBox(height: 140, child: ColoredBox(color: AppColors.accent)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: _kStatusBgDecoration,
                    child: Text(property.statusLabel,
                        style: T.badgeWhiteSm),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: T.cardTitleXs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.secondary, size: 12),
                      const SizedBox(width: 2),
                      Text(property.area, style: T.locationSm),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(property.priceLabel, style: T.priceLg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  final String propertyId;
  final BoxDecoration decoration;
  final double size;
  final double iconSize;

  const _SaveButton({
    required this.propertyId,
    required this.decoration,
    required this.size,
    required this.iconSize,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saved = false;
  bool _loading = false;

  Future<void> _toggle() async {
    if (_loading) return;
    final authed = await ensureAuth(context);
    if (!authed || !mounted) return;
    setState(() => _loading = true);
    try {
      final repo = const PropertyRepository();
      if (_saved) {
        await repo.unsaveProperty(widget.propertyId);
      } else {
        await repo.saveProperty(widget.propertyId);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (_) {
      // silently ignore — icon stays at previous state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: DecoratedBox(
          decoration: widget.decoration,
          child: _loading
              ? Padding(
                  padding: EdgeInsets.all(widget.size * 0.22),
                  child: const CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppColors.primary),
                )
              : Icon(
                  _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _saved ? AppColors.error : AppColors.primary,
                  size: widget.iconSize,
                ),
        ),
      ),
    );
  }
}
