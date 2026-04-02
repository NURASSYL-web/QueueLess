import 'package:flutter/material.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/features/home/presentation/screens/home_screen.dart';
import 'package:queue/src/features/map/presentation/screens/map_screen.dart';
import 'package:queue/src/features/profile/presentation/screens/profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [MapScreen(), HomeScreen(), ProfileScreen()];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.ink900.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: NavigationBar(
          height: 76,
          backgroundColor: Colors.transparent,
          selectedIndex: _currentIndex,
          onDestinationSelected: (value) {
            setState(() => _currentIndex = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.format_list_bulleted_rounded),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'List',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
