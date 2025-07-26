import 'package:esportapp/admin/dash.dart';
import 'package:flutter/material.dart';
import 'package:esportapp/admin/manage_users.dart';
import 'package:esportapp/admin/manage_teams.dart';
import 'package:esportapp/admin/manage_matches.dart';
import 'package:esportapp/admin/predict_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:esportapp/authenticate/login.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    Dashboard(),
    ManageUsers(),
    ManageTeams(),
    ManageMatches(),
    ManagePredictions(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
      
        elevation: 0,
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF283593), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
      Image.asset(
        'assets/icon.png',
        height: 40,
      ),
      SizedBox(width: 10),
      Text(' Admin dashboard'),
    ],
            
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: () => _confirmLogout(context),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(221, 82, 138, 234),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer), label: "Teams"),
          BottomNavigationBarItem(
              icon: Icon(Icons.event), label: "Matches"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: "Predictions"),
        ],
      ),
    );
  }
}
