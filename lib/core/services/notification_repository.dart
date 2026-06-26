import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class NotificationRepository {
  Future<ApiClient> get _client async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('wamato_access_token');
    return ApiClient(accessToken: token);
  }

  Future<List<Map<String, dynamic>>> getNotifications({int page = 1, int size = 30}) async {
    final client = await _client;
    final res = await client.get('/api/v1/notifications', {
      'page': page.toString(),
      'size': size.toString(),
    });
    final items = res is Map ? (res['items'] ?? []) : res;
    return (items as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> markRead(String id) async {
    final client = await _client;
    await client.post('/api/v1/notifications/$id/read', {});
  }

  Future<void> markAllRead() async {
    final client = await _client;
    await client.post('/api/v1/notifications/read-all', {});
  }
}
