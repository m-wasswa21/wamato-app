import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Failed to load listings: $e', AppColors.error);
      }
    }
  }

  Future<void> _confirmDelete(int index) async {
    final property = _listings[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Listing',
            style: GoogleFonts.urbanist(
                fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete "${property.title}"? This cannot be undone.',
          style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w700, color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await const PropertyRepository().deleteProperty(property.id);
      if (mounted) {
        setState(() => _listings.removeAt(index));
        _snack('Listing deleted', AppColors.success);
      }
    } catch (e) {
      if (mounted) _snack('Delete failed: $e', AppColors.error);
    }
  }

  void _openEdit(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditSheet(
        property: _listings[index],
        onSaved: (updated) {
          setState(() => _listings[index] = updated);
          _snack('Listing updated', AppColors.success);
        },
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.urbanist(color: AppColors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
                              onEdit: () => _openEdit(i),
                              onDelete: () => _confirmDelete(i),
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

// ── Listing tile ──────────────────────────────────────────────────────────────
class _ListingTile extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListingTile({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

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
                          placeholder: (_, __) => _placeholder(),
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
                  _btn(Icons.edit_rounded, AppColors.secondary, onEdit),
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

// ── Edit bottom sheet ─────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final Property property;
  final void Function(Property updated) onSaved;

  const _EditSheet({required this.property, required this.onSaved});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _titleCtrl =
      TextEditingController(text: widget.property.title);
  late final _priceCtrl =
      TextEditingController(text: widget.property.price.toInt().toString());
  late final _descCtrl =
      TextEditingController(text: widget.property.shortDescription);
  late final _phoneCtrl =
      TextEditingController(text: widget.property.ownerPhone ?? '');
  late final _waCtrl =
      TextEditingController(text: widget.property.ownerWhatsApp ?? '');
  late final _locationCtrl =
      TextEditingController(text: widget.property.exactLocation ?? '');

  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '').trim());
    if (title.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Title and price are required',
            style: GoogleFonts.urbanist(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'title': title,
        'price': price,
      };
      if (_descCtrl.text.trim().isNotEmpty) {
        fields['description'] = _descCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        fields['owner_phone'] = _phoneCtrl.text.trim();
      }
      if (_waCtrl.text.trim().isNotEmpty) {
        fields['owner_whatsapp'] = _waCtrl.text.trim();
      }
      if (_locationCtrl.text.trim().isNotEmpty) {
        fields['exact_location'] = _locationCtrl.text.trim();
      }

      await const PropertyRepository()
          .updateProperty(widget.property.id, fields);

      if (!mounted) return;
      // Build an updated Property copy with the new values
      final updated = Property(
        id: widget.property.id,
        title: title,
        type: widget.property.type,
        status: widget.property.status,
        price: price,
        district: widget.property.district,
        area: widget.property.area,
        shortDescription: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : widget.property.shortDescription,
        photos: widget.property.photos,
        isVerified: widget.property.isVerified,
        listingPackage: widget.property.listingPackage,
        bedrooms: widget.property.bedrooms,
        bathrooms: widget.property.bathrooms,
        floorSize: widget.property.floorSize,
        plotSize: widget.property.plotSize,
        ownerPhone: _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : widget.property.ownerPhone,
        ownerWhatsApp: _waCtrl.text.trim().isNotEmpty
            ? _waCtrl.text.trim()
            : widget.property.ownerWhatsApp,
        exactLocation: _locationCtrl.text.trim().isNotEmpty
            ? _locationCtrl.text.trim()
            : widget.property.exactLocation,
        createdAt: widget.property.createdAt,
        hasSecurity: widget.property.hasSecurity,
        hasFurnishing: widget.property.hasFurnishing,
        hasInternet: widget.property.hasInternet,
        hasSwimmingPool: widget.property.hasSwimmingPool,
        hasParking: widget.property.hasParking,
        hasGenerator: widget.property.hasGenerator,
        hasSolar: widget.property.hasSolar,
        hasWaterTank: widget.property.hasWaterTank,
      );

      Navigator.pop(context);
      widget.onSaved(updated);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Update failed: $e',
              style: GoogleFonts.urbanist(color: Colors.white)),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom + 20;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
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
                    color: const Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('Edit Listing',
              style: GoogleFonts.urbanist(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF222222))),
          const SizedBox(height: 4),
          Text(widget.property.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF717171))),
          const SizedBox(height: 24),

          _label('Property Title *'),
          _field(_titleCtrl, 'e.g. 3 Bedroom House in Kololo'),
          const SizedBox(height: 16),

          _label('Price (UGX) *'),
          _field(_priceCtrl, 'e.g. 1500000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 16),

          _label('Description'),
          _field(_descCtrl, 'Describe your property...', maxLines: 3),
          const SizedBox(height: 16),

          _label('Owner Phone Number'),
          _field(_phoneCtrl, '+256 700 000 000',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),

          _label('WhatsApp Number'),
          _field(_waCtrl, '+256 700 000 000',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),

          _label('Exact Location / Address'),
          _field(_locationCtrl, 'e.g. Plot 14, Acacia Avenue'),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text('Save Changes',
                      style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444))),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontSize: 14, color: Color(0xFFAAAAAA)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}
