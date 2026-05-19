import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esportapp/models/predict.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingMatches extends StatefulWidget {
  const UpcomingMatches({super.key});

  @override
  State<UpcomingMatches> createState() => _UpcomingMatchesState();
}

class _UpcomingMatchesState extends State<UpcomingMatches> {
  final Map<String, Map<String, dynamic>> _teamsMap = {};
  bool _teamsLoaded = false;
  bool _hasError = false;
  bool _isRefreshing = false;
  DateTime? _lastTeamLoadTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _loadTeamsIfNeeded();
  }

  Future<void> _loadTeamsIfNeeded() async {
    if (_lastTeamLoadTime == null || 
        DateTime.now().difference(_lastTeamLoadTime!) > _cacheDuration) {
      await _loadTeams();
    }
  }

  Future<void> _loadTeams() async {
    try {
      setState(() => _isRefreshing = true);

      final QuerySnapshot snapshot = 
          await FirebaseFirestore.instance.collection('teams').get();

      final map = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        map[data['name']] = {
          'name': data['name']?.toString() ?? 'Team ${doc.id}',
          'logo': data['logo']?.toString() ?? '',
        };
      }

      setState(() {
        _teamsMap.clear();
        _teamsMap.addAll(map);
        _teamsLoaded = true;
        _hasError = false;
        _lastTeamLoadTime = DateTime.now();
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadTeams();
  }

  Widget _buildTeamLogo(String? logoPath, String teamName) {
    final safeName = teamName.isEmpty ? 'T' : teamName;

    if (logoPath != null && logoPath.isNotEmpty) {
      return Image.asset(
        'assets/teams/$logoPath',
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => _buildDefaultTeamIcon(safeName),
      );
    }
    return _buildDefaultTeamIcon(safeName);
  }

  Widget _buildDefaultTeamIcon(String teamName) {
    final firstChar = teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : 'T';
    final colorIndex = teamName.hashCode % Colors.primaries.length;
    final color = Colors.primaries[colorIndex];

    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        firstChar,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upcoming Matches'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load team data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTeams,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_teamsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Matches'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .where('matchDate', isGreaterThan: Timestamp.now())
              .orderBy('matchDate')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load matches'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final matches = snapshot.data?.docs ?? [];
            if (matches.isEmpty) {
              return const Center(child: Text('No upcoming matches.'));
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final data = matches[index].data() as Map<String, dynamic>;

                final String teamA = data['teamA']?.toString() ?? 'Unknown';
                final String teamB = data['teamB']?.toString() ?? 'Unknown';
                final Timestamp? matchDate = data['matchDate'] as Timestamp?;
                final DateTime date = matchDate?.toDate() ?? DateTime.now();
                final venue = data['venue']?.toString() ?? 'TBD';

                final home = _teamsMap[teamA] ?? {'name': teamA, 'logo': ''};
                final away = _teamsMap[teamB] ?? {'name': teamB, 'logo': ''};

                final formattedDate = DateFormat('EEE, MMM d • hh:mm a').format(date);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: _buildTeamLogo(home['logo'], home['name']),
                    title: Text(
                      '${home['name']} vs ${away['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$formattedDate\nVenue: $venue'),
                    trailing: _buildTeamLogo(away['logo'], away['name']),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PredictPage(),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
