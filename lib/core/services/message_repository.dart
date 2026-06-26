import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class MessageRepository {
  Future<ApiClient> get _client async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('wamato_access_token');
    return ApiClient(accessToken: token);
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final client = await _client;
    final res = await client.get('/api/v1/messages/conversations');
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getMessages(String convId, {int page = 1, int size = 50}) async {
    final client = await _client;
    final res = await client.get('/api/v1/messages/conversations/$convId/messages', {
      'page': page.toString(),
      'size': size.toString(),
    });
    final items = res is Map ? (res['items'] ?? []) : res;
    return (items as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> sendMessage(String convId, String content) async {
    final client = await _client;
    final res = await client.post('/api/v1/messages/conversations/$convId/messages', {
      'content': content,
      'message_type': 'text',
    });
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> startConversation({
    required String recipientId,
    required String firstMessage,
    String? propertyId,
  }) async {
    final client = await _client;
    final res = await client.post('/api/v1/messages/conversations', {
      'recipient_id': recipientId,
      'first_message': firstMessage,
      if (propertyId != null) 'property_id': propertyId,
    });
    return Map<String, dynamic>.from(res);
  }
}
