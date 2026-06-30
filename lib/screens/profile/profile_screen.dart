import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/saved/saved_cubit.dart';
import '../../core/services/property_repository.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'my_listings_screen.dart';
import 'saved_properties_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _listingsCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final count = await const PropertyRepository().getMyListingsCount();
      if (mounted) setState(() { _listingsCount = count; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState : null;
        final savedCount = context.watch<SavedCubit>().state.length;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: Text('My Profile',
                style: GoogleFonts.urbanist(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(user),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 20),
                  _buildMenuSection('My Properties', [
                    _MenuItem(
                      Icons.home_rounded,
                      'My Listings',
                      _loadingStats ? '' : '$_listingsCount Active',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyListingsScreen())),
                    ),
                    _MenuItem(
                      Icons.favorite_rounded,
                      'Saved Properties',
                      '$savedCount Saved',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SavedPropertiesScreen())),
                    ),
                    _MenuItem(Icons.history_rounded, 'Viewed Properties',
                        'Last 30 days', () {}),
                  ]),
                  const SizedBox(height: 16),
                  _buildMenuSection('Payments', [
                    _MenuItem(Icons.receipt_long_rounded, 'Payment History', '', () {}),
                    _MenuItem(Icons.lock_open_rounded, 'Unlocked Properties', '0 Properties', () {}),
                    _MenuItem(Icons.card_giftcard_rounded, 'Subscription Plan', 'Free Plan', () {}),
                  ]),
                  const SizedBox(height: 16),
                  _buildMenuSection('Account', [
                    _MenuItem(
                      Icons.edit_rounded,
                      'Edit Profile',
                      '',
                      () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        // Refresh stats after returning from edit
                        _loadStats();
                      },
                    ),
                    _MenuItem(Icons.verified_user_rounded, 'Verify Identity', 'Not Verified', () {}),
                    _MenuItem(
                      Icons.notifications_rounded,
                      'Notifications',
                      '',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                    _MenuItem(Icons.help_outline_rounded, 'Help & Support', '', () {}),
                    _MenuItem(Icons.info_outline_rounded, 'About Wamato', '', () {}),
                  ]),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        context.read<AuthCubit>().logout();
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Text('Sign Out',
                                style: GoogleFonts.urbanist(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthAuthenticated? user) {
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final roleLabel = _roleLabel(user?.role ?? 'user');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.white.withOpacity(0.2),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.white, size: 52),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name,
              style: GoogleFonts.urbanist(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email,
              style: GoogleFonts.urbanist(
                  color: AppColors.white.withOpacity(0.8), fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.white, size: 14),
                const SizedBox(width: 6),
                Text(roleLabel,
                    style: GoogleFonts.urbanist(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'agent':
        return 'Property Agent';
      case 'admin':
        return 'Administrator';
      default:
        return 'Property Seeker';
    }
  }

  Widget _buildStats() {
    return BlocBuilder<SavedCubit, Set<String>>(
      builder: (context, savedIds) {
        final savedCount = savedIds.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _statBox(_loadingStats ? '…' : '$_listingsCount', 'Listings',
                  Icons.home_rounded),
              const SizedBox(width: 12),
              _statBox('$savedCount', 'Saved', Icons.favorite_rounded),
              const SizedBox(width: 12),
              _statBox('0', 'Unlocked', Icons.lock_open_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.dark.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            Text(label,
                style: GoogleFonts.urbanist(
                    fontSize: 11,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.dark.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final item = e.value;
                final last = e.key == items.length - 1;
                return GestureDetector(
                  onTap: item.onTap,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon,
                                  color: AppColors.secondary, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(item.label,
                                  style: GoogleFonts.urbanist(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark)),
                            ),
                            if (item.trailing.isNotEmpty)
                              Text(item.trailing,
                                  style: GoogleFonts.urbanist(
                                      fontSize: 12,
                                      color: AppColors.textTertiary)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: AppColors.textTertiary, size: 14),
                          ],
                        ),
                      ),
                      if (!last)
                        const Divider(
                            height: 1, color: AppColors.border, indent: 68),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.trailing, this.onTap);
}
