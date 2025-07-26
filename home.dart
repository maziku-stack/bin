import 'package:esportapp/authenticate/login.dart';
import 'package:esportapp/models/up_provider.dart';
import 'package:esportapp/models/upcoming.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esportapp/models/view.dart';
import 'package:esportapp/models/predict.dart' hide Team;
import 'package:esportapp/models/setting.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? userRole;
  bool isLoading = true;
  bool _teamsLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTeamProvider();
    });
  }

  void _initializeTeamProvider() {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    teamProvider.loadTeams().then((_) {
      setState(() => _teamsLoading = false);
    });
  }

  Future<void> fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userRole = doc.data()?['role'] ?? 'user';
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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
            Image.asset('assets/icon.png', height: 40),
            const SizedBox(width: 10),
            const Text('eSportApp'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFE3F2FD)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            children: [
              Text(
                userRole == 'admin'
                    ? "👑 Admin Dashboard"
                    : "Welcome to our eSportApp community",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 20),
              _buildTeamProviderStatus(),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  return Column(
                    children: [
                      if (userRole == 'admin') ..._adminOptions(context),
                      if (userRole != 'admin') ..._userOptions(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamProviderStatus() {
    if (_teamsLoading) {
      return const LinearProgressIndicator(minHeight:0.5);
    }
    
    return Consumer<TeamProvider>(
      builder: (context, provider, child) {
        if (provider.error != null) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.red[100],
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(child: Text('Team data: ${provider.error}')),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() => _teamsLoading = false);
                    provider.refreshTeams().then((_) {
                    setState(() => _teamsLoading = false);
                    });
                  },
                ),
              ],
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  List<Widget> _userOptions(BuildContext context) {
    return [
      CustomNavCard(
        icon: Icons.group,
        title: 'View Team',
        color: Colors.deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ViewTeamPage()),
        ),
      ),
      CustomNavCard(
        icon: Icons.sports_soccer,
        title: 'Upcoming Matches',
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpcomingMatches()),
        ),
      ),
      CustomNavCard(
        icon: Icons.how_to_vote,
        title: 'Predict Match',
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PredictPage(),
          ),
        ),
      ),
    ];
  }

  List<Widget> _adminOptions(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    
    return [
      CustomNavCard(
        icon: Icons.supervised_user_circle,
        title: 'Manage Users',
        color: Colors.redAccent,
        onTap: () {
          print('Admin has ${teamProvider.teams.length} teams');
        },
      ),
      CustomNavCard(
        icon: Icons.sports,
        title: 'Manage Teams',
        color: Colors.orange,
        onTap: () {
          teamProvider.refreshTeams();
        },
      ),
      CustomNavCard(
        icon: Icons.event,
        title: 'Manage Matches',
        color: Colors.green,
        onTap: () {
          print('Matches management with ${teamProvider.teams.length} teams');
        },
      ),
      CustomNavCard(
        icon: Icons.analytics,
        title: 'View Predictions',
        color: Colors.pinkAccent,
        onTap: () {
          print('Predictions for ${teamProvider.teams.length} teams');
        },
      ),
    ];
  }
}

class CustomNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const CustomNavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      // ignore: deprecated_member_use
      shadowColor: color.withOpacity(0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          // ignore: deprecated_member_use
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}