import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Team {
  final String id;
  final String name;
  final String location;
  final String manager;
  final int founded;
  final String logoUrl;

  Team({
    required this.id,
    required this.name,
    required this.location,
    required this.manager,
    required this.founded,
    required this.logoUrl,
  });

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      manager: data['manager'] ?? '',
      founded: data['founded'] ?? 0,
      logoUrl: data['logoUrl'] ?? '',
    );
  }
}

class ViewTeamPage extends StatelessWidget {
  const ViewTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View Teams")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No teams found"));
          }

          final teams = docs.map((doc) => Team.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _getImageProvider(team.logoUrl),
                  ),
                  title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Location: ${team.location}"),
                      Text("Manager: ${team.manager}"),
                      Text("Founded: ${team.founded}"),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamDetailPage(team: team),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static ImageProvider _getImageProvider(String url) {
    if (url.isEmpty) {
      return const AssetImage('assets/teams/default_logo.png');
    } else if (url.startsWith('http') || url.startsWith('https')) {
      return NetworkImage(url);
    } else {
      return AssetImage('assets/teams/${url.toLowerCase()}');
    }
  }
}

class TeamDetailPage extends StatelessWidget {
  final Team team;

  const TeamDetailPage({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(team.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _getImageProvider(team.logoUrl),
            ),
            const SizedBox(height: 20),
            Text("Location: ${team.location}", style: const TextStyle(fontSize: 18)),
            Text("Manager: ${team.manager}", style: const TextStyle(fontSize: 18)),
            Text("Founded: ${team.founded}", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  static ImageProvider _getImageProvider(String url) {
    if (url.isEmpty) {
      return const AssetImage('assets/teams/default_logo.png');
    } else if (url.startsWith('http') || url.startsWith('https')) {
      return NetworkImage(url);
    } else {
      return AssetImage('assets/teams/${url.toLowerCase()}');
    }
  }
}
