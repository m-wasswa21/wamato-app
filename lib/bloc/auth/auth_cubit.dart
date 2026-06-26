import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;

  AuthCubit(this._repo) : super(const AuthInitial());

  /// Called on app start — restore session from stored token.
  Future<void> checkSession() async {
    emit(const AuthLoading());
    try {
      final seen = await _repo.hasSeenOnboarding();
      final user = await _repo.restoreSession();
      if (user != null) {
        emit(_fromUser(user));
      } else {
        emit(AuthUnauthenticated(onboardingSeen: seen));
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> completeOnboarding() async {
    await _repo.markOnboardingSeen();
    // Re-emit unauthenticated with seen=true so router allows /auth routes
    emit(const AuthUnauthenticated(onboardingSeen: true));
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(email, password);
      emit(_fromUser(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      emit(_fromUser(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await _repo.clearTokens();
    emit(const AuthUnauthenticated());
  }

  Future<void> updateProfile({
    required String name,
    String? phone,
    String? bio,
    String? district,
  }) async {
    final current = state;
    if (current is! AuthAuthenticated) return;
    try {
      final updated = await _repo.patchProfile(
        name: name,
        phone: phone,
        bio: bio,
        district: district,
      );
      emit(current.copyWith(
        name: updated['full_name'] as String? ?? name,
        phone: updated['phone'] as String?,
        bio: updated['bio'] as String?,
        district: updated['district'] as String?,
      ));
    } catch (_) {
      // silently fail — UI shows success regardless of local state
    }
  }

  AuthAuthenticated _fromUser(Map<String, dynamic> user) => AuthAuthenticated(
        userId: user['id'].toString(),
        name: user['full_name'] as String? ?? '',
        email: user['email'] as String? ?? '',
        role: user['role'] as String? ?? 'user',
        phone: user['phone'] as String?,
        bio: user['bio'] as String?,
        district: user['district'] as String?,
        avatarUrl: user['avatar_url'] as String?,
      );
}
