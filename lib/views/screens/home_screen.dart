// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:chw_tb/components/bottom_navigation.dart';
import 'package:chw_tb/controllers/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await AuthService.instance.signOut();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/sign-in');
          },
          child: const Text("Sign Out"),
        ),
      ),
      bottomNavigationBar: NavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
