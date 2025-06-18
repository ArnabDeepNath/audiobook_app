import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

final List<MenuItem> quickMenuItems = [
  MenuItem(
    title: 'Audiobooks',
    icon: Icons.headphones,
    route: '/audiobooks',
  ),
  MenuItem(
    title: 'E-Books',
    icon: Icons.book,
    route: '/ebooks',
  ),
  MenuItem(
    title: 'Poems',
    icon: Icons.auto_stories,
    route: '/poems',
  ),
  MenuItem(
    title: 'Kids Hub',
    icon: Icons.child_care,
    route: '/kids-hub',
  ),
  MenuItem(
    title: 'Students Hub',
    icon: Icons.school,
    route: '/students-hub',
  ),
  MenuItem(
    title: 'Articles',
    icon: Icons.article,
    route: '', // No route for now
  ),
];
