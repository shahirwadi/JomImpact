// lib/views/organizer/organizer_main.dart

import 'package:flutter/material.dart';
import '../shared/feed_screen.dart';
import '../shared/marketplace_screen.dart';
import '../shared/widgets.dart';
import 'organizer_dashboard_screen.dart';
import 'organizer_events_screen.dart';
import 'organizer_profile_screen.dart';

class OrganizerMain extends StatefulWidget {
  const OrganizerMain({super.key});
  @override
  State<OrganizerMain> createState() => _OrganizerMainState();
}

class _OrganizerMainState extends State<OrganizerMain> {
  int _index = 0;

  final _screens = const [
    OrganizerDashboardScreen(),
    FeedScreen(),
    OrganizerEventsScreen(),
    MarketplaceScreen(),
    OrganizerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: ReferenceBottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'Feed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'My Events'),
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Market'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
