import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/property/property_cubit.dart';
import '../../bloc/property/property_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import 'listings_screen.dart';

// ── Subtype definition ─────────────────────────────────────────────────────────
class PropertySubtype {
  final String label;
  final String sublabel;      // e.g. "2 beds · any status"
  final String image;
  final Color color;
  final bool Function(Property) filter;

  const PropertySubtype({
    required this.label,
    required this.sublabel,
    required this.image,
    required this.color,
    required this.filter,
  });

  int countIn(List<Property> all) => all.where(filter).length;
}

// ── Subtype catalogue — one list per property type ─────────────────────────────
class _Subtypes {
  static List<PropertySubtype> forType(String type) {
    switch (type) {
      case 'House':
        return [
          PropertySubtype(
            label: 'Self-Contained / 1 Bedroom',
            sublabel: '1 bed',
            image: 'assets/images/prop2.jpg',
            color: AppColors.secondary,
            filter: (p) =>
                p.type == 'House' &&
                !p.isShortStay &&
                (p.bedrooms == null || p.bedrooms! <= 1),
          ),
          PropertySubtype(
            label: '2 Bedroom House',
            sublabel: '2 beds',
            image: 'assets/images/prop1.jpg',
            color: AppColors.primary,
            filter: (p) =>
                p.type == 'House' && !p.isShortStay && p.bedrooms == 2,
          ),
          PropertySubtype(
            label: '3 Bedroom House',
            sublabel: '3 beds',
            image: 'assets/images/prop7.jpg',
            color: AppColors.secondary,
            filter: (p) =>
                p.type == 'House' && !p.isShortStay && p.bedrooms == 3,
          ),
          PropertySubtype(
            label: '4 Bedroom House',
            sublabel: '4 beds',
            image: 'assets/images/prop8.jpg',
            color: AppColors.success,
            filter: (p) =>
                p.type == 'House' && !p.isShortStay && p.bedrooms == 4,
          ),
          PropertySubtype(
            label: '5+ Bedroom / Mansion',
            sublabel: '5+ beds',
            image: 'assets/images/prop4.jpg',
            color: AppColors.warning,
            filter: (p) =>
                p.type == 'House' &&
                !p.isShortStay &&
                p.bedrooms != null &&
                p.bedrooms! >= 5,
          ),
        ];

      case 'Apartment':
        return [
          PropertySubtype(
            label: 'Bedsitter / Studio',
            sublabel: 'Studio',
            image: 'assets/images/prop2.jpg',
            color: AppColors.secondary,
            filter: (p) =>
                p.type == 'Apartment' &&
                !p.isShortStay &&
                (p.bedrooms == null || p.bedrooms! <= 1),
          ),
          PropertySubtype(
            label: '2 Bedroom Apartment',
            sublabel: '2 beds',
            image: 'assets/images/prop7.jpg',
            color: AppColors.primary,
            filter: (p) =>
                p.type == 'Apartment' &&
                !p.isShortStay &&
                p.bedrooms == 2,
          ),
          PropertySubtype(
            label: '3 Bedroom Apartment',
            sublabel: '3 beds',
            image: 'assets/images/prop2.jpg',
            color: AppColors.secondary,
            filter: (p) =>
                p.type == 'Apartment' &&
                !p.isShortStay &&
                p.bedrooms == 3,
          ),
          PropertySubtype(
            label: 'Penthouse / Executive',
            sublabel: '4+ beds',
            image: 'assets/images/prop4.jpg',
            color: AppColors.warning,
            filter: (p) =>
                p.type == 'Apartment' &&
                !p.isShortStay &&
                p.bedrooms != null &&
                p.bedrooms! >= 4,
          ),
        ];

      case 'Land':
        return [
          PropertySubtype(
            label: 'Residential Plot',
            sublabel: 'For homes',
            image: 'assets/images/prop5.jpg',
            color: AppColors.success,
            filter: (p) =>
                p.type == 'Land' &&
                (p.plotSize == null || p.plotSize! <= 15000),
          ),
          PropertySubtype(
            label: 'Large Plot / Acreage',
            sublabel: 'Big land',
            image: 'assets/images/prop5.jpg',
            color: AppColors.primary,
            filter: (p) =>
                p.type == 'Land' &&
                p.plotSize != null &&
                p.plotSize! > 15000,
          ),
          PropertySubtype(
            label: 'Commercial Plot',
            sublabel: 'Business use',
            image: 'assets/images/prop3.jpg',
            color: AppColors.warning,
            filter: (p) => p.type == 'Land',
          ),
        ];

      case 'Office':
        return [
          PropertySubtype(
            label: 'Small Office',
            sublabel: '< 100 sqm',
            image: 'assets/images/prop6.jpg',
            color: AppColors.secondary,
            filter: (p) =>
                p.type == 'Office' &&
                (p.floorSize == null || p.floorSize! < 100),
          ),
          PropertySubtype(
            label: 'Medium Office',
            sublabel: '100–300 sqm',
            image: 'assets/images/prop6.jpg',
            color: AppColors.primary,
            filter: (p) =>
                p.type == 'Office' &&
                p.floorSize != null &&
                p.floorSize! >= 100 &&
                p.floorSize! < 300,
          ),
          PropertySubtype(
            label: 'Large / Corporate Office',
            sublabel: '300+ sqm',
            image: 'assets/images/prop3.jpg',
            color: AppColors.success,
            filter: (p) =>
                p.type == 'Office' &&
                p.floorSize != null &&
                p.floorSize! >= 300,
          ),
        ];

      case 'Commercial':
        return [
          PropertySubtype(
            label: 'Shop / Retail Space',
            sublabel: 'Retail',
            image: 'assets/images/prop3.jpg',
            color: AppColors.warning,
            filter: (p) =>
                p.type == 'Commercial' &&
                (p.floorSize == null || p.floorSize! <= 100),
          ),
          PropertySubtype(
            label: 'Large Commercial Space',
            sublabel: 'Showroom / Market',
            image: 'assets/images/prop6.jpg',
            color: AppColors.primary,
            filter: (p) =>
                p.type == 'Commercial' &&
                p.floorSize != null &&
                p.floorSize! > 100,
          ),
        ];

      case 'Warehouse':
        return [
          PropertySubtype(
            label: 'Standard Warehouse',
            sublabel: '< 500 sqm',
            image: 'assets/images/prop6.jpg',
            color: AppColors.secondary,
            filter: (p) =>
                p.type == 'Warehouse' &&
                (p.floorSize == null || p.floorSize! < 500),
          ),
          PropertySubtype(
            label: 'Large / Industrial Warehouse',
            sublabel: '500+ sqm',
            image: 'assets/images/prop3.jpg',
            color: AppColors.primary,
            filter: (p) =>
                p.type == 'Warehouse' &&
                p.floorSize != null &&
                p.floorSize! >= 500,
          ),
        ];

      case 'Airbnb':
        return [
          PropertySubtype(
            label: 'Studio / 1 Bedroom',
            sublabel: 'Solo · Couple',
            image: 'assets/images/prop2.jpg',
            color: AppColors.error,
            filter: (p) =>
                p.isShortStay &&
                (p.bedrooms == null || p.bedrooms! <= 1),
          ),
          PropertySubtype(
            label: '2 Bedroom Stay',
            sublabel: 'Small group',
            image: 'assets/images/prop7.jpg',
            color: AppColors.primary,
            filter: (p) => p.isShortStay && p.bedrooms == 2,
          ),
          PropertySubtype(
            label: 'Family / 3+ Bedrooms',
            sublabel: 'Family · Groups',
            image: 'assets/images/prop4.jpg',
            color: AppColors.success,
            filter: (p) =>
                p.isShortStay &&
                p.bedrooms != null &&
                p.bedrooms! >= 3,
          ),
          PropertySubtype(
            label: 'Holiday Apartments',
            sublabel: 'Holiday Apt',
            image: 'assets/images/prop8.jpg',
            color: AppColors.secondary,
            filter: (p) => p.type == 'Holiday Apt',
          ),
        ];

      default:
        return [];
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class CategoryScreen extends StatelessWidget {
  final String categoryType;
  final String categoryLabel;
  final String categoryImage;

  const CategoryScreen({
    super.key,
    required this.categoryType,
    required this.categoryLabel,
    required this.categoryImage,
  });

  bool get _isStayType =>
      categoryType == 'Airbnb' || categoryType == 'Holiday Apt';

  List<Property> _pool(PropertyState state) {
    if (state is PropertyLoaded) {
      final seen = <String>{};
      return [...state.featured, ...state.stays, ...state.recent]
          .where((p) => seen.add(p.id))
          .toList();
    }
    return sampleProperties;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyCubit, PropertyState>(
      builder: (context, state) {
        final pool = _pool(state);
        return _buildContent(context, pool);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Property> pool) {
    final allOfType = pool.where((p) {
      if (_isStayType) return p.isShortStay;
      return p.type == categoryType && !p.isShortStay;
    }).toList();

    final subtypes = _Subtypes.forType(categoryType)
        .where((s) => s.countIn(pool) > 0)
        .toList();

    final totalCount = allOfType.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryLabel,
          style: GoogleFonts.urbanist(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.whiteFaint,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Text(
                  '$totalCount',
                  style: GoogleFonts.urbanist(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── "View All" row ──────────────────────────────────────────────────
          _SubtypeRow(
            label: 'All $categoryLabel',
            sublabel: 'Any type · any status',
            count: totalCount,
            image: categoryImage,
            color: AppColors.primary,
            onTap: () => _openListings(context, null),
          ),

          if (subtypes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 22, 0, 12),
              child: Text(
                'Browse by Subtype',
                style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark),
              ),
            ),
            ...subtypes.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubtypeRow(
                    label: s.label,
                    sublabel: s.sublabel,
                    count: s.countIn(pool),
                    image: s.image,
                    color: s.color,
                    onTap: () => _openListings(context, s),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _openListings(BuildContext context, PropertySubtype? sub) {
    // For stay categories the subtypeFilter always drives the results;
    // "All Short Stays" uses a catch-all predicate so both Airbnb and
    // Holiday Apt properties pass the isShortStay guard in ListingsScreen.
    final filter = sub?.filter ??
        (_isStayType ? (Property p) => p.isShortStay : null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingsScreen(
          title: sub?.label ?? 'All $categoryLabel',
          initialType: _isStayType ? null : categoryType,
          subtypeFilter: filter,
        ),
      ),
    );
  }
}

// ── Row widget ─────────────────────────────────────────────────────────────────
class _SubtypeRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final int count;
  final String image;
  final Color color;
  final VoidCallback onTap;

  const _SubtypeRow({
    required this.label,
    required this.sublabel,
    required this.count,
    required this.image,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          boxShadow: [
            BoxShadow(
                color: AppColors.darkShadow,
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Image.asset(
                image,
                width: 90,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 80,
                  color: color.withOpacity(0.15),
                  child: Icon(Icons.home_rounded, color: color, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Text(sublabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count ${count == 1 ? 'property' : 'properties'}',
                        style: GoogleFonts.urbanist(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
