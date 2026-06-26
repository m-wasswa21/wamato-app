import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifMessages = true;
  bool _notifListings = true;
  bool _notifPriceDrops = true;
  bool _notifPromos = false;
  bool _darkMode = false;
  bool _locationServices = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Notifications'),
            _toggleTile('Messages',
                'Get notified for new messages', _notifMessages,
                (v) => setState(() => _notifMessages = v),
                Icons.message_rounded),
            _toggleTile('New Listings',
                'Alerts for properties matching your search',
                _notifListings,
                (v) => setState(() => _notifListings = v),
                Icons.home_rounded),
            _toggleTile('Price Drops',
                'When saved property prices change',
                _notifPriceDrops,
                (v) => setState(() => _notifPriceDrops = v),
                Icons.price_change_rounded),
            _toggleTile('Promotions',
                'Deals and featured listing offers', _notifPromos,
                (v) => setState(() => _notifPromos = v),
                Icons.local_offer_rounded),
            const SizedBox(height: 20),
            _sectionHeader('Appearance'),
            _toggleTile('Dark Mode', 'Switch to dark theme', _darkMode,
                (v) => setState(() => _darkMode = v),
                Icons.dark_mode_outlined),
            const SizedBox(height: 20),
            _sectionHeader('Location'),
            _toggleTile('Location Services',
                'Allow app to use your location', _locationServices,
                (v) => setState(() => _locationServices = v),
                Icons.location_on_outlined),
            const SizedBox(height: 20),
            _sectionHeader('Privacy & Security'),
            _navTile(Icons.lock_outline_rounded, 'Change Password', () {}),
            _navTile(Icons.phonelink_lock_rounded, 'Two-Factor Auth', () {}),
            _navTile(
                Icons.visibility_off_outlined, 'Profile Visibility', () {}),
            const SizedBox(height: 20),
            _sectionHeader('About'),
            _navTile(Icons.info_outline_rounded,
                'About Wamato', () {}),
            _navTile(Icons.article_outlined, 'Terms & Conditions', () {}),
            _navTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
            _navTile(Icons.star_outline_rounded, 'Rate the App', () {}),
            const SizedBox(height: 20),
            _sectionHeader('Danger Zone'),
            _navTile(Icons.delete_forever_rounded, 'Delete Account',
                () => _confirmDelete(context),
                danger: true),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account?',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently delete your account and all data. This cannot be undone.',
            style: GoogleFonts.urbanist(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.urbanist(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Delete',
                style: GoogleFonts.urbanist(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary)),
    );
  }

  Widget _toggleTile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.secondary,
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        title: Text(title,
            style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
        subtitle: Text(subtitle,
            style: GoogleFonts.urbanist(
                fontSize: 12, color: AppColors.textSecondary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  Widget _navTile(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.dark;
    final iconBg = danger
        ? AppColors.error.withOpacity(0.1)
        : AppColors.secondary.withOpacity(0.1);
    final iconColor = danger ? AppColors.error : AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }
}
