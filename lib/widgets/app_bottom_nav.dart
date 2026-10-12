import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex});
  final int selectedIndex;

  void _go(BuildContext context, int index) {
    final route = switch (index) { 0 => '/', 1 => '/discover', 2 => '/favorites', _ => '/settings' };
    if (index == selectedIndex) return;
    Navigator.pushNamedAndRemoveUntil(context, route, (entry) => entry.isFirst && route == '/');
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _go(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.bookmarks_outlined), selectedIcon: Icon(Icons.bookmarks_rounded), label: 'Shelf'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      );
}
