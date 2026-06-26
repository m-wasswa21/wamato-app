import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import '../../bloc/property/property_cubit.dart';
import '../../bloc/property/property_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/property.dart';
import '../property/property_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final Property? focusProperty;
  const MapScreen({super.key, this.focusProperty});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  Property? _selected;
  String _filterStatus = 'All';

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  double? _routeDuration;
  bool _loadingRoute = false;
  bool _locationDenied = false;

  static const _center = LatLng(0.3136, 32.5811);

  @override
  void initState() {
    super.initState();
    _initLocation();
    if (widget.focusProperty != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectProperty(widget.focusProperty!);
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      final location = loc.Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (mounted) setState(() => _locationDenied = true);
          return;
        }
      }

      var perm = await location.hasPermission();
      if (perm == loc.PermissionStatus.denied) {
        perm = await location.requestPermission();
      }
      if (perm != loc.PermissionStatus.granted &&
          perm != loc.PermissionStatus.grantedLimited) {
        if (mounted) setState(() => _locationDenied = true);
        return;
      }

      final pos = await location.getLocation();
      if (mounted && pos.latitude != null && pos.longitude != null) {
        setState(
            () => _userLocation = LatLng(pos.latitude!, pos.longitude!));
        if (_selected != null) _fetchRoute(_selected!);
      }
    } catch (_) {
      if (mounted) setState(() => _locationDenied = true);
    }
  }

  Future<void> _fetchRoute(Property dest) async {
    if (_userLocation == null ||
        dest.latitude == null ||
        dest.longitude == null) return;
    if (mounted) {
      setState(() {
        _loadingRoute = true;
        _routePoints = [];
        _routeDistance = null;
        _routeDuration = null;
      });
    }
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation!.longitude},${_userLocation!.latitude};'
        '${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson';
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final route =
            (data['routes'] as List).first as Map<String, dynamic>;
        final coords =
            (route['geometry']['coordinates'] as List)
                .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble()))
                .toList();
        setState(() {
          _routePoints = coords;
          _routeDistance =
              (route['distance'] as num).toDouble();
          _routeDuration =
              (route['duration'] as num).toDouble();
          _loadingRoute = false;
        });
      } else {
        if (mounted) setState(() => _loadingRoute = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  String get _distanceLabel {
    if (_routeDistance == null) return '';
    final km = _routeDistance! / 1000;
    return km < 1
        ? '${_routeDistance!.toInt()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  String get _durationLabel {
    if (_routeDuration == null) return '';
    final mins = (_routeDuration! / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  List<Property> _allProperties(BuildContext context) {
    final state = context.read<PropertyCubit>().state;
    if (state is PropertyLoaded) {
      final seen = <String>{};
      return [...state.featured, ...state.stays, ...state.recent]
          .where((p) => seen.add(p.id))
          .toList();
    }
    return sampleProperties;
  }

  List<Property> _filtered(BuildContext context) {
    final withCoords =
        _allProperties(context).where((p) => p.latitude != null).toList();
    if (_filterStatus == 'All') return withCoords;
    return withCoords
        .where((p) => p.statusLabel == _filterStatus)
        .toList();
  }

  Color _markerColor(Property p) {
    if (p.isShortStay) return AppColors.error;
    if (p.listingPackage == ListingPackage.featured)
      return AppColors.warning;
    switch (p.status) {
      case PropertyStatus.forRent:
        return AppColors.secondary;
      case PropertyStatus.forSale:
        return AppColors.primary;
      case PropertyStatus.forLease:
        return AppColors.success;
    }
  }

  void _selectProperty(Property p) {
    setState(() {
      _selected = p;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });
    _mapController.move(
        LatLng(p.latitude! - 0.01, p.longitude!), 14.5);
    _fetchRoute(p);
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered(context);
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12.5,
              minZoom: 8,
              maxZoom: 18,
              onTap: (_, __) => _clearSelection(),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                fallbackUrl:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.wamato.app',
                maxZoom: 19,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: AppColors.primary.withOpacity(0.85),
                      borderStrokeWidth: 2,
                      borderColor:
                          AppColors.white.withOpacity(0.6),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: filtered.map((p) {
                  final isSelected = _selected?.id == p.id;
                  return Marker(
                    point: LatLng(p.latitude!, p.longitude!),
                    width: 130,
                    height: 56,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () => _selectProperty(p),
                      child: _PriceMarker(
                        label: p.priceLabel,
                        color: _markerColor(p),
                        isSelected: isSelected,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      child: _UserDot(),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 10),
                _buildFilterChips(),
              ],
            ),
          ),

          // Route pill
          if (_routeDistance != null && _routeDuration != null)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(child: _buildRoutePill()),
            ),

          // Loading
          if (_loadingRoute)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.dark.withOpacity(0.12),
                          blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('Calculating route…',
                          style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark)),
                    ],
                  ),
                ),
              ),
            ),

          // Controls
          Positioned(
            right: 16,
            bottom: _selected != null ? 300 : 120,
            child: Column(
              children: [
                _MapBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1),
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15);
                    } else {
                      _initLocation();
                    }
                  },
                  active: _userLocation != null,
                ),
              ],
            ),
          ),

          // Property count
          Positioned(
            left: 16,
            bottom: _selected != null ? 300 : 120,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.dark.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('${filtered.length} Properties',
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark)),
                ],
              ),
            ),
          ),

          // Legend
          if (_selected == null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildLegend(),
            ),

          // Property card
          if (_selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _PropertyCard(
                property: _selected!,
                distanceLabel: _distanceLabel,
                durationLabel: _durationLabel,
                loadingRoute: _loadingRoute,
                hasLocation: _userLocation != null,
                onClose: _clearSelection,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(
                          property: _selected!)),
                ),
              ),
            ),

          // GPS denied banner
          if (_locationDenied)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_rounded,
                        color: AppColors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Location access denied – directions unavailable',
                          style: GoogleFonts.urbanist(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoutePill() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_rounded,
              color: AppColors.white, size: 16),
          const SizedBox(width: 8),
          Text(_durationLabel,
              style: GoogleFonts.urbanist(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.white.withOpacity(0.4)),
          Text(_distanceLabel,
              style: GoogleFonts.urbanist(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.white.withOpacity(0.4)),
          Text('Driving',
              style: GoogleFonts.urbanist(
                  color: AppColors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.dark.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.dark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _selected != null
                          ? _selected!.title
                          : 'Properties in Uganda',
                      style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _userLocation != null
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _userLocation != null
                              ? 'GPS On'
                              : 'No GPS',
                          style: GoogleFonts.urbanist(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _userLocation != null
                                  ? AppColors.success
                                  : AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MapBtn(
              icon: Icons.list_rounded,
              onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'For Rent', 'For Sale', 'For Lease'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = _filterStatus == filters[i];
          return GestureDetector(
            onTap: () => setState(() {
              _filterStatus = filters[i];
              _clearSelection();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.dark.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text(
                  filters[i],
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.dark.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _dot(AppColors.secondary, 'Rent'),
          _dot(AppColors.primary, 'Sale'),
          _dot(AppColors.success, 'Lease'),
          _dot(AppColors.warning, 'Featured'),
          _dot(AppColors.error, 'Stay'),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.urbanist(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── GPS pulsing dot ────────────────────────────────────────────────────────────
class _UserDot extends StatefulWidget {
  @override
  State<_UserDot> createState() => _UserDotState();
}

class _UserDotState extends State<_UserDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  AppColors.secondary.withOpacity(_anim.value),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
              border: Border.all(
                  color: AppColors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color:
                        AppColors.secondary.withOpacity(0.5),
                    blurRadius: 6)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price bubble marker ────────────────────────────────────────────────────────
class _PriceMarker extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;

  const _PriceMarker(
      {required this.label,
      required this.color,
      required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: color, width: isSelected ? 0 : 2),
            boxShadow: [
              BoxShadow(
                color: color
                    .withOpacity(isSelected ? 0.4 : 0.2),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              color: isSelected ? AppColors.white : color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _MarkerTailPainter(color: color),
        ),
      ],
    );
  }
}

// ── Triangular marker tail ─────────────────────────────────────────────────────
class _MarkerTailPainter extends CustomPainter {
  final Color color;
  const _MarkerTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MarkerTailPainter old) => old.color != color;
}

// ── Round map button ───────────────────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _MapBtn(
      {required this.icon,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.dark.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon,
            color: active
                ? AppColors.white
                : AppColors.primary,
            size: 20),
      ),
    );
  }
}

// ── Bottom property + route card ───────────────────────────────────────────────
class _PropertyCard extends StatelessWidget {
  final Property property;
  final String distanceLabel;
  final String durationLabel;
  final bool loadingRoute;
  final bool hasLocation;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const _PropertyCard({
    required this.property,
    required this.distanceLabel,
    required this.durationLabel,
    required this.loadingRoute,
    required this.hasLocation,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x22020617),
              blurRadius: 20,
              offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: p.photos.isNotEmpty
                    ? (p.photos.first.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: p.photos.first,
                            width: 88,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                width: 88,
                                height: 80,
                                color: AppColors.accent.withOpacity(0.3)),
                            errorWidget: (_, __, ___) => Container(
                                width: 88,
                                height: 80,
                                color: AppColors.accent.withOpacity(0.3),
                                child: const Icon(Icons.home_rounded,
                                    color: AppColors.secondary, size: 32)))
                        : Image.asset(p.photos.first,
                            width: 88,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 88,
                                height: 80,
                                color: AppColors.accent.withOpacity(0.3),
                                child: const Icon(Icons.home_rounded,
                                    color: AppColors.secondary, size: 32))))
                    : Container(
                        width: 88,
                        height: 80,
                        color: AppColors.accent.withOpacity(0.3),
                        child: const Icon(Icons.home_rounded,
                            color: AppColors.secondary, size: 32)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.secondary,
                            size: 12),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                              '${p.area}, ${p.district}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.urbanist(
                                  fontSize: 11,
                                  color:
                                      AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(p.priceLabel,
                        style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.border)),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route strip
          if (!hasLocation)
            _infoBox(
              AppColors.warning,
              Icons.location_off_rounded,
              'Enable GPS to see route & travel time',
            )
          else if (loadingRoute)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text('Calculating route…',
                      style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else if (durationLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  _stat(Icons.access_time_rounded,
                      durationLabel, 'Drive Time'),
                  Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border),
                  _stat(Icons.straighten_rounded,
                      distanceLabel, 'Distance'),
                  Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border),
                  _stat(Icons.directions_car_rounded,
                      'Driving', 'Mode'),
                ],
              ),
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onOpen,
              child: Text('View Full Details',
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(Color color, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark)),
          Text(label,
              style: GoogleFonts.urbanist(
                  fontSize: 10,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
