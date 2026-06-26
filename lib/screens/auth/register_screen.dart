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
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String _role = 'Seeker';
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
        const SizedBox(height: 10),
        Row(
          children: [
            _roleChip('Seeker', Icons.search_rounded),
            const SizedBox(width: 10),
            _roleChip('Owner', Icons.home_rounded),
            const SizedBox(width: 10),
            _roleChip('Agent', Icons.badge_rounded),
          ],
        ),
      ],
    );
  }

  Widget _roleChip(String label, IconData icon) {
    final selected = _role == label;
    return GestureDetector(
      onTap: () => setState(() => _role = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.white : AppColors.textSecondary,
                size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.textSecondary)),
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
