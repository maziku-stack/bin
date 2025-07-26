import 'package:esportapp/admin/manage_matches.dart';
import 'package:esportapp/admin/manage_teams.dart';
import 'package:esportapp/admin/manage_users.dart';
import 'package:esportapp/admin/predict_result.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int totalUsers = 0;
  int totalMatches = 0;
  int totalTeams = 0;
  int totalPredictions = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();
      final teamsSnapshot = await FirebaseFirestore.instance.collection('teams').get();
      final predictionsSnapshot = await FirebaseFirestore.instance.collection('predictions').get();

      setState(() {
        totalUsers = usersSnapshot.size;
        totalMatches = matchesSnapshot.size;
        totalTeams = teamsSnapshot.size;
        totalPredictions = predictionsSnapshot.size;
      });
    } catch (e) {
      print('Error fetching counts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch dashboard data')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: fetchCounts,
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          DashboardCard(
            title: "Total Users",
            value: totalUsers.toString(),
            onTap: () => navigateToPage(const  ManageUsers()),
          ),
          DashboardCard(
            title: "Matches",
            value: totalMatches.toString(),
            onTap: () => navigateToPage(const ManageMatches()),
          ),
          DashboardCard(
            title: "Teams",
            value: totalTeams.toString(),
            onTap: () => navigateToPage(const ManageTeams()),
          ),
          DashboardCard(
            title: "Predictions",
            value: totalPredictions.toString(),
            onTap: () => navigateToPage(const ManagePredictions()),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: ListTile(
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}
