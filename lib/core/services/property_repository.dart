import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../../models/property.dart';

class PropertyRepository {
  final String? accessToken;

  const PropertyRepository({this.accessToken});

  ApiClient get _client => ApiClient(accessToken: accessToken);

  Future<ApiClient> get _authClient async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('wamato_access_token');
    return ApiClient(accessToken: token ?? accessToken);
  }

  // ── Public endpoints ──────────────────────────────────────────────────────

  Future<List<Property>> getFeatured({int limit = 10}) async {
    final res = await _client.get('/api/v1/properties/featured', {'limit': limit});
    return (res as List).map((j) => Property.fromJson(j)).toList();
  }

  Future<List<Property>> getProperties({
    String? status,
    String? type,
    String? district,
    bool? isShortStay,
    bool? isFeatured,
    int page = 1,
    int size = 20,
  }) async {
    final res = await _client.get('/api/v1/properties', {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (district != null) 'district': district,
      if (isShortStay != null) 'is_short_stay': isShortStay.toString(),
      if (isFeatured != null) 'is_featured': isFeatured.toString(),
      'page': page.toString(),
      'size': size.toString(),
      'sort_by': 'created_at',
      'sort_order': 'desc',
    });
    return (res['items'] as List).map((j) => Property.fromJson(j)).toList();
  }

  Future<List<Property>> search(String query) async {
    final res = await _client.get('/api/v1/search', {
      'q': query,
      'size': '20',
    });
    final items = res is Map ? (res['items'] ?? res['results'] ?? []) : res;
    return (items as List).map((j) => Property.fromJson(j)).toList();
  }

  Future<Property> getProperty(String id) async {
    final res = await _client.get('/api/v1/properties/$id');
    return Property.fromJson(res);
  }

  // ── Auth-required endpoints ───────────────────────────────────────────────

  Future<Property> createProperty({
    required String title,
    required String type,
    required String status,
    required double price,
    required String district,
    required String area,
    required String description,
    int? bedrooms,
    int? bathrooms,
    bool hasSecurity = false,
    bool hasFurnishing = false,
    bool hasInternet = false,
    bool hasSwimmingPool = false,
    bool hasParking = false,
    bool hasGenerator = false,
    String listingPackage = 'basic',
  }) async {
    final client = await _authClient;
    final res = await client.post('/api/v1/properties', {
      'title': title,
      'type': type,
      'status': status,
      'price': price,
      'district': district,
      'area': area,
      'description': description,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      'has_security': hasSecurity,
      'has_furnishing': hasFurnishing,
      'has_internet': hasInternet,
      'has_swimming_pool': hasSwimmingPool,
      'has_gym': false,
      'has_generator': hasGenerator,
      'listing_package': listingPackage,
    });
    return Property.fromJson(res);
  }

  Future<List<Property>> getMyListings({int page = 1, int size = 20}) async {
    final client = await _authClient;
    final res = await client.get('/api/v1/properties/my', {
      'page': page.toString(),
      'size': size.toString(),
    });
    return (res['items'] as List).map((j) => Property.fromJson(j)).toList();
  }

  Future<List<Property>> getSavedProperties({int page = 1, int size = 20}) async {
    final client = await _authClient;
    final res = await client.get('/api/v1/users/me/saved-properties', {
      'page': page.toString(),
      'size': size.toString(),
    });
    return (res['items'] as List).map((j) => Property.fromJson(j)).toList();
  }

  Future<void> saveProperty(String propertyId) async {
    final client = await _authClient;
    await client.post('/api/v1/users/me/saved-properties/$propertyId', {});
  }

  Future<void> unsaveProperty(String propertyId) async {
    final client = await _authClient;
    await client.delete('/api/v1/users/me/saved-properties/$propertyId');
  }

  Future<void> deleteProperty(String propertyId) async {
    final client = await _authClient;
    await client.delete('/api/v1/properties/$propertyId');
  }
}
