import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/property_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import '../property/property_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<Property> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await const PropertyRepository().getMyListings(size: 50);
      if (mounted) setState(() { _listings = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(int index) async {
    final property = _listings[index];
    try {
      await const PropertyRepository().deleteProperty(property.id);
      if (mounted) setState(() => _listings.removeAt(index));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete listing',
              style: GoogleFonts.urbanist(color: AppColors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Listings',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? _buildShimmer()
            : Column(
                children: [
                  // Summary bar
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.dark.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('${_listings.length}', 'Total'),
                        _divider(),
                        _stat(
                            '${_listings.where((p) => p.isVerified).length}',
                            'Verified'),
                        _divider(),
                        _stat('0', 'Pending'),
                        _divider(),
                        _stat('0', 'Expired'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _listings.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: _listings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _ListingTile(
                              property: _listings[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PropertyDetailScreen(
                                        property: _listings[i])),
                              ),
                              onDelete: () => _delete(i),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
        Text(label,
            style: GoogleFonts.urbanist(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: AppColors.border);

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_outlined, color: AppColors.accent, size: 64),
          const SizedBox(height: 16),
          Text('No Listings Yet',
              style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          Text('Add your first property listing',
              style: GoogleFonts.urbanist(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ListingTile(
      {required this.property, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.dark.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: property.photos.isNotEmpty
                  ? (property.photos.first.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: property.photos.first,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              width: 100,
                              height: 100,
                              color: AppColors.accent.withOpacity(0.3)),
                          errorWidget: (_, __, ___) => _placeholder())
                      : Image.asset(property.photos.first,
                          width: 100, height: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder()))
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('Active',
                              style: GoogleFonts.urbanist(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success)),
                        ),
                        if (property.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: AppColors.success, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark)),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.secondary, size: 12),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                            '${property.area}, ${property.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.urbanist(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Text(property.priceLabel,
                        style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _btn(Icons.edit_rounded, AppColors.secondary, () {}),
                  const SizedBox(height: 8),
                  _btn(Icons.delete_outline_rounded, AppColors.error, onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      width: 100,
      height: 100,
      color: AppColors.accent.withOpacity(0.3),
      child: const Icon(Icons.home_rounded,
          color: AppColors.secondary, size: 32));

  Widget _btn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
