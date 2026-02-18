import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../history/screens/ride_history_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RideHistoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: const Text('Home'),
                      selected: _selectedIndex == 0,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        _onItemTapped(0);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Your Trips'),
                      selected: _selectedIndex == 1,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        _onItemTapped(1);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('My Profile'),
                      selected: _selectedIndex == 2,
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        _onItemTapped(2);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help'),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help coming soon')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
