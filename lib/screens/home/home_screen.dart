import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/property/property_cubit.dart';
import '../../bloc/property/property_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import '../../widgets/property_card.dart';
import '../browse/listings_screen.dart';
import '../map/map_screen.dart';
import '../notifications/notifications_screen.dart';
import '../property/property_detail_screen.dart';
import '../search/search_screen.dart';

// ── Category chips (key, label, icon) ────────────────────────────────────────
const _kCats = [
  ('All',         'All',          Icons.apps_rounded),
  ('House',       'Houses',       Icons.house_rounded),
  ('Apartment',   'Apartments',   Icons.apartment_rounded),
  ('Land',        'Land',         Icons.landscape_rounded),
  ('Office',      'Offices',      Icons.business_center_rounded),
  ('Warehouse',   'Warehouses',   Icons.warehouse_rounded),
  ('Commercial',  'Commercial',   Icons.store_rounded),
  ('Airbnb',      'Short Stays',  Icons.cabin_rounded),
  ('Holiday Apt', 'Holiday',      Icons.beach_access_rounded),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _featured = [];
  List<Property> _stays = [];
  List<Property> _recent = [];
  String _selectedCat = 'All';

  @override
  void initState() {
    super.initState();
    final state = context.read<PropertyCubit>().state;
    if (state is! PropertyLoaded) {
      context.read<PropertyCubit>().loadHome();
    } else {
      _featured = state.featured;
      _stays = state.stays;
      _recent = state.recent;
    }
  }

  // Deduplicated full list: featured first, then recent
  List<Property> get _allProperties => [
        ..._featured,
        ..._recent.where((p) => !_featured.any((f) => f.id == p.id)),
      ];

  List<Property> get _filteredProperties {
    if (_selectedCat == 'All') return _allProperties;
    return _allProperties.where((p) => p.type == _selectedCat).toList();
  }

  void _openDetail(Property p) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));

  void _openListings({String? type, String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingsScreen(
          title: title ?? 'Properties',
          initialType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PropertyCubit, PropertyState>(
      listener: (_, state) {
        if (state is PropertyLoaded) {
          setState(() {
            _featured = state.featured;
            _stays = state.stays;
            _recent = state.recent;
          });
        }
      },
      builder: (_, state) {
        final loading = state is PropertyLoading && _featured.isEmpty;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: loading ? _buildShimmer() : _buildFeed(),
          ),
        );
      },
    );
  }

  // ── Shimmer loading ───────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF8F8F8),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 170, 20, 20),
        children: List.generate(
          4,
          (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 15, width: 220, color: Colors.white),
              const SizedBox(height: 6),
              Container(height: 13, width: 150, color: Colors.white),
              const SizedBox(height: 6),
              Container(height: 15, width: 120, color: Colors.white),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main feed ─────────────────────────────────────────────────────────────
  Widget _buildFeed() {
    final filtered = _filteredProperties;
    final showStays = _selectedCat == 'All' && _stays.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // ── Pinned white header ─────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          pinned: true,
          floating: false,
          toolbarHeight: 52,
          expandedHeight: 52 + 110,
          title: _buildLogoRow(),
          titleSpacing: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: _buildSearchAndChips(),
          ),
        ),

        // ── Short stays horizontal row ──────────────────────────────────────
        if (showStays) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: _sectionHeader(
                'Short Stays & Holiday',
                onSeeAll: () => _openListings(
                    type: 'Airbnb', title: 'Short Stays & Holiday'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 256,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _stays.length > 6 ? 6 : _stays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => SizedBox(
                  width: 196,
                  child: PropertyCardGrid(
                    property: _stays[i],
                    onTap: () => _openDetail(_stays[i]),
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── Section title ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, showStays ? 28 : 24, 20, 14),
            child: _sectionHeader(
              _selectedCat == 'All'
                  ? 'Explore all properties'
                  : _kCats
                      .firstWhere(
                        (c) => c.$1 == _selectedCat,
                        orElse: () => ('', 'Properties', Icons.home_rounded),
                      )
                      .$2,
              onSeeAll: () => _openListings(
                type: _selectedCat == 'All' ? null : _selectedCat,
                title: 'All Properties',
              ),
            ),
          ),
        ),

        // ── Property cards list ─────────────────────────────────────────────
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 52, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 14),
                  Text(
                    'No properties in this category yet',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final p = filtered[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: RepaintBoundary(
                    child: PropertyCard(
                      property: p,
                      onTap: () => _openDetail(p),
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ── Logo row (top, collapses on scroll) ──────────────────────────────────
  Widget _buildLogoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png',
              height: 30, fit: BoxFit.contain),
          const SizedBox(width: 8),
          const Text(
            'Wamato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          _HeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(width: 10),
          _HeaderIcon(
            icon: Icons.map_outlined,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen())),
          ),
        ],
      ),
    );
  }

  // ── Search bar + category chips (always pinned) ───────────────────────────
  Widget _buildSearchAndChips() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Airbnb-style pill search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search_rounded,
                        size: 22, color: Color(0xFF222222)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Where in Uganda?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222)),
                          ),
                          Text(
                            'Any type  ·  Any price',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF717171)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          size: 16, color: Color(0xFF222222)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category chips — Airbnb style: icon above label, underline when active
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 8),
              itemCount: _kCats.length,
              itemBuilder: (_, i) {
                final cat = _kCats[i];
                final active = _selectedCat == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCat = cat.$1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat.$3,
                          size: 20,
                          color: active
                              ? const Color(0xFF222222)
                              : const Color(0xFFAAAAAA),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cat.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active
                                ? const Color(0xFF222222)
                                : const Color(0xFF717171),
                          ),
                        ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF717171),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF717171),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small circular icon button for header ────────────────────────────────────
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF222222)),
      ),
    );
  }
}
