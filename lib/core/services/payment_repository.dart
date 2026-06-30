import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class PaymentRepository {
  const PaymentRepository();

  Future<ApiClient> get _authClient async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('wamato_access_token');
    return ApiClient(accessToken: token);
  }

  /// Initiate a payment. Returns the full payment object from the backend.
  Future<Map<String, dynamic>> initiatePayment({
    required String type,         // 'unlock_property' | 'unlock_pack' | 'listing_package'
    required String method,       // 'mtn_momo' | 'airtel_money'
    required double amount,
    required String phoneNumber,
    String? propertyId,
    String? description,
  }) async {
    final client = await _authClient;
    final res = await client.post('/api/v1/payments/initiate', {
      'type': type,
      'method': method,
      'amount': amount,
      'phone_number': phoneNumber,
      'currency': 'UGX',
      if (propertyId != null) 'property_id': propertyId,
      if (description != null) 'description': description,
    });
    return res as Map<String, dynamic>;
  }

  /// Poll the status of a payment by its ID.
  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final client = await _authClient;
    final res = await client.get('/api/v1/payments/$paymentId');
    return res as Map<String, dynamic>;
  }

  /// Sandbox only — simulate a successful MTN callback so we can test without
  /// real MoMo keys. Calls the same webhook endpoint MTN would call.
  Future<void> simulateSuccess(String providerRef) async {
    final client = await _authClient;
    await client.post('/api/v1/payments/callback/mtn', {
      'provider_ref': providerRef,
      'status': 'SUCCESSFUL',
    });
  }
}
