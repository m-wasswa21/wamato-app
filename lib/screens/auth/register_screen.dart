import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole ?? 'Seeker';
  }
  bool _agree = false;

  void _submit() {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please accept Terms & Conditions',
            style: GoogleFonts.urbanist()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    final data = _formKey.currentState!.value;
    context.read<AuthCubit>().register(
          fullName: data['full_name'] as String,
          email: data['email'] as String,
          password: data['password'] as String,
          phone: data['phone'] as String?,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message, style: GoogleFonts.urbanist()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.go('/auth/login'),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Account',
                      style: GoogleFonts.urbanist(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark)),
                  const SizedBox(height: 8),
                  Text("Join Uganda's #1 Property Marketplace",
                      style: GoogleFonts.urbanist(
                          fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),
                  FormBuilder(
                    key: _formKey,
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: 'full_name',
                          decoration: _inputDec(
                              'Full Name', 'Enter your full name',
                              Icons.person_outline_rounded),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(3),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'phone',
                          decoration: _inputDec(
                              'Phone Number', '+256 7XX XXX XXX',
                              Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'email',
                          decoration: _inputDec(
                              'Email Address', 'Enter your email',
                              Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.email(),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'password',
                          obscureText: true,
                          decoration: _inputDec(
                              'Password', 'Create a strong password (min 8 chars)',
                              Icons.lock_outline_rounded),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(8),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTermsRow(),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Create Account',
                    onTap: loading ? null : _submit,
                    prefix: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.urbanist(
                              color: AppColors.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.go('/auth/login'),
                        child: Text('Sign In',
                            style: GoogleFonts.urbanist(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
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

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I am a...',
            style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.dark)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _roleCard(
              role: 'Seeker',
              icon: Icons.person_search_rounded,
              emoji: '🔍',
              label: 'Property\nSeeker',
              description: 'Find & rent or buy properties',
              color: AppColors.primary,
              bgColor: const Color(0xFFEFF6FF),
            )),
            const SizedBox(width: 10),
            Expanded(child: _roleCard(
              role: 'Agent',
              icon: Icons.real_estate_agent_rounded,
              emoji: '🏢',
              label: 'Property\nAgent',
              description: 'List & manage client properties',
              color: AppColors.secondary,
              bgColor: const Color(0xFFFFF7ED),
            )),
            const SizedBox(width: 10),
            Expanded(child: _roleCard(
              role: 'Owner',
              icon: Icons.house_rounded,
              emoji: '🔑',
              label: 'Property\nOwner',
              description: 'List your own property directly',
              color: AppColors.success,
              bgColor: const Color(0xFFF0FDF4),
            )),
          ],
        ),
      ],
    );
  }

  Widget _roleCard({
    required String role,
    required IconData icon,
    required String emoji,
    required String label,
    required String description,
    required Color color,
    required Color bgColor,
  }) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.06) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]
              : [const BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            // Logo illustration
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : bgColor,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: selected ? color : color.withOpacity(0.6), size: 30),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Text(emoji, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.dark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 10,
                color: AppColors.textTertiary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agree,
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => setState(() => _agree = v!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.urbanist(
                  fontSize: 13, color: AppColors.textSecondary),
              children: const [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600)),
                TextSpan(text: ' and '),
                TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDec(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
