import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/property_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_guard.dart';
import '../../models/property.dart';
import '../../widgets/custom_button.dart';
import '../map/map_screen.dart';
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
  bool _saved = false;
  bool _savingInProgress = false;

  Property get p => widget.property;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildContent()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.dark.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.dark, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () async {
              if (_savingInProgress) return;
              final authed = await ensureAuth(context);
              if (!authed || !mounted) return;
              setState(() => _savingInProgress = true);
              try {
                if (_saved) {
                  await const PropertyRepository().unsaveProperty(p.id);
                } else {
                  await const PropertyRepository().saveProperty(p.id);
                }
                if (mounted) setState(() => _saved = !_saved);
              } catch (_) {}
              finally {
                if (mounted) setState(() => _savingInProgress = false);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.dark.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: _savingInProgress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: AppColors.primary))
                  : Icon(
                      _saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _saved ? AppColors.error : AppColors.dark,
                      size: 20,
                    ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemCount: p.photos.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageGalleryScreen(
                      images: p.photos,
                      initialIndex: i,
                    ),
                  ),
                ),
                child: p.photos[i].startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: p.photos[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppColors.accent.withOpacity(0.3)),
                        errorWidget: (_, __, ___) => Container(
                            color: AppColors.accent.withOpacity(0.3),
                            child: const Icon(Icons.home_rounded,
                                color: AppColors.secondary, size: 64)),
                      )
                    : Image.asset(
                        p.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppColors.accent.withOpacity(0.3),
                            child: const Icon(Icons.home_rounded,
                                color: AppColors.secondary, size: 64)),
                      ),
              ),
            ),
            // Image counter
            if (p.photos.length > 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImage + 1}/${p.photos.length}',
                    style: GoogleFonts.urbanist(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            // Badges
            Positioned(
              top: 60,
              left: 16,
              child: _badge(p.statusLabel,
                  p.status == PropertyStatus.forRent
                      ? AppColors.secondary
                      : AppColors.primary),
            ),
            if (p.isVerified)
              Positioned(
                top: 60,
                right: 16,
                child: _badge('✓ Verified', AppColors.success),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Text(label,
          style: GoogleFonts.urbanist(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildContent() {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(p.title,
                          style: GoogleFonts.urbanist(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.priceLabel,
                            style: GoogleFonts.urbanist(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        if (p.status == PropertyStatus.forRent)
                          Text('per month',
                              style: GoogleFonts.urbanist(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 4),
                    Text('${p.area}, ${p.district}',
                        style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Specs row
          _buildSpecsRow(),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description',
                    style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark)),
                const SizedBox(height: 10),
                Text(p.shortDescription,
                    style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.7)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          // Amenities
          _buildAmenities(),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          // Locked info section
          _buildLockedSection(),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          // Company contact
          _buildCompanyContact(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompanyContact() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Center(
                  child: Text('W',
                      style: GoogleFonts.urbanist(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wamato Property Hub',
                        style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark)),
                    Text("Uganda's #1 Property Platform",
                        style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.successFaint,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Text('Verified',
                    style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contact buttons row
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
                    await launchUrl(
                        Uri.parse('https://wa.me/256700000000'),
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
                    await launchUrl(
                        Uri.parse('mailto:info@wamato.ug'));
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
                    await launchUrl(
                        Uri.parse('https://www.wamato.ug'),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorFaint,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Report this listing',
                        style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error)),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.error, size: 13),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              isFa
                  ? FaIcon(icon, color: color, size: 18)
                  : Icon(icon, color: color, size: 18),
              const SizedBox(height: 5),
              Text(label,
                  style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecsRow() {
    final specs = <Map<String, dynamic>>[];
    if (p.bedrooms != null)
      specs.add({'icon': Icons.bed_rounded, 'value': '${p.bedrooms}', 'label': 'Bedrooms'});
    if (p.bathrooms != null)
      specs.add({'icon': Icons.bathtub_rounded, 'value': '${p.bathrooms}', 'label': 'Bathrooms'});
    if (p.parkingSpaces != null)
      specs.add({'icon': Icons.local_parking_rounded, 'value': '${p.parkingSpaces}', 'label': 'Parking'});
    if (p.floorSize != null)
      specs.add({'icon': Icons.square_foot_rounded, 'value': '${p.floorSize!.toInt()}m²', 'label': 'Floor Size'});
    if (p.plotSize != null)
      specs.add({'icon': Icons.landscape_rounded, 'value': '${p.plotSize!.toInt()}ft²', 'label': 'Plot'});

    if (specs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: specs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Container(
          width: 90,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(specs[i]['icon'] as IconData,
                  color: AppColors.secondary, size: 20),
              const SizedBox(height: 4),
              Text(specs[i]['value'] as String,
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark)),
              Text(specs[i]['label'] as String,
                  style: GoogleFonts.urbanist(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenities() {
    final amenities = <Map<String, dynamic>>[];
    if (p.hasSecurity) amenities.add({'icon': '🔒', 'label': 'Security'});
    if (p.hasFurnishing) amenities.add({'icon': '🛋️', 'label': 'Furnished'});
    if (p.hasInternet) amenities.add({'icon': '📶', 'label': 'Internet'});
    if (p.hasSwimmingPool) amenities.add({'icon': '🏊', 'label': 'Pool'});

    if (amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenities',
              style: GoogleFonts.urbanist(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: amenities
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a['icon'] as String,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(a['label'] as String,
                              style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Property Details',
              style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 16),
          if (!_unlocked) ...[
            _lockedItem(Icons.location_on_rounded, 'Exact Location'),
            _lockedItem(Icons.phone_rounded, 'Owner Phone Number'),
            _lockedItem(Icons.chat_rounded, 'WhatsApp Contact'),
            _lockedItem(Icons.photo_library_rounded, 'Full Photo Gallery'),
            _lockedItem(Icons.description_rounded, 'Property Documents'),
          ] else ...[
            _unlockedItem(Icons.location_on_rounded, 'Exact Location',
                p.exactLocation ?? 'Kololo Hill, Kampala'),
            _unlockedItem(Icons.phone_rounded, 'Owner Phone',
                p.ownerPhone ?? '+256 701 234 567'),
            _unlockedItem(Icons.chat_rounded, 'WhatsApp',
                p.ownerWhatsApp ?? '+256 701 234 567'),
            const SizedBox(height: 4),
            // Directions call-to-action card
            GestureDetector(
              onTap: _showDirectionsSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.locationArrow,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get Directions to this Property',
                              style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dark)),
                          Text('Open Google Maps or in-app navigation',
                              style: GoogleFonts.urbanist(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lockedItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark)),
                Text('Unlock to reveal',
                    style: GoogleFonts.urbanist(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded,
              color: AppColors.textTertiary, size: 18),
        ],
      ),
    );
  }

  Widget _unlockedItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                Text(value,
                    style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark)),
              ],
            ),
          ),
          const Icon(Icons.lock_open_rounded,
              color: AppColors.success, size: 18),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
                color: AppColors.dark.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: _unlocked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Directions — full width, most prominent
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showDirectionsSheet,
                      icon: const FaIcon(FontAwesomeIcons.locationArrow, size: 16),
                      label: Text('Get Directions',
                          style: GoogleFonts.urbanist(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Call + WhatsApp side by side
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('tel:${p.ownerPhone ?? ""}');
                            try { await launchUrl(uri); } catch (_) {}
                          },
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: Text('Call',
                              style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final phone = (p.ownerWhatsApp ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                            final uri = Uri.parse('https://wa.me/$phone');
                            try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
                          },
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                          label: Text('WhatsApp',
                              style: GoogleFonts.urbanist(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : GradientButton(
                label: '🔓  Unlock Details – UGX 5,000',
                onTap: () => _showUnlockSheet(),
              ),
      ),
    );
  }

  // ── Directions ───────────────────────────────────────────────────────────────
  void _showDirectionsSheet() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            // Destination info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                          style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(p.exactLocation ?? '${p.area}, ${p.district}',
                          style: GoogleFonts.urbanist(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 14),
            // Google Maps
            _directionOption(
              icon: FontAwesomeIcons.locationArrow,
              iconColor: AppColors.primary,
              bgColor: AppColors.primary.withOpacity(0.1),
              title: 'Open in Google Maps',
              subtitle: 'Turn-by-turn navigation to this property',
              onTap: () { Navigator.pop(context); _launchGoogleMaps(); },
            ),
            const SizedBox(height: 10),
            // In-app map
            _directionOption(
              icon: FontAwesomeIcons.map,
              iconColor: AppColors.secondary,
              bgColor: AppColors.secondary.withOpacity(0.1),
              title: 'View on Wamato Map',
              subtitle: 'See property pin on the in-app map',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MapScreen(focusProperty: p)));
              },
            ),
            const SizedBox(height: 10),
            // Open in browser maps
            _directionOption(
              icon: FontAwesomeIcons.earthAfrica,
              iconColor: AppColors.success,
              bgColor: AppColors.success.withOpacity(0.1),
              title: 'Open in Browser',
              subtitle: 'View exact pin on Google Maps in your browser',
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: AppColors.dark.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark)),
                  Text(subtitle,
                      style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    if (p.latitude == null || p.longitude == null) {
      _showNoLocationSnack();
      return;
    }
    final lat = p.latitude!;
    final lng = p.longitude!;
    // Direct web URL — works on all Android versions without canLaunchUrl
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showNoLocationSnack();
    }
  }

  Future<void> _copyCoordinates() async {
    if (p.latitude == null || p.longitude == null) {
      _showNoLocationSnack();
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showNoLocationSnack();
    }
  }

  void _showNoLocationSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('GPS coordinates not available for this property',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showUnlockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UnlockSheet(onUnlock: (pkg) {
        Navigator.pop(context);
        setState(() => _unlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Property unlocked successfully!',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }),
    );
  }
}

class _UnlockSheet extends StatelessWidget {
  final void Function(String pkg) onUnlock;

  const _UnlockSheet({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final packages = [
      {'label': 'Single Property', 'price': 'UGX 5,000', 'desc': 'Access 1 property'},
      {'label': '5 Properties', 'price': 'UGX 20,000', 'desc': 'Access 5 properties'},
      {'label': 'Weekly Pass', 'price': 'UGX 30,000', 'desc': 'Unlimited for 7 days'},
      {'label': 'Monthly Pass', 'price': 'UGX 100,000', 'desc': 'Unlimited for 30 days'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Unlock Property Details',
              style: GoogleFonts.urbanist(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark)),
          const SizedBox(height: 4),
          Text('Choose an access package to reveal full details',
              style: GoogleFonts.urbanist(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...packages.map((pkg) => _PackageTile(
                label: pkg['label']!,
                price: pkg['price']!,
                desc: pkg['desc']!,
                onTap: () => onUnlock(pkg['label']!),
              )),
          const SizedBox(height: 6),
          Text('Secure payment via MTN Money, Airtel Money, or Card',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                  fontSize: 11, color: AppColors.textTertiary)),
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
          color: isBest ? AppColors.primary.withOpacity(0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isBest ? AppColors.primary : AppColors.border,
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
                          style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark)),
                      if (isBest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Best Value',
                              style: GoogleFonts.urbanist(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  Text(desc,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(price,
                style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }
}
