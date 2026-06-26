import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

const _kAccessToken = 'wamato_access_token';
const _kRefreshToken = 'wamato_refresh_token';
const _kUserName = 'wamato_user_name';
const _kUserEmail = 'wamato_user_email';
const _kOnboardingSeen = 'wamato_onboarding_seen';

class AuthRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Token storage ──────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async =>
      (await _prefs).getString(_kAccessToken);

  Future<bool> hasSeenOnboarding() async =>
      (await _prefs).getBool(_kOnboardingSeen) ?? false;

  Future<void> markOnboardingSeen() async =>
      (await _prefs).setBool(_kOnboardingSeen, true);

  Future<void> _saveTokens(String access, String refresh) async {
    final p = await _prefs;
    await p.setString(_kAccessToken, access);
    await p.setString(_kRefreshToken, refresh);
  }

  Future<void> clearTokens() async {
    final p = await _prefs;
    await p.remove(_kAccessToken);
    await p.remove(_kRefreshToken);
    await p.remove(_kUserName);
    await p.remove(_kUserEmail);
  }

  // ── Auth API calls ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await const ApiClient().post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    await _saveTokens(res['access_token'], res['refresh_token']);
    final me = await me_(res['access_token']);
    final p = await _prefs;
    await p.setString(_kUserName, me['full_name'] ?? '');
    await p.setString(_kUserEmail, me['email'] ?? email);
    return me;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    await const ApiClient().post('/api/v1/auth/register', {
      'full_name': fullName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    // Auto-login after registration
    return login(email, password);
  }

  Future<Map<String, dynamic>> me_(String token) async {
    return await ApiClient(accessToken: token).get('/api/v1/auth/me');
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    final token = await getAccessToken();
    if (token == null) return null;
    try {
      return await me_(token);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> patchProfile({
    required String name,
    String? phone,
    String? bio,
    String? district,
  }) async {
    final token = await getAccessToken();
    final res = await ApiClient(accessToken: token).patch('/api/v1/users/me', {
      'full_name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      if (district != null && district.isNotEmpty) 'district': district,
    });
    final p = await _prefs;
    await p.setString(_kUserName, name);
    return res;
  }

  Future<String?> getSavedName() async =>
      (await _prefs).getString(_kUserName);

  Future<String?> getSavedEmail() async =>
      (await _prefs).getString(_kUserEmail);
}
