import 'package:flutter/material.dart';
import 'package:guardian_circle/core/navigation/caregiver_destination.dart';
import 'package:guardian_circle/features/alerts/presentation/alerts_screen.dart';
import 'package:guardian_circle/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:guardian_circle/features/map/presentation/map_screen.dart';
import 'package:guardian_circle/features/more/presentation/more_screen.dart';
import 'package:guardian_circle/features/plans/presentation/plans_screen.dart';

/// Central navigation shell for the Guardian Circle Caregiver App.
/// Coordinates the 5 primary tabs: Home, Alerts, Location, Plans, and More.
class CaregiverShell extends StatefulWidget {
  const CaregiverShell({super.key});

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  CaregiverDestination _selected = CaregiverDestination.home;

  void _navigate(CaregiverDestination destination) {
    setState(() => _selected = destination);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigate: _navigate),
      const AlertsScreen(),
      const MapScreen(),
      const PlansScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selected.index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected.index,
        onDestinationSelected: (index) {
          _navigate(CaregiverDestination.values[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Location',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_open_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
