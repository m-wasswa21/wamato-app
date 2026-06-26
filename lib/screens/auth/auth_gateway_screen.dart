import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen>
    with SingleTickerProviderStateMixin {
  String? _selected; // 'seeker' | 'agent'
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _pick(String role) {
    setState(() => _selected = role);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            // Top logo bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png',
                      height: 34, fit: BoxFit.contain),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text('Browse as Guest',
                        style: GoogleFonts.urbanist(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Who are you?',
                  style: GoogleFonts.urbanist(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                  "Choose your role to get the experience built for you.",
                  style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.white54,
                      height: 1.5)),
            ),

            const SizedBox(height: 28),

            // Role cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        role: 'seeker',
                        selected: _selected == 'seeker',
                        title: 'Property\nSeeker',
                        subtitle: 'Find your perfect home, plot or office space',
                        emoji: '🔍',
                        icon: Icons.person_search_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        features: const [
                          'Browse verified listings',
                          'Save favourite properties',
                          'Chat with agents directly',
                          'Filter by location & price',
                        ],
                        onTap: () => _pick('seeker'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        role: 'agent',
                        selected: _selected == 'agent',
                        title: 'Agent /\nOwner',
                        subtitle: 'List, manage and sell your properties',
                        emoji: '🏢',
                        icon: Icons.real_estate_agent_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF92400E), Color(0xFFF59E0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        features: const [
                          'Post unlimited listings',
                          'Manage enquiries & leads',
                          'Get verified agent badge',
                          'Analytics & performance',
                        ],
                        onTap: () => _pick('agent'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons — shown after picking
            AnimatedBuilder(
              animation: _fade,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: _selected == null
                    ? const SizedBox(height: 100)
                    : _buildActions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final isSeeker = _selected == 'seeker';
    final accentColor = isSeeker ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);
    final registerRole = isSeeker ? 'Seeker' : 'Agent';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sign In button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/auth/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Sign In',
                  style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.go(
                  '/auth/register',
                  extra: registerRole,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Create Account',
                  style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accentColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final bool selected;
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final LinearGradient gradient;
  final List<String> features;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.gradient,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: gradient.colors.last.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]
              : [],
        ),
        child: Stack(
          children: [
            // Big background emoji watermark
            Positioned(
              right: -10,
              bottom: -10,
              child: Text(emoji,
                  style: TextStyle(
                      fontSize: 90,
                      color: Colors.white.withOpacity(0.12))),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(title,
                      style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2)),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(subtitle,
                      style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.4)),

                  const SizedBox(height: 16),

                  // Feature list
                  ...features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 10),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(f,
                                  style: GoogleFonts.urbanist(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      )),

                  const Spacer(),

                  // Selected indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        selected ? 'Selected ✓' : 'Tap to select',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? gradient.colors.first
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
