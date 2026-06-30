import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/property/property_cubit.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import '../../widgets/filter_chip_button.dart';
import '../../widgets/property_card.dart';
import '../map/map_screen.dart';
import '../property/property_detail_screen.dart';

class ListingsScreen extends StatefulWidget {
  final String title;
  final String? initialType;
  final String? initialStatus;
  // Optional subtype filter passed from CategoryScreen
  final bool Function(Property)? subtypeFilter;

  const ListingsScreen({
    super.key,
    required this.title,
    this.initialType,
    this.initialStatus,
    this.subtypeFilter,
  });

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final _searchCtrl = TextEditingController();

  // ── Filter state ─────────────────────────────────────────────────────────────
  late String? _type;
  late String? _status; // 'For Rent' | 'For Sale' | 'For Lease' | null=All
  String? _district;
  int? _minBedrooms;
  double _priceMin = 0;
  double _priceMax = 1500000000;
  bool _verifiedOnly = false;
  String _sortBy = 'Newest';
  bool _gridView = false;
  bool _isLoading = true;

  List<Property> _allProperties = [];
  List<Property> _results = [];

  static const _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Verified First',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _status = widget.initialStatus;
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    setState(() => _isLoading = true);
    try {
      final cubit = context.read<PropertyCubit>();
      final data = await cubit.fetchByFilter(
        type: _type != null ? _apiType(_type!) : null,
        status: _status != null ? _apiStatus(_status!) : null,
        isShortStay: (_type == 'Airbnb' || _type == 'Holiday Apt') ? true : null,
      );
      if (mounted) {
        setState(() {
          _allProperties = data.isNotEmpty ? data : sampleProperties;
          _isLoading = false;
        });
        _filter();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allProperties = sampleProperties;
          _isLoading = false;
        });
        _filter();
      }
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering & sorting ───────────────────────────────────────────────────────
  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    var list = _allProperties.where((p) {
      // subtype filter from CategoryScreen — check first so it can
      // explicitly include short-stay results via its own predicate.
      if (widget.subtypeFilter != null) {
        if (!widget.subtypeFilter!(p)) return false;
      } else {
        // Without a subtype filter, hide short stays unless browsing by type.
        if (p.isShortStay &&
            _type != 'Airbnb' &&
            _type != 'Holiday Apt') return false;
      }

      final matchQ = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.area.toLowerCase().contains(q) ||
          p.district.toLowerCase().contains(q);
      final matchType = _type == null || p.type == _type;
      final matchStatus =
          _status == null || p.statusLabel == _status;
      final matchDistrict =
          _district == null || p.district == _district;
      final matchPrice =
          p.price >= _priceMin && p.price <= _priceMax;
      final matchBeds = _minBedrooms == null ||
          (p.bedrooms != null && p.bedrooms! >= _minBedrooms!);
      final matchVerified = !_verifiedOnly || p.isVerified;
      return matchQ &&
          matchType &&
          matchStatus &&
          matchDistrict &&
          matchPrice &&
          matchBeds &&
          matchVerified;
    }).toList();

    _applySort(list);
    setState(() => _results = list);
  }

  void _applySort(List<Property> list) {
    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Verified First':
        list.sort((a, b) =>
            (b.isVerified ? 1 : 0)
                .compareTo(a.isVerified ? 1 : 0));
        break;
      default: // Newest
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  // ── Active filter count (for "More" badge) ────────────────────────────────────
  int get _activeFilterCount {
    int n = 0;
    if (_verifiedOnly) n++;
    if (_priceMin > 0 || _priceMax < 1500000000) n++;
    return n;
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────────
  void _showSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SortSheet(
        current: _sortBy,
        options: _sortOptions,
        onSelect: (opt) {
          setState(() => _sortBy = opt);
          _filter();
        },
      ),
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ListPickerSheet(
        title: 'Location',
        items: ['All Districts', ...AppConstants.districts],
        selected: _district ?? 'All Districts',
        onSelect: (v) {
          setState(
              () => _district = v == 'All Districts' ? null : v);
          _filter();
        },
      ),
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PriceSheet(
        priceMin: _priceMin,
        priceMax: _priceMax,
        onApply: (min, max) {
          setState(() {
            _priceMin = min;
            _priceMax = max;
          });
          _filter();
        },
      ),
    );
  }

  void _showBedroomsFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BedroomsSheet(
        current: _minBedrooms,
        onSelect: (v) {
          setState(() => _minBedrooms = v);
          _filter();
        },
      ),
    );
  }

  void _showMoreFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Text('More Filters',
                  style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark)),
              const SizedBox(height: 20),
              _toggleRow(
                ctx,
                ss,
                'Verified Properties Only',
                Icons.verified_rounded,
                AppColors.success,
                _verifiedOnly,
                (v) => _verifiedOnly = v,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _filter();
                    Navigator.pop(ctx);
                  },
                  child: Text('Apply Filters',
                      style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(
    BuildContext ctx,
    StateSetter ss,
    String label,
    IconData icon,
    Color color,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius:
                const BorderRadius.all(Radius.circular(10)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
        ),
        Switch(
          value: value,
          onChanged: (v) {
            ss(() => onChanged(v));
            setState(() => onChanged(v));
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  // ── Status chip label for filter bar ─────────────────────────────────────────
  String? get _statusLabel => _status;
  String? get _districtLabel => _district;
  String? get _bedsLabel =>
      _minBedrooms != null ? '$_minBedrooms+ Beds' : null;
  String? get _moreLabel =>
      _activeFilterCount > 0 ? 'More ($_activeFilterCount)' : null;

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          _buildStatusChips(),
          _buildFilterBar(),
          _buildCountBar(),
        ],
        body: _isLoading
            ? _buildShimmer()
            : _results.isEmpty
                ? _buildEmpty()
                : _gridView
                    ? _buildGrid()
                    : _buildList(),
      ),
    );
  }

  // ── App bar with embedded search ──────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF222222),
                      size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _filter(),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF222222)),
                    decoration: InputDecoration(
                      hintText: 'Search in ${widget.title}…',
                      hintStyle: GoogleFonts.urbanist(
                          color: const Color(0xFF999999),
                          fontSize: 13),
                      prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF999999),
                          size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                _filter();
                              },
                              child: const Icon(
                                  Icons.clear_rounded,
                                  size: 16,
                                  color: Color(0xFF999999)),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 13),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MapScreen()),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: Color(0xFF222222), size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status chips (All / For Rent / For Sale / For Lease) ─────────────────────
  SliverPersistentHeader _buildStatusChips() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedDelegate(
        height: 48,
        child: ColoredBox(
          color: AppColors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              _statusChip(null, 'All'),
              _statusChip('For Rent', 'For Rent'),
              _statusChip('For Sale', 'For Sale'),
              _statusChip('For Lease', 'For Lease'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String? value, String label) {
    final active = _status == value;
    return GestureDetector(
      onTap: () {
        setState(() => _status = value);
        _filter();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? const Color(0xFF222222)
                        : const Color(0xFF717171))),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: active ? 24 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips row ──────────────────────────────────────────────────────────
  SliverPersistentHeader _buildFilterBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedDelegate(
        height: 50,
        child: Container(
          color: AppColors.white,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: [
                    FilterChipButton(
                      label: 'Location',
                      activeValue: _districtLabel,
                      onTap: _showLocationFilter,
                    ),
                    FilterChipButton(
                      label: 'Price',
                      activeValue: (_priceMin > 0 ||
                              _priceMax < 1500000000)
                          ? 'Price ✓'
                          : null,
                      onTap: _showPriceFilter,
                    ),
                    FilterChipButton(
                      label: 'Bedrooms',
                      activeValue: _bedsLabel,
                      onTap: _showBedroomsFilter,
                    ),
                    FilterChipButton(
                      label: 'More',
                      activeValue: _moreLabel,
                      onTap: _showMoreFilter,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                  height: 1,
                  child: ColoredBox(color: AppColors.border)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Count + Sort + Grid toggle ────────────────────────────────────────────────
  SliverPersistentHeader _buildCountBar() {
    return SliverPersistentHeader(
      pinned: false,
      delegate: _PinnedDelegate(
        height: 46,
        child: Container(
          color: AppColors.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Found ',
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: '${_results.length}',
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark),
                    ),
                    TextSpan(
                      text: ' properties',
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showSort,
                child: Row(
                  children: [
                    const Icon(Icons.sort_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 4),
                    Text(_sortBy,
                        style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary)),
                    const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.secondary,
                        size: 16),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () =>
                    setState(() => _gridView = !_gridView),
                child: Icon(
                  _gridView
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        mainAxisExtent: 228,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _results.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        mainAxisExtent: 228,
      ),
      itemBuilder: (_, i) => RepaintBoundary(
        child: PropertyCardGrid(
          property: _results[i],
          onTap: () => _openDetail(_results[i]),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => RepaintBoundary(
        child: PropertyCard(
          property: _results[i],
          onTap: () => _openDetail(_results[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.accent, size: 64),
          const SizedBox(height: 16),
          Text('No Properties Found',
              style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters',
              style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() {
                _status = widget.initialStatus;
                _district = null;
                _minBedrooms = null;
                _priceMin = 0;
                _priceMax = 1500000000;
                _verifiedOnly = false;
                _searchCtrl.clear();
              });
              _filter();
            },
            child: Text('Clear All Filters',
                style: GoogleFonts.urbanist(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openDetail(Property p) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: p)));
}

// ── Pinned header delegate ─────────────────────────────────────────────────────
class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  const _PinnedDelegate({required this.height, required this.child});

  @override
  Widget build(
          BuildContext _, double shrinkOffset, bool overlapsContent) =>
      child;
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_PinnedDelegate old) => false;
}

// ── Sort sheet ─────────────────────────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  final String current;
  final List<String> options;
  final void Function(String) onSelect;

  const _SortSheet(
      {required this.current,
      required this.options,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Sort By',
              style: GoogleFonts.urbanist(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...options.map((opt) => GestureDetector(
                onTap: () {
                  onSelect(opt);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: AppColors.border))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(opt,
                            style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: current == opt
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: current == opt
                                    ? AppColors.primary
                                    : AppColors.dark)),
                      ),
                      if (current == opt)
                        const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Location picker sheet ─────────────────────────────────────────────────────
class _ListPickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selected;
  final void Function(String) onSelect;

  const _ListPickerSheet(
      {required this.title,
      required this.items,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.urbanist(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: ctrl,
                children: items
                    .map((item) => GestureDetector(
                          onTap: () {
                            onSelect(item);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.border))),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: selected == item
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                    size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(item,
                                      style: GoogleFonts.urbanist(
                                          fontSize: 14,
                                          fontWeight:
                                              selected == item
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                          color: selected == item
                                              ? AppColors.primary
                                              : AppColors.dark)),
                                ),
                                if (selected == item)
                                  const Icon(Icons.check_rounded,
                                      color: AppColors.primary,
                                      size: 18),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price range sheet ─────────────────────────────────────────────────────────
class _PriceSheet extends StatefulWidget {
  final double priceMin;
  final double priceMax;
  final void Function(double, double) onApply;
  const _PriceSheet(
      {required this.priceMin,
      required this.priceMax,
      required this.onApply});

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late double _min;
  late double _max;
  static const double _absMax = 1500000000;

  @override
  void initState() {
    super.initState();
    _min = widget.priceMin;
    _max = widget.priceMax;
  }

  String _fmt(double v) {
    if (v >= 1000000000)
      return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text('Price Range (UGX)',
              style: GoogleFonts.urbanist(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UGX ${_fmt(_min)}',
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              Text('UGX ${_fmt(_max)}',
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          RangeSlider(
            values: RangeValues(_min, _max),
            min: 0,
            max: _absMax,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (v) =>
                setState(() {
                  _min = v.start;
                  _max = v.end;
                }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_min, _max);
                Navigator.pop(context);
              },
              child: Text('Apply Price Filter',
                  style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bedrooms sheet ─────────────────────────────────────────────────────────────
class _BedroomsSheet extends StatelessWidget {
  final int? current;
  final void Function(int?) onSelect;
  const _BedroomsSheet(
      {required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = [null, 1, 2, 3, 4, 5];
    final labels = ['Any', '1+', '2+', '3+', '4+', '5+'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text('Bedrooms',
              style: GoogleFonts.urbanist(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(opts.length, (i) {
              final active = current == opts[i];
              return GestureDetector(
                onTap: () {
                  onSelect(opts[i]);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.white,
                    borderRadius:
                        const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.border),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.white
                              : AppColors.dark)),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
