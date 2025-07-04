import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String userDetails = '/user_details';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
}

class NavItem {
  final String label;
  final String route;
  final IconData icon;

  const NavItem({required this.label, required this.route, required this.icon});
}

final List<NavItem> navItems = [
  const NavItem(
    label: 'Tableau de bord',
    route: AppRoutes.dashboard,
    icon: Icons.dashboard,
  ),
  const NavItem(
    label: 'Utilisateurs',
    route: AppRoutes.users,
    icon: Icons.people,
  ),
  const NavItem(
    label: 'Statistiques',
    route: AppRoutes.statistics,
    icon: Icons.bar_chart,
  ),
  const NavItem(
    label: 'Paramètres',
    route: AppRoutes.settings,
    icon: Icons.settings,
  ),
];
