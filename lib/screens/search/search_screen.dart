import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/property/property_cubit.dart';
import '../../core/services/property_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

const _kAreas = [
  'Kampala', 'Wakiso', 'Jinja', 'Entebbe', 'Mbarara',
  'Gulu', 'Mukono', 'Masaka', 'Mbale', 'Arua',
];

const _kTypes = [
  ('House',       'Houses',       Icons.house_rounded),
  ('Apartment',   'Apartments',   Icons.apartment_rounded),
  ('Land',        'Land',         Icons.landscape_rounded),
  ('Office',      'Offices',      Icons.business_center_rounded),
  ('Commercial',  'Commercial',   Icons.store_rounded),
  ('Airbnb',      'Short Stays',  Icons.cabin_rounded),
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _filterType;
  String? _filterStatus;
  String? _filterDistrict;
  List<Property> _allProperties = [];
  List<Property> _results = [];
  String _sortBy = 'Newest';
  bool _isLoading = true;
  Timer? _debounce;

  bool get _hasSearch =>
      _ctrl.text.isNotEmpty ||
      _filterType != null ||
      _filterStatus != null ||
      _filterDistrict != null;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadFromBackend() async {
    setState(() => _isLoading = true);
    try {
      final data = await context.read<PropertyCubit>().fetchByFilter();
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

  // Debounced text search — hits /api/v1/search after 400 ms of no typing
  void _onTextChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _filter();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final data = await const PropertyRepository().search(query.trim());
        if (!mounted) return;
        setState(() {
          _allProperties = data.isNotEmpty ? data : sampleProperties;
          _isLoading = false;
        });
        _filter();
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _filter();
      }
    });
  }

  void _filter() {
    setState(() {
      _results = _allProperties.where((p) {
        final q = _ctrl.text.toLowerCase();
        final matchQ = q.isEmpty ||
            p.title.toLowerCase().contains(q) ||
            p.area.toLowerCase().contains(q) ||
            p.district.toLowerCase().contains(q) ||
            p.type.toLowerCase().contains(q);
        final matchType = _filterType == null || p.type == _filterType;
        final matchStatus =
            _filterStatus == null || p.statusLabel == _filterStatus;
        final matchDistrict =
            _filterDistrict == null || p.district == _filterDistrict;
        return matchQ && matchType && matchStatus && matchDistrict;
      }).toList();
      _applySort();
    });
  }

  void _applySort() {
    switch (_sortBy) {
      case 'Price: Low to High':
        _results.sort((a, b) => a.price.compareTo(b.price));
      case 'Price: High to Low':
        _results.sort((a, b) => b.price.compareTo(a.price));
      case 'Newest':
        _results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'Verified First':
        _results.sort((a, b) =>
            (b.isVerified ? 1 : 0).compareTo(a.isVerified ? 1 : 0));
    }
  }

  int get _activeFilterCount {
    int n = 0;
    if (_filterType != null) n++;
    if (_filterStatus != null) n++;
    if (_filterDistrict != null) n++;
    return n;
  }

  void _clearAll() {
    _debounce?.cancel();
    setState(() {
      _ctrl.clear();
      _filterType = null;
      _filterStatus = null;
      _filterDistrict = null;
      _results = [];
    });
    _loadFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Search bar ────────────────────────────────────────────
              _buildSearchBar(),

              // ── Active filter chips ───────────────────────────────────
              if (_activeFilterCount > 0) _buildActiveChips(),

              const Divider(height: 1, thickness: 0.8, color: Color(0xFFEBEBEB)),

              // ── Body ──────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? _buildShimmer()
                    : _hasSearch
                        ? _buildResults()
                        : _buildSuggestions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back_rounded,
                  size: 24, color: Color(0xFF222222)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: _onTextChanged,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search area, type, district...',
                  hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w400),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF999999), size: 20),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded,
                              size: 18, color: Color(0xFF999999)),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _filterDistrict = null);
                            _onTextChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilters,
            child: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _activeFilterCount > 0
                            ? AppColors.primary
                            : const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(12),
                    color: _activeFilterCount > 0
                        ? AppColors.primaryFaint
                        : Colors.white,
                  ),
                  child: Icon(Icons.tune_rounded,
                      size: 20,
                      color: _activeFilterCount > 0
                          ? AppColors.primary
                          : const Color(0xFF222222)),
                ),
                if (_activeFilterCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$_activeFilterCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Active filter chips ───────────────────────────────────────────────────
  Widget _buildActiveChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
        children: [
          if (_filterType != null)
            _chip(_filterType!, () => setState(() {
                  _filterType = null;
                  _filter();
                })),
          if (_filterStatus != null)
            _chip(_filterStatus!, () => setState(() {
                  _filterStatus = null;
                  _filter();
                })),
          if (_filterDistrict != null)
            _chip(_filterDistrict!, () {
              setState(() {
                _filterDistrict = null;
                _ctrl.clear();
              });
              _filter();
            }),
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Clear all',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF717171))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  // ── Suggestions (no search yet) ───────────────────────────────────────────
  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        // Popular areas
        const Text('Popular Areas',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _kAreas
              .map((area) => GestureDetector(
                    onTap: () async {
                      _debounce?.cancel();
                      _ctrl.text = area;
                      setState(() { _filterDistrict = area; _isLoading = true; });
                      _focus.unfocus();
                      try {
                        final data = await context
                            .read<PropertyCubit>()
                            .fetchByFilter(district: area);
                        if (!mounted) return;
                        setState(() {
                          _allProperties =
                              data.isNotEmpty ? data : sampleProperties;
                          _isLoading = false;
                        });
                        _filter();
                      } catch (_) {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 13, color: Color(0xFF717171)),
                          const SizedBox(width: 5),
                          Text(area,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF222222))),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 32),

        // Browse by type
        const Text('Browse by Type',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: _kTypes.map((t) {
            final active = _filterType == t.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _filterType = active ? null : t.$1);
                _filter();
                _focus.unfocus();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$3,
                        size: 24,
                        color: active ? Colors.white : const Color(0xFF717171)),
                    const SizedBox(height: 6),
                    Text(t.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : const Color(0xFF222222))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Quick status
        const Text('Quick Browse',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
        const SizedBox(height: 14),
        Row(
          children: [
            _quickStatus('For Rent', Icons.vpn_key_rounded, AppColors.secondary),
            const SizedBox(width: 10),
            _quickStatus('For Sale', Icons.home_rounded, AppColors.primary),
            const SizedBox(width: 10),
            _quickStatus('For Lease', Icons.business_rounded, AppColors.success),
          ],
        ),
      ],
    );
  }

  Widget _quickStatus(String status, IconData icon, Color color) {
    final active = _filterStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filterStatus = active ? null : status);
          _filter();
          _focus.unfocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: active ? Colors.white : color),
              const SizedBox(height: 6),
              Text(status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : const Color(0xFF222222))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search results ────────────────────────────────────────────────────────
  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text('No properties found',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222))),
            const SizedBox(height: 8),
            Text('Try different keywords or filters',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _clearAll,
              child: const Text('Clear filters',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_results.length} ${_results.length == 1 ? "property" : "properties"}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222)),
              ),
              GestureDetector(
                onTap: _showSort,
                child: Row(
                  children: [
                    const Icon(Icons.sort_rounded,
                        size: 16, color: Color(0xFF717171)),
                    const SizedBox(width: 4),
                    Text(_sortBy,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF717171),
                            fontWeight: FontWeight.w500)),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: Color(0xFF717171)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: _results.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: PropertyCard(
                property: _results[i],
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PropertyDetailScreen(property: _results[i]))),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: List.generate(
        3,
        (_) => Shimmer.fromColors(
          baseColor: const Color(0xFFEEEEEE),
          highlightColor: const Color(0xFFF8F8F8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
              ),
              const SizedBox(height: 10),
              Container(height: 15, width: 200, color: Colors.white),
              const SizedBox(height: 6),
              Container(height: 13, width: 140, color: Colors.white),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────────────────
  void _showSort() {
    const options = [
      'Newest',
      'Price: Low to High',
      'Price: High to Low',
      'Verified First',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEBEBEB),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Sort by',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF222222))),
            const SizedBox(height: 12),
            ...options.map((opt) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _sortBy = opt;
                      _applySort();
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFEBEBEB)))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(opt,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _sortBy == opt
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: _sortBy == opt
                                      ? AppColors.primary
                                      : const Color(0xFF222222))),
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

  // ── Filter bottom sheet ───────────────────────────────────────────────────
  void _showFilters() {
    String? tmpType = _filterType;
    String? tmpStatus = _filterStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFEBEBEB),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF222222))),
                  GestureDetector(
                    onTap: () => ss(() {
                      tmpType = null;
                      tmpStatus = null;
                    }),
                    child: const Text('Clear all',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Property type
              const Text('Property Type',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _kTypes.map((t) {
                  final active = tmpType == t.$1;
                  return GestureDetector(
                    onTap: () =>
                        ss(() => tmpType = active ? null : t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.$3,
                              size: 14,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF717171)),
                          const SizedBox(width: 5),
                          Text(t.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF222222))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEBEBEB)),
              const SizedBox(height: 20),

              // Status
              const Text('Listing Status',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222))),
              const SizedBox(height: 12),
              Row(
                children: ['For Rent', 'For Sale', 'For Lease'].map((s) {
                  final active = tmpStatus == s;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            ss(() => tmpStatus = active ? null : s),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(s,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF222222))),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterType = tmpType;
                      _filterStatus = tmpStatus;
                    });
                    _filter();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Show properties',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
