import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/property/property_cubit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/property.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  String? _filterType;
  String? _filterStatus;
  String? _filterDistrict;
  RangeValues _priceRange = const RangeValues(0, 700000000);
  List<Property> _allProperties = [];
  List<Property> _results = [];
  String _sortBy = 'Newest';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadFromBackend() async {
    setState(() => _isLoading = true);
    try {
      final cubit = context.read<PropertyCubit>();
      final data = await cubit.fetchByFilter();
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

  void _filter() {
    setState(() {
      _results = _allProperties.where((p) {
        final q = _query.text.toLowerCase();
        final matchQ = q.isEmpty ||
            p.title.toLowerCase().contains(q) ||
            p.area.toLowerCase().contains(q) ||
            p.district.toLowerCase().contains(q);
        final matchType = _filterType == null || p.type == _filterType;
        final matchStatus =
            _filterStatus == null || p.statusLabel == _filterStatus;
        final matchDistrict =
            _filterDistrict == null || p.district == _filterDistrict;
        final matchPrice =
            p.price >= _priceRange.start && p.price <= _priceRange.end;
        return matchQ && matchType && matchStatus && matchDistrict && matchPrice;
      }).toList();
      _applySort();
    });
  }

  void _applySort() {
    switch (_sortBy) {
      case 'Price: Low to High':
        _results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        _results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        _results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Verified First':
        _results.sort((a, b) =>
            (b.isVerified ? 1 : 0).compareTo(a.isVerified ? 1 : 0));
        break;
    }
  }

  void _showSort() {
    final options = [
      'Newest',
      'Price: Low to High',
      'Price: High to Low',
      'Verified First',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
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
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Sort By',
                style: GoogleFonts.urbanist(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ...options.map((opt) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _sortBy = opt;
                      _applySort();
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.border))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(opt,
                              style: GoogleFonts.urbanist(
                                  fontSize: 15,
                                  fontWeight: _sortBy == opt
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _sortBy == opt
                                      ? AppColors.primary
                                      : AppColors.dark)),
                        ),
                        if (_sortBy == opt)
                          const Icon(Icons.check_rounded,
                              color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Search Properties',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _query,
              onChanged: (_) => _filter(),
              decoration: InputDecoration(
                hintText: 'Search area, property type...',
                hintStyle: GoogleFonts.urbanist(
                    color: AppColors.textTertiary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textTertiary, size: 22),
                suffixIcon: _query.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _query.clear();
                          _filter();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.secondary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_filterType != null ||
              _filterStatus != null ||
              _filterDistrict != null)
            _buildActiveFilters(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoading ? 'Loading...' : '${_results.length} Properties Found',
                  style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark),
                ),
                GestureDetector(
                  onTap: _showSort,
                  child: Row(
                    children: [
                      const Icon(Icons.sort_rounded,
                          color: AppColors.secondary, size: 18),
                      const SizedBox(width: 4),
                      Text(_sortBy,
                          style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _results.isEmpty
                    ? _buildEmpty()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _results.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 228,
                        ),
                        itemBuilder: (_, i) => PropertyCardGrid(
                          property: _results[i],
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PropertyDetailScreen(property: _results[i]))),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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

  Widget _buildActiveFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        scrollDirection: Axis.horizontal,
        children: [
          if (_filterType != null)
            _filterChip(_filterType!, () => setState(() {
                  _filterType = null;
                  _filter();
                })),
          if (_filterStatus != null)
            _filterChip(_filterStatus!, () => setState(() {
                  _filterStatus = null;
                  _filter();
                })),
          if (_filterDistrict != null)
            _filterChip(_filterDistrict!, () => setState(() {
                  _filterDistrict = null;
                  _filter();
                })),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                color: AppColors.primary, size: 14),
          ),
        ],
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
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Filter Properties',
                  style: GoogleFonts.urbanist(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Text('Property Type',
                  style: GoogleFonts.urbanist(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.propertyTypes.map((t) {
                  final active = _filterType == t;
                  return GestureDetector(
                    onTap: () => ss(() => _filterType = active ? null : t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: active ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(t,
                          style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? AppColors.white
                                  : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Status',
                  style: GoogleFonts.urbanist(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: ['For Rent', 'For Sale', 'For Lease'].map((s) {
                  final active = _filterStatus == s;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          ss(() => _filterStatus = active ? null : s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  active ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(s,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.white
                                    : AppColors.textSecondary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    _filter();
                    Navigator.pop(ctx);
                  },
                  child: Text('Apply Filters',
                      style: GoogleFonts.urbanist(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
