import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;

  const MainWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role;
    
    // Get current location to highlight correct tab
    final String location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _getSelectedIndex(location, userRole),
          onTap: (index) => _onItemTapped(context, index, userRole),
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textLight,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _getNavItems(userRole),
        ),
      ),
    );
  }

  int _getSelectedIndex(String location, String? role) {
    if (role == 'officer' || role == 'admin') {
      if (location.startsWith('/officer-home') || location.startsWith('/dashboard')) return 0;
      if (location.startsWith('/scan')) return 1;
      if (location.startsWith('/profile')) return 2;
    } else {
      // Default to student/staff/visitor items
      if (location == '/' || location.startsWith('/home')) return 0;
      if (location.startsWith('/my-devices')) return 1;
      if (location.startsWith('/profile')) return 2;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index, String? role) {
    if (role == 'officer' || role == 'admin') {
      switch (index) {
        case 0:
          context.go(role == 'admin' ? '/dashboard' : '/officer-home');
          break;
        case 1:
          context.go('/scan');
          break;
        case 2:
          context.go('/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/my-devices');
          break;
        case 2:
          context.go('/profile');
          break;
      }
    }
  }

  List<BottomNavigationBarItem> _getNavItems(String? role) {
    if (role == 'officer' || role == 'admin') {
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_outlined),
          activeIcon: const Icon(Icons.dashboard),
          label: role == 'admin' ? 'Dashboard' : 'Officer Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner_outlined),
          activeIcon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.devices_outlined),
          activeIcon: Icon(Icons.devices),
          label: 'My Devices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }
}
