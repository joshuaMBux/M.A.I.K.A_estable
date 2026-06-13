import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../chat/chat_screen.dart';
import '../favorites/favorites_screen.dart';
import '../games/games_screen.dart';
import '../profile/profile_screen.dart';
//import '../testing/rasa_test_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onProfileTap: () => setState(() => _currentIndex = 5),
      ),
      const ExploreScreen(),
      const ChatScreen(), // Chat con interfaz de avatar
      const FavoritesScreen(),
      const GamesScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.backgroundPrimary,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: scheme.pageGradient,
            ),
          ),
          _screens[_currentIndex],
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: scheme.overlayOnSurface(0.18, lightAlpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: scheme.borderWithOverlay(0.1, lightAlpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadowWithOverlay(0.3, lightAlpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: scheme.primary,
            unselectedItemColor: scheme.textSecondary,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 11,
              color: scheme.textSecondary,
            ),
            items: [
              _buildNavItem(context, Icons.home, 'Inicio', 0),
              _buildNavItem(context, Icons.explore, 'Explorar', 1),
              _buildNavItem(context, Icons.chat, 'Chat', 2),
              _buildNavItem(context, Icons.favorite, 'Favoritos', 3),
              _buildNavItem(context, Icons.sports_esports, 'Minijuegos', 4),
              _buildNavItem(context, Icons.person, 'Perfil', 5),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    final scheme = Theme.of(context).colorScheme;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            const SizedBox(height: 2),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? scheme.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isSelected
                          ? scheme.primary.withValues(alpha: 0.28)
                          : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? scheme.primary : scheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
