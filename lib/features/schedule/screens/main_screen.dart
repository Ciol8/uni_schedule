import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'weekly_schedule_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lista ekranów do przełączania
  final List<Widget> _screens = [
    const HomeScreen(),
    const WeeklyScheduleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack sprawia, że ekrany nie ładują się od nowa po przełączeniu karty
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.calendar_today_rounded),
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Kalendarz',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.view_agenda_rounded),
            icon: Icon(Icons.view_agenda_outlined),
            label: 'Plan Tygodnia',
          ),
        ],
      ),
    );
  }
}