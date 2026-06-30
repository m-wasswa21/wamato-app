import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/saved/saved_cubit.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/property_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_guard.dart';
import '../../models/property.dart';
import '../../widgets/custom_button.dart';
import '../map/map_screen.dart';
import '../payment/payment_sheet.dart';
import 'image_gallery_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _unlocked = false;
  int _currentImage = 0;
  bool _descExpanded = false;
  Property? _fullProperty;
  bool _loadingFull = true;

  final _pageCtrl = PageController();

  Property get p => _fullProperty ?? widget.property;

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFull() async {
    try {
      final full =
          await const PropertyRepository().getProperty(widget.property.id);
      if (mounted) setState(() { _fullProperty = full; _loadingFull = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFull = false);
    }
  }

  // ── Root ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildPhotoSection(),
                SliverToBoxAdapter(child: _buildBody()),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Full-width photo section ──────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo pageview
            p.photos.isEmpty
                ? Container(color: const Color(0xFFE8E8E8),
                    child: const Center(child: Icon(Icons.home_rounded, size: 64, color: Color(0xFFBBBBBB))))
                : PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentImage = i),
                    itemCount: p.photos.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageGalleryScreen(
                              images: p.photos, initialIndex: i),
                        ),
                      ),
                      child: p.photos[i].startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: p.photos[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: const Color(0xFFE8E8E8)),
                              errorWidget: (_, __, ___) =>
                                  Container(color: const Color(0xFFE8E8E8)),
                            )
                          : Image.asset(p.photos[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: const Color(0xFFE8E8E8))),
                    ),
                  ),

            // Bottom gradient fade for dots
            if (p.photos.length > 1)
              const Positioned(
                bottom: 0, left: 0, right: 0,
                child: SizedBox(
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x55000000)],
                      ),
                    ),
                  ),
                ),
              ),

            // Dot indicators
            if (p.photos.length > 1)
              Positioned(
                bottom: 14,
                left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(p.photos.length, (i) {
                    final active = i == _currentImage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

            // Status badge bottom-left
            Positioned(
              bottom: p.photos.length > 1 ? 36 : 14,
              left: 16,
              child: _photoBadge(p.statusLabel,
                  p.status == PropertyStatus.forRent
                      ? AppColors.secondary
                      : AppColors.primary),
            ),

            // Verified badge bottom-left (next to status)
            if (p.isVerified)
              Positioned(
                bottom: p.photos.length > 1 ? 36 : 14,
                left: _statusBadgeWidth(p.statusLabel) + 26,
                child: _photoBadge('✓ Verified', AppColors.success),
              ),

            // Photo count chip top-right (when >1)
            if (p.photos.length > 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 54,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_currentImage + 1} / ${p.photos.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
      // Floating back button
      leading: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Color(0xFF222222)),
            ),
          ),
        ),
      ),
      // Save button — reads from SavedCubit
      actions: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: BlocBuilder<SavedCubit, Set<String>>(
              builder: (context, savedIds) {
                final saved = savedIds.contains(p.id);
                return GestureDetector(
                  onTap: () async {
                    final authed = await ensureAuth(context);
                    if (authed && context.mounted) {
                      context.read<SavedCubit>().toggle(p.id);
                    }
                  },
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: saved ? const Color(0xFFFF5A5F) : const Color(0xFF222222),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  double _statusBadgeWidth(String label) {
    // Approximate widths for badge positioning
    return label.length * 7.5 + 24;
  }

  Widget _photoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }

  // ── Main body ─────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingFull)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Color(0xFFEBEBEB),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

          // ── Title + Location + Specs ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p.type,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF717171))),
                ),
                const SizedBox(height: 10),

                // Title
                Text(p.title,
                    style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF222222),
                        height: 1.25)),
                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: Color(0xFF717171)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('${p.area}, ${p.district}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717171),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Inline specs row
                _buildInlineSpecs(),

                // Rating row (short stays)
                if (p.isShortStay && (p.rating ?? 0) > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFF222222)),
                      const SizedBox(width: 4),
                      Text(p.rating!.toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222))),
                      const SizedBox(width: 6),
                      Text('· ${p.reviewCount ?? 0} reviews',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF717171),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF717171))),
                    ],
                  ),
                ],
              ],
            ),
          ),

          _divider(),

          // ── Listed by Wamato ──────────────────────────────────────────
          _buildHostSection(),

          _divider(),

          // ── Description ───────────────────────────────────────────────
          if (p.shortDescription.isNotEmpty) ...[
            _buildDescription(),
            _divider(),
          ],

          // ── What this place offers (amenities) ────────────────────────
          if (_hasAmenities) ...[
            _buildAmenities(),
            _divider(),
          ],

          // ── Short-stay info (guests · nights · fee) ───────────────────
          if (p.isShortStay) ...[
            _buildShortStayInfo(),
            _divider(),
          ],

          // ── Full property details (locked/unlocked) ───────────────────
          _buildLockedSection(),

          _divider(),

          // ── Wamato contact ────────────────────────────────────────────
          _buildContactSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Divider(height: 1, thickness: 0.8, color: Color(0xFFEBEBEB)),
  );

  // ── Inline specs ──────────────────────────────────────────────────────────
  Widget _buildInlineSpecs() {
    final parts = <String>[];
    if (p.bedrooms != null)
      parts.add('${p.bedrooms} bed${p.bedrooms! > 1 ? "s" : ""}');
    if (p.bathrooms != null)
      parts.add('${p.bathrooms} bath${p.bathrooms! > 1 ? "s" : ""}');
    if (p.floorSize != null)
      parts.add('${p.floorSize!.toInt()} m²');
    if (p.plotSize != null)
      parts.add('${p.plotSize!.toInt()} ft² plot');
    if (p.parkingSpaces != null && p.parkingSpaces! > 0)
      parts.add('${p.parkingSpaces} parking');
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF717171),
          fontWeight: FontWeight.w400,
          height: 1.5),
    );
  }

  // ── Wamato host card ──────────────────────────────────────────────────────
  Widget _buildHostSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text('W',
                  style: GoogleFonts.urbanist(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Listed by Wamato Property Hub',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text("Uganda's #1 Property Platform",
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF717171))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Verified',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }

  // ── Description ───────────────────────────────────────────────────────────
  Widget _buildDescription() {
    final text = p.shortDescription;
    final isLong = text.length > 200;
    final displayed = (!_descExpanded && isLong)
        ? '${text.substring(0, 200)}...'
        : text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this property',
              style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222))),
          const SizedBox(height: 12),
          Text(displayed,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF444444),
                  height: 1.7)),
          if (isLong) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Row(
                children: [
                  Text(_descExpanded ? 'Show less' : 'Show more',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF222222))),
                  const SizedBox(width: 4),
                  Icon(
                    _descExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF222222),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Amenities ─────────────────────────────────────────────────────────────
  bool get _hasAmenities =>
      p.hasSecurity ||
      p.hasFurnishing ||
      p.hasInternet ||
      p.hasSwimmingPool ||
      p.hasParking ||
      p.hasGenerator ||
      p.hasSolar ||
      p.hasWaterTank;

  Widget _buildAmenities() {
    final all = <_Amenity>[];
    if (p.hasSecurity)
      all.add(const _Amenity(Icons.security_rounded, 'Security Guard'));
    if (p.hasFurnishing)
      all.add(const _Amenity(Icons.chair_rounded, 'Furnished'));
    if (p.hasInternet)
      all.add(const _Amenity(Icons.wifi_rounded, 'Internet / WiFi'));
    if (p.hasSwimmingPool)
      all.add(const _Amenity(Icons.pool_rounded, 'Swimming Pool'));
    if (p.hasParking)
      all.add(const _Amenity(Icons.local_parking_rounded, 'Parking'));
    if (p.hasGenerator)
      all.add(const _Amenity(Icons.bolt_rounded, 'Backup Power'));
    if (p.hasSolar)
      all.add(const _Amenity(Icons.wb_sunny_rounded, 'Solar Power'));
    if (p.hasWaterTank)
      all.add(const _Amenity(Icons.water_drop_rounded, 'Water Tank'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What this place offers',
              style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222))),
          const SizedBox(height: 16),
          // 2-column grid
          ...List.generate((all.length / 2).ceil(), (row) {
            final left = all[row * 2];
            final right = row * 2 + 1 < all.length ? all[row * 2 + 1] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(child: _amenityItem(left)),
                  Expanded(
                      child: right != null
                          ? _amenityItem(right)
                          : const SizedBox.shrink()),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _amenityItem(_Amenity a) {
    return Row(
      children: [
        Icon(a.icon, size: 20, color: const Color(0xFF222222)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(a.label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF222222))),
        ),
      ],
    );
  }

  // ── Short-stay info ───────────────────────────────────────────────────────
  Widget _buildShortStayInfo() {
    final items = <Map<String, dynamic>>[];
    if (p.maxGuests != null)
      items.add({'icon': Icons.people_rounded, 'text': 'Up to ${p.maxGuests} guests'});
    if (p.minNights != null)
      items.add({'icon': Icons.nights_stay_rounded,
          'text': 'Minimum ${p.minNights} night${p.minNights! > 1 ? "s" : ""}'});
    if (p.cleaningFee != null) {
      final fee = p.cleaningFee! >= 1000
          ? 'UGX ${(p.cleaningFee! / 1000).toStringAsFixed(0)}K'
          : 'UGX ${p.cleaningFee!.toInt()}';
      items.add({'icon': Icons.cleaning_services_rounded, 'text': '$fee cleaning fee'});
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stay details',
              style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222))),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Icon(item['icon'] as IconData,
                    size: 20, color: const Color(0xFF222222)),
                const SizedBox(width: 14),
                Text(item['text'] as String,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF444444))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Locked / unlocked details ─────────────────────────────────────────────
  Widget _buildLockedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full property details',
              style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222))),
          const SizedBox(height: 14),
          if (!_unlocked) ...[
            _lockedItem(Icons.location_on_rounded, 'Exact Location'),
            _lockedItem(Icons.phone_rounded, 'Owner Phone Number'),
            _lockedItem(Icons.chat_rounded, 'WhatsApp Contact'),
            _lockedItem(Icons.photo_library_rounded, 'Full Photo Gallery'),
          ] else ...[
            _unlockedItem(Icons.location_on_rounded, 'Exact Location',
                p.exactLocation ?? '${p.area}, ${p.district}'),
            _unlockedItem(Icons.phone_rounded, 'Owner Phone',
                p.ownerPhone ?? '+256 700 000 000'),
            _unlockedItem(Icons.chat_rounded, 'WhatsApp',
                p.ownerWhatsApp ?? '+256 700 000 000'),
            const SizedBox(height: 8),
            _directionsCard(),
          ],
        ],
      ),
    );
  }

  Widget _lockedItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFBBBBBB)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222))),
                const Text('Unlock to reveal',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFAAAAAA))),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }

  Widget _unlockedItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBE9D4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF717171),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222))),
              ],
            ),
          ),
          const Icon(Icons.lock_open_rounded,
              size: 16, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _directionsCard() {
    return GestureDetector(
      onTap: _showDirectionsSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBCCEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.directions_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get directions to this property',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222))),
                  Text('Open Google Maps or in-app map',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF717171))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  // ── Wamato contact section ────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Wamato',
              style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222))),
          const SizedBox(height: 16),

          // 4 contact buttons
          Row(
            children: [
              _contactBtn(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: AppColors.primary,
                onTap: () async {
                  try {
                    await launchUrl(Uri.parse('tel:+256700000000'));
                  } catch (_) {}
                },
              ),
              const SizedBox(width: 10),
              _contactBtn(
                icon: FontAwesomeIcons.whatsapp,
                label: 'WhatsApp',
                color: AppColors.success,
                onTap: () async {
                  try {
                    await launchUrl(Uri.parse('https://wa.me/256700000000'),
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                isFa: true,
              ),
              const SizedBox(width: 10),
              _contactBtn(
                icon: Icons.email_rounded,
                label: 'Email',
                color: AppColors.secondary,
                onTap: () async {
                  try {
                    await launchUrl(Uri.parse('mailto:info@wamato.ug'));
                  } catch (_) {}
                },
              ),
              const SizedBox(width: 10),
              _contactBtn(
                icon: Icons.language_rounded,
                label: 'Website',
                color: AppColors.warning,
                onTap: () async {
                  try {
                    await launchUrl(Uri.parse('https://www.wamato.ug'),
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Report listing
          GestureDetector(
            onTap: () async {
              try {
                await launchUrl(
                    Uri.parse(
                        'mailto:info@wamato.ug?subject=Report%20Listing%20-%20${Uri.encodeComponent(p.title)}'),
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCCCC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Report this listing',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error)),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.error, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFa = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              isFa
                  ? FaIcon(icon, color: color, size: 18)
                  : Icon(icon, color: color, size: 18),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar (Airbnb style) ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
              top: BorderSide(color: Color(0xFFEBEBEB), width: 0.8)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
        child: _unlocked ? _unlockedBottomBar() : _lockedBottomBar(),
      ),
    );
  }

  Widget _lockedBottomBar() {
    return Row(
      children: [
        // Price column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.priceLabel,
                style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF222222))),
            Text(p.status == PropertyStatus.forRent ? 'per month' : 'total price',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF717171))),
          ],
        ),
        const SizedBox(width: 16),
        // Unlock button
        Expanded(
          child: GestureDetector(
            onTap: () => _showUnlockSheet(),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🔓  Unlock Details',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _unlockedBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Directions
        GestureDetector(
          onTap: _showDirectionsSheet,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Get Directions',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Call + WhatsApp
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await launchUrl(
                        Uri.parse('tel:${p.ownerPhone ?? ""}'));
                  } catch (_) {}
                },
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final phone = (p.ownerWhatsApp ?? '')
                      .replaceAll(RegExp(r'[^0-9]'), '');
                  try {
                    await launchUrl(Uri.parse('https://wa.me/$phone'),
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Directions sheet ──────────────────────────────────────────────────────
  void _showDirectionsSheet() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEBEBEB),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(p.exactLocation ?? '${p.area}, ${p.district}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF717171))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEBEBEB)),
            const SizedBox(height: 16),
            _directionOption(
              icon: FontAwesomeIcons.locationArrow,
              iconColor: AppColors.primary,
              bgColor: AppColors.primaryFaint,
              title: 'Open in Google Maps',
              subtitle: 'Turn-by-turn navigation',
              onTap: () { Navigator.pop(context); _launchGoogleMaps(); },
            ),
            const SizedBox(height: 10),
            _directionOption(
              icon: FontAwesomeIcons.map,
              iconColor: AppColors.secondary,
              bgColor: const Color(0x1438A4C8),
              title: 'View on Wamato Map',
              subtitle: 'See property pin on in-app map',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MapScreen(focusProperty: p)));
              },
            ),
            const SizedBox(height: 10),
            _directionOption(
              icon: FontAwesomeIcons.earthAfrica,
              iconColor: AppColors.success,
              bgColor: const Color(0x1410B981),
              title: 'Open in Browser',
              subtitle: 'View on Google Maps in browser',
              onTap: () { Navigator.pop(context); _copyCoordinates(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _directionOption({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Center(child: FaIcon(icon, color: iconColor, size: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222))),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF717171))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    if (p.latitude == null || p.longitude == null) {
      _showSnack('GPS coordinates not available', AppColors.warning);
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=driving');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Could not open Google Maps', AppColors.warning);
    }
  }

  Future<void> _copyCoordinates() async {
    if (p.latitude == null || p.longitude == null) {
      _showSnack('GPS coordinates not available', AppColors.warning);
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Unlock sheet ──────────────────────────────────────────────────────────
  Future<void> _showUnlockSheet() async {
    final authed = await ensureAuth(context);
    if (!authed || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UnlockSheet(
        onPackageSelected: (label, amount) {
          Navigator.pop(context); // Close package sheet
          // Open payment sheet
          showPaymentSheet(
            context: context,
            amount: amount,
            type: label.contains('Pass') ? 'unlock_pack' : 'unlock_property',
            propertyId: p.id,
            description: '$label — ${p.title}',
            onSuccess: () {
              if (mounted) {
                setState(() => _unlocked = true);
                _showSnack('Property unlocked!', AppColors.success);
              }
            },
          );
        },
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _Amenity {
  final IconData icon;
  final String label;
  const _Amenity(this.icon, this.label);
}

// ── Unlock bottom sheet ───────────────────────────────────────────────────────
class _UnlockSheet extends StatelessWidget {
  final void Function(String label, int amount) onPackageSelected;
  const _UnlockSheet({required this.onPackageSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Unlock Property Details',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF222222))),
          const SizedBox(height: 4),
          const Text('Choose an access package to reveal full details',
              style: TextStyle(fontSize: 13, color: Color(0xFF717171))),
          const SizedBox(height: 20),
          ...AppConstants.unlockPackages.entries.map((e) {
            final label = e.key;
            final amount = e.value;
            final fmtPrice = amount >= 1000
                ? 'UGX ${(amount / 1000).toStringAsFixed(0)},000'
                : 'UGX $amount';
            final desc = switch (label) {
              'Single Property' => 'Access 1 property',
              '5 Properties' => 'Access 5 properties',
              'Weekly Pass' => 'Unlimited for 7 days',
              'Monthly Pass' => 'Unlimited for 30 days',
              _ => '',
            };
            return _PackageTile(
              label: label,
              price: fmtPrice,
              desc: desc,
              onTap: () => onPackageSelected(label, amount),
            );
          }),
          const SizedBox(height: 8),
          const Text('Secure payment via MTN Money or Airtel Money',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final String label, price, desc;
  final VoidCallback onTap;

  const _PackageTile(
      {required this.label,
      required this.price,
      required this.desc,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBest = label == 'Weekly Pass';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isBest ? AppColors.primaryFaint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isBest ? AppColors.primary : const Color(0xFFEBEBEB),
              width: isBest ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222))),
                      if (isBest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Best Value',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF717171))),
                ],
              ),
            ),
            Text(price,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 13),
          ],
        ),
      ),
    );
  }
}
