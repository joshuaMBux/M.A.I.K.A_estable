import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../chat/avatar_chat_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../testing/rasa_test_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const AvatarChatScreen(), // Chat con interfaz de avatar
    const FavoritesScreen(),
    const ProfileScreen(),
    const RasaTestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          // Contenido principal
          _screens[_currentIndex],
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF6B46C1),
            unselectedItemColor: Colors.white.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
            items: [
              _buildNavItem(Icons.home, 'Inicio', 0),
              _buildNavItem(Icons.explore, 'Explorar', 1),
              _buildNavItem(Icons.chat, 'Chat', 2),
              _buildNavItem(Icons.favorite, 'Favoritos', 3),
              _buildNavItem(Icons.person, 'Perfil', 4),
              _buildNavItem(Icons.science, 'Test', 5),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF6B46C1).withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFF6B46C1).withOpacity(0.3)
                          : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color:
                    isSelected
                        ? const Color(0xFF6B46C1)
                        : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
