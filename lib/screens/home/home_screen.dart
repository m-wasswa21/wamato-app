import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/property/property_cubit.dart';
import '../../bloc/property/property_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import '../../widgets/property_card.dart';
import '../browse/category_screen.dart';
import '../browse/listings_screen.dart';
import '../map/map_screen.dart';
import '../notifications/notifications_screen.dart';
import '../property/property_detail_screen.dart';
import '../search/search_screen.dart';

// Pre-computed constants
const _kHeaderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.gradientStart, AppColors.primary, AppColors.secondary],
);

// Category definitions: (type key, display label, FA icon, image for CategoryScreen header)
const _kCategories = [
  ('House',      'Houses',       FontAwesomeIcons.house,          'assets/images/prop1.jpg'),
  ('Apartment',  'Apartments',   FontAwesomeIcons.building,       'assets/images/prop2.jpg'),
  ('Land',       'Land',         FontAwesomeIcons.mountain,       'assets/images/prop5.jpg'),
  ('Office',     'Offices',      FontAwesomeIcons.briefcase,      'assets/images/prop6.jpg'),
  ('Warehouse',  'Warehouses',   FontAwesomeIcons.warehouse,      'assets/images/prop6.jpg'),
  ('Commercial', 'Commercial',   FontAwesomeIcons.store,          'assets/images/prop3.jpg'),
  ('Airbnb',     'Short Stays',  FontAwesomeIcons.airbnb,         'assets/images/prop4.jpg'),
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

  @override
  void initState() {
    super.initState();
    // Trigger load if not already loaded
    final state = context.read<PropertyCubit>().state;
    if (state is! PropertyLoaded) {
      context.read<PropertyCubit>().loadHome();
    } else {
      _featured = state.featured;
      _stays = state.stays;
      _recent = state.recent;
    }
  }

  int _countByType(String type) =>
      _recent.where((p) => p.type == type).length +
      _featured.where((p) => p.type == type).length;

  int _countByStatus(String status) =>
      _recent.where((p) => p.statusLabel == status).length;

  void _openCategory(String type, String label, String image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          categoryType: type,
          categoryLabel: label,
          categoryImage: image,
        ),
      ),
    );
  }

  void _openListings({String? status, String? type, String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingsScreen(
          title: title ?? 'Properties',
          initialStatus: status,
          initialType: type,
        ),
      ),
    );
  }

  void _openDetail(Property p) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: p)));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PropertyCubit, PropertyState>(
      listener: (context, state) {
        if (state is PropertyLoaded) {
          setState(() {
            _featured = state.featured;
            _stays = state.stays;
            _recent = state.recent;
          });
        }
      },
      builder: (context, state) {
        if (state is PropertyLoading && _featured.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: _buildShimmer(),
          );
        }
        return _buildContent();
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 160),
          ...List.generate(
            4,
            (_) => Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ─────────────────────────────────────────
          _buildHeader(),

          // ── "Browse by Status" title ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Browse by Status', style: T.sectionTitle),
                  GestureDetector(
                    onTap: () => _openListings(title: 'All Properties'),
                    child: Text('See All', style: T.seeAll),
                  ),
                ],
              ),
            ),
          ),

          // ── Status cards (For Rent / For Sale / For Lease / Short Stays) ──
          SliverToBoxAdapter(child: _buildStatusRow()),

          // ── "Browse by Type" title ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Text('Browse by Type', style: T.sectionTitle),
            ),
          ),

          // ── Type icon grid — 3 columns, FA icons ───────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 82,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final c = _kCategories[i];
                  final count = _countByType(c.$1);
                  return GestureDetector(
                    onTap: () => _openCategory(c.$1, c.$2, c.$4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(14)),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.darkShadow,
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(c.$3,
                              size: 22,
                              color: AppColors.secondary),
                          const SizedBox(height: 6),
                          Text(c.$2,
                              textAlign: TextAlign.center,
                              style: T.typeInactive,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('$count',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _kCategories.length,
              ),
            ),
          ),

          // ── Short Stays button ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => _openListings(
                    type: 'Airbnb',
                    title: 'Short Stays & Airbnb'),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.error,
                        Color(0xFFFF6B6B)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius:
                        const BorderRadius.all(Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.error.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.airbnb,
                          color: AppColors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Short Stays & Airbnb',
                          style: GoogleFonts.urbanist(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius:
                              const BorderRadius.all(
                                  Radius.circular(20)),
                        ),
                        child: Text('${_stays.length}',
                            style: GoogleFonts.urbanist(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Featured section ────────────────────────────────────────
          if (_featured.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: 6),
                        Text('Featured Properties',
                            style: T.sectionTitle),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _openListings(
                          title: 'Featured Properties'),
                      child: Text('See All', style: T.seeAll),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: SizedBox(
                  height: 365,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _featured.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 16),
                    itemBuilder: (_, i) => SizedBox(
                      width: 268,
                      child: RepaintBoundary(
                        child: PropertyCard(
                          property: _featured[i],
                          onTap: () => _openDetail(_featured[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── Recent listings title ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Listings', style: T.sectionTitle),
                  GestureDetector(
                    onTap: () => _openListings(
                        title: 'Recent Listings'),
                    child: Text('See All', style: T.seeAll),
                  ),
                ],
              ),
            ),
          ),

          // ── Recent grid (SliverGrid) ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                mainAxisExtent: 228,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => RepaintBoundary(
                  child: PropertyCardGrid(
                    property: _recent[i],
                    onTap: () => _openDetail(_recent[i]),
                  ),
                ),
                childCount: _recent.length > 6 ? 6 : _recent.length,
              ),
            ),
          ),

          // ── View all button ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: OutlinedButton(
                onPressed: () =>
                    _openListings(title: 'All Properties'),
                child: Text('View All Properties',
                    style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  } // end _buildContent

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 175,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration:
              const BoxDecoration(gradient: _kHeaderGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                            ),
                            child: Image.asset(
                                'assets/images/logo.png',
                                height: 28,
                                fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Good day!',
                                  style: T.headerGoodDay),
                              Text('Find Your Property',
                                  style: T.headerTitle),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen())),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.whiteFaint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons
                                      .notifications_none_rounded,
                                  color: AppColors.white,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.whiteFaint,
                            child: Icon(Icons.person_rounded,
                                color: AppColors.white, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const SearchScreen())),
                    child: Container(
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.all(
                            Radius.circular(14)),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x1A020617),
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 22),
                          const SizedBox(width: 10),
                          Text(
                              'Search location, property type…',
                              style: T.searchHint),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const MapScreen())),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                              ),
                              child: const Icon(
                                  Icons.map_rounded,
                                  color: AppColors.white,
                                  size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Status cards row ──────────────────────────────────────────────────────────
  Widget _buildStatusRow() {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _StatusCard(
            label: 'For Rent',
            icon: Icons.vpn_key_rounded,
            color: AppColors.secondary,
            count: _countByStatus('For Rent'),
            image: 'assets/images/prop7.jpg',
            onTap: () =>
                _openListings(status: 'For Rent', title: 'For Rent'),
          ),
          const SizedBox(width: 12),
          _StatusCard(
            label: 'For Sale',
            icon: Icons.home_rounded,
            color: AppColors.primary,
            count: _countByStatus('For Sale'),
            image: 'assets/images/prop8.jpg',
            onTap: () =>
                _openListings(status: 'For Sale', title: 'For Sale'),
          ),
          const SizedBox(width: 12),
          _StatusCard(
            label: 'For Lease',
            icon: Icons.business_rounded,
            color: AppColors.success,
            count: _countByStatus('For Lease'),
            image: 'assets/images/prop6.jpg',
            onTap: () =>
                _openListings(status: 'For Lease', title: 'For Lease'),
          ),
          const SizedBox(width: 12),
          _StatusCard(
            label: 'Map View',
            icon: Icons.map_rounded,
            color: AppColors.warning,
            count: _recent.where((p) => p.latitude != null).length +
                _featured.where((p) => p.latitude != null).length,
            image: 'assets/images/prop4.jpg',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MapScreen())),
          ),
        ],
      ),
    );
  }
}

// ── Status card widget ────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final String image;
  final VoidCallback onTap;

  const _StatusCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.all(Radius.circular(16)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: color.withOpacity(0.2))),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          color: AppColors.white, size: 16),
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        Text('$count props',
                            style: const TextStyle(
                                color: AppColors.whiteMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
