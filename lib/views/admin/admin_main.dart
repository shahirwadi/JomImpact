import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import 'admin_marketplace_requests_screen.dart';
import 'admin_organizer_requests_screen.dart';
import 'admin_profile_screen.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _index = 0;

  final _screens = const [
    AdminOrganizerRequestsScreen(),
    AdminMarketplaceRequestsScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user),
            label: 'Organizers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
