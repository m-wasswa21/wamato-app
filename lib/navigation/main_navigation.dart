import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/auth_guard.dart';
import '../screens/home/home_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/property/add_property_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/profile/profile_screen.dart';

const _kFabDecoration = BoxDecoration(
  gradient: LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  shape: BoxShape.circle,
  boxShadow: [
    BoxShadow(
      color: Color(0x66074173),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ],
);

// Tabs that require the user to be logged in
const _kProtectedTabs = {3, 4}; // Messages, Profile

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    _AddPlaceholder(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  Future<void> _onTabTap(int idx) async {
    if (_kProtectedTabs.contains(idx)) {
      final ok = await ensureAuth(context);
      if (!ok || !mounted) return;
    }
    setState(() => _index = idx);
  }

  Future<void> _onFabTap() async {
    final ok = await ensureAuth(context);
    if (!ok || !mounted) return;
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppColors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 10,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
            _navItem(1, Icons.search_rounded, Icons.search_outlined, 'Search'),
            const SizedBox(width: 56),
            _navItem(3, Icons.chat_rounded, Icons.chat_outlined, 'Messages'),
            _navItem(4, Icons.person_rounded, Icons.person_outlined, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      int idx, IconData activeIcon, IconData inactiveIcon, String label) {
    final active = _index == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? activeIcon : inactiveIcon,
                key: ValueKey(active),
                color: active ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: active ? T.navActive : T.navInactive),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _onFabTap,
      child: const SizedBox(
        width: 56,
        height: 56,
        child: DecoratedBox(
          decoration: _kFabDecoration,
          child: Icon(Icons.add_rounded, color: AppColors.white, size: 28),
        ),
      ),
    );
  }
}

class _AddPlaceholder extends StatelessWidget {
  const _AddPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
