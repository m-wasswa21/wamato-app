import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/property_repository.dart';
import '../../models/property.dart';
import 'property_state.dart';

class PropertyCubit extends Cubit<PropertyState> {
  final PropertyRepository _repo;

  PropertyCubit(this._repo) : super(const PropertyInitial());

  Future<void> loadHome() async {
    emit(const PropertyLoading());
    try {
      // Fetch all three lists in parallel
      final results = await Future.wait([
        _repo.getFeatured(limit: 10),
        _repo.getProperties(isShortStay: true, size: 10),
        _repo.getProperties(size: 20),
      ]);

      final featured = results[0].where((p) => !p.isShortStay).toList();
      final stays = results[1];
      final recent = results[2].where((p) => !p.isShortStay).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Fall back to sample data if backend returns empty lists
      emit(PropertyLoaded(
        featured: featured.isNotEmpty ? featured : _sampleFeatured,
        stays: stays.isNotEmpty ? stays : _sampleStays,
        recent: recent.isNotEmpty ? recent : _sampleRecent,
      ));
    } catch (_) {
      // Network error — fall back to sample data so app always shows content
      emit(PropertyLoaded(
        featured: _sampleFeatured,
        stays: _sampleStays,
        recent: _sampleRecent,
      ));
    }
  }

  Future<List<Property>> fetchByFilter({
    String? status,
    String? type,
    String? district,
    bool? isShortStay,
    String? query,
  }) async {
    try {
      if (query != null && query.isNotEmpty) {
        return await _repo.search(query);
      }
      return await _repo.getProperties(
        status: status,
        type: type,
        district: district,
        isShortStay: isShortStay,
        size: 50,
      );
    } catch (_) {
      return [];
    }
  }
}

// Inline sample fallback helpers (delegates to model file)
List<Property> get _sampleFeatured => sampleProperties
    .where((p) => p.listingPackage == ListingPackage.featured && !p.isShortStay)
    .toList();

List<Property> get _sampleStays =>
    sampleProperties.where((p) => p.isShortStay).toList();

List<Property> get _sampleRecent => (sampleProperties
      .where((p) => !p.isShortStay)
      .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
