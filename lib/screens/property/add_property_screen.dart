import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/property_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../payment/payment_sheet.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();

  String _selectedType = 'House';
  String _selectedStatus = 'For Rent';
  String _selectedDistrict = 'Kampala';
  String _selectedPackage = 'Basic Listing';
  int _bedrooms = 2;
  int _bathrooms = 1;
  bool _submitting = false;

  // Amenity toggles
  bool _hasSecurity = false;
  bool _hasFurnishing = false;
  bool _hasInternet = false;
  bool _hasPool = false;
  bool _hasParking = false;
  bool _hasGenerator = false;

  final _steps = ['Basic Info', 'Details', 'Photos', 'Payment'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _area.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _step--);
    }
  }

  static String _apiType(String display) {
    const m = {
      'House': 'house', 'Apartment': 'apartment', 'Office': 'office',
      'Land': 'land', 'Warehouse': 'warehouse', 'Commercial': 'commercial',
      'Airbnb': 'short_stay', 'Holiday Apt': 'holiday_apt',
    };
    return m[display] ?? display.toLowerCase();
  }

  static String _apiStatus(String display) {
    const m = {
      'For Rent': 'for_rent',
      'For Sale': 'for_sale',
      'For Lease': 'for_lease',
    };
    return m[display] ?? display.toLowerCase().replaceAll(' ', '_');
  }

  static String _apiPackage(String display) {
    const m = {
      'Basic Listing': 'basic',
      'Premium Listing': 'premium',
      'Featured Listing': 'featured',
    };
    return m[display] ?? 'basic';
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final price = double.tryParse(_price.text.replaceAll(',', '').trim());
    final area = _area.text.trim();
    final desc = _desc.text.trim();

    if (title.isEmpty || price == null || area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all required fields',
            style: GoogleFonts.urbanist(color: AppColors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    // Show payment sheet — on success, create the property
    final packageAmount =
        AppConstants.listingPackages[_selectedPackage] ?? 20000;

    await showPaymentSheet(
      context: context,
      amount: packageAmount,
      type: 'listing_package',
      description: '$_selectedPackage — $title',
      onSuccess: () => _createProperty(title, price, area, desc),
    );
  }

  Future<void> _createProperty(
      String title, double price, String area, String desc) async {
    setState(() => _submitting = true);
    try {
      await const PropertyRepository().createProperty(
        title: title,
        type: _apiType(_selectedType),
        status: _apiStatus(_selectedStatus),
        price: price,
        district: _selectedDistrict,
        area: area,
        description: desc.isEmpty ? title : desc,
        bedrooms: _bedrooms > 0 ? _bedrooms : null,
        bathrooms: _bathrooms > 0 ? _bathrooms : null,
        hasSecurity: _hasSecurity,
        hasFurnishing: _hasFurnishing,
        hasInternet: _hasInternet,
        hasSwimmingPool: _hasPool,
        hasParking: _hasParking,
        hasGenerator: _hasGenerator,
        listingPackage: _apiPackage(_selectedPackage),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Property submitted for review!',
            style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w600, color: AppColors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Submission failed: $e',
            style: GoogleFonts.urbanist(color: AppColors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _step == 0 ? () => Navigator.pop(context) : _back,
        ),
        title: Text('Add Property',
            style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _buildStepper(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (i) {
              final done = i < _step;
              final active = i == _step;
              return Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done || active
                            ? AppColors.primary
                            : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.white, size: 14)
                            : Text('${i + 1}',
                                style: GoogleFonts.urbanist(
                                    color: active
                                        ? AppColors.white
                                        : AppColors.textTertiary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < _step ? AppColors.primary : AppColors.border,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _steps
                .asMap()
                .entries
                .map((e) => Text(e.value,
                    style: GoogleFonts.urbanist(
                        fontSize: 10,
                        fontWeight: e.key == _step
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: e.key == _step
                            ? AppColors.primary
                            : AppColors.textTertiary)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Property Title'),
          const SizedBox(height: 10),
          AppTextField(
            hint: 'e.g. 3 Bedroom House in Kololo',
            controller: _title,
          ),
          const SizedBox(height: 20),
          _sectionTitle('Property Type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.propertyTypes
                .map((t) => _selectable(
                    t, _selectedType, (v) => setState(() => _selectedType = v)))
                .toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Listing Status'),
          const SizedBox(height: 10),
          Row(
            children: ['For Rent', 'For Sale', 'For Lease']
                .map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _selectable(s, _selectedStatus,
                            (v) => setState(() => _selectedStatus = v)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('District'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
              filled: true,
              fillColor: AppColors.white,
            ),
            style: GoogleFonts.urbanist(color: AppColors.dark, fontSize: 14),
            items: AppConstants.districts
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDistrict = v!),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Specific Area / Street'),
          const SizedBox(height: 10),
          AppTextField(hint: 'e.g. Acacia Avenue, Plot 14', controller: _area),
          const SizedBox(height: 20),
          _sectionTitle('Price (UGX)'),
          const SizedBox(height: 10),
          AppTextField(
            hint: 'e.g. 1,500,000',
            controller: _price,
            keyboardType: TextInputType.number,
            prefixIcon: Text('UGX',
                style: GoogleFonts.urbanist(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Bedrooms'),
          const SizedBox(height: 10),
          _counter(_bedrooms, (v) => setState(() => _bedrooms = v), min: 0),
          const SizedBox(height: 20),
          _sectionTitle('Bathrooms'),
          const SizedBox(height: 10),
          _counter(_bathrooms, (v) => setState(() => _bathrooms = v), min: 0),
          const SizedBox(height: 20),
          _sectionTitle('Description'),
          const SizedBox(height: 10),
          AppTextField(
            hint: 'Describe your property...',
            controller: _desc,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          _sectionTitle('Amenities'),
          const SizedBox(height: 10),
          ..._buildAmenityToggles(),
        ],
      ),
    );
  }

  List<Widget> _buildAmenityToggles() {
    final amenities = [
      ('🔒', 'Security Guard', _hasSecurity, (v) => setState(() => _hasSecurity = v)),
      ('🛋️', 'Furnished', _hasFurnishing, (v) => setState(() => _hasFurnishing = v)),
      ('📶', 'Internet / WiFi', _hasInternet, (v) => setState(() => _hasInternet = v)),
      ('🏊', 'Swimming Pool', _hasPool, (v) => setState(() => _hasPool = v)),
      ('🚗', 'Parking', _hasParking, (v) => setState(() => _hasParking = v)),
      ('⚡', 'Backup Power', _hasGenerator, (v) => setState(() => _hasGenerator = v)),
    ];
    return amenities
        .map((a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(a.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a.$2,
                        style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark)),
                  ),
                  Switch(
                    value: a.$3,
                    activeColor: AppColors.primary,
                    onChanged: a.$4,
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _sectionTitle('Property Photos'),
          const SizedBox(height: 6),
          Text('Add at least 3 clear photos of the property',
              style: GoogleFonts.urbanist(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.secondary, size: 44),
                  const SizedBox(height: 10),
                  Text('Tap to browse images',
                      style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary)),
                  Text('PNG, JPG, WEBP supported',
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'High-quality photos improve your listing visibility by 3x',
                    style: GoogleFonts.urbanist(
                        fontSize: 13, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Choose Listing Package'),
          const SizedBox(height: 6),
          Text('Select how you want your property to appear',
              style: GoogleFonts.urbanist(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...AppConstants.listingPackages.entries.map((e) => _packageTile(
              e.key, 'UGX ${_fmt(e.value)}', _getPackageDesc(e.key))),
          const SizedBox(height: 20),
          _sectionTitle('Payment Method'),
          const SizedBox(height: 14),
          ...[
            {'icon': '📱', 'label': 'MTN Mobile Money'},
            {'icon': '📲', 'label': 'Airtel Money'},
            {'icon': '💳', 'label': 'Visa / Mastercard'},
          ].map((m) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text(m['icon']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Text(m['label']!,
                        style: GoogleFonts.urbanist(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.radio_button_off_rounded,
                        color: AppColors.border),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _step < _steps.length - 1
          ? GradientButton(label: 'Continue', onTap: _next)
          : GradientButton(
              label: _submitting ? 'Processing...' : 'Pay & Submit Listing',
              onTap: _submitting ? null : _submit,
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.dark));

  Widget _selectable(String label, String selected, ValueChanged<String> onTap) {
    final active = selected == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _counter(int value, ValueChanged<int> onChange, {int min = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _counterBtn(Icons.remove_rounded,
              () => value > min ? onChange(value - 1) : null),
          SizedBox(
            width: 50,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          _counterBtn(Icons.add_rounded, () => onChange(value + 1)),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _packageTile(String label, String price, String desc) {
    final active = _selectedPackage == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: active ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: 1.5),
                color: active ? AppColors.primary : AppColors.white,
              ),
              child: active
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark)),
                  Text(desc,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(price,
                style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  String _getPackageDesc(String pkg) {
    switch (pkg) {
      case 'Basic Listing':
        return 'Standard listing, visible in search';
      case 'Premium Listing':
        return 'Highlighted listing, more visibility';
      case 'Featured Listing':
        return 'Top of search, homepage featured';
      default:
        return '';
    }
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(0)},000' : '$v';
}
