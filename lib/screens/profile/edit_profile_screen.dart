import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _bio;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth : null;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _location = TextEditingController(text: user?.district ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Name cannot be empty',
            style: GoogleFonts.urbanist(color: AppColors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthCubit>().updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            bio: _bio.text.trim(),
            district: _location.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated!',
            style: GoogleFonts.urbanist(color: AppColors.white, fontSize: 13)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update failed. Try again.',
            style: GoogleFonts.urbanist(color: AppColors.white, fontSize: 13)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.secondary))
                : Text('Save',
                    style: GoogleFonts.urbanist(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withOpacity(0.12),
                      border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                          width: 3),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.secondary, size: 52),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: AppColors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Tap camera to change photo',
                  style: GoogleFonts.urbanist(
                      fontSize: 12, color: AppColors.textTertiary)),
            ),
            const SizedBox(height: 28),
            _label('Full Name *'),
            _field(_name, Icons.person_outline_rounded,
                hint: 'Your full name'),
            const SizedBox(height: 16),
            _label('Phone Number'),
            _field(_phone, Icons.phone_outlined,
                keyboard: TextInputType.phone, hint: '+256 700 000 000'),
            const SizedBox(height: 16),
            _label('District / Location'),
            _field(_location, Icons.location_on_outlined,
                hint: 'e.g. Kampala'),
            const SizedBox(height: 16),
            _label('Bio'),
            TextField(
              controller: _bio,
              maxLines: 3,
              style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.dark),
              decoration: InputDecoration(
                hintText: 'Tell others about yourself...',
                hintStyle: GoogleFonts.urbanist(
                    color: AppColors.textTertiary, fontSize: 14),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.secondary, width: 1.5)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white))
                    : Text('Save Changes',
                        style: GoogleFonts.urbanist(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }

  Widget _field(TextEditingController ctrl, IconData icon,
      {TextInputType keyboard = TextInputType.text, String hint = ''}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.urbanist(
            color: AppColors.textTertiary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.secondary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
