import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esportapp/models/predict_service.dart'; // Adjust the path as needed
import 'package:flutter/material.dart';

class Team {
  final String id;
  final String name;
  final String logo;

  Team({required this.id, required this.name, required this.logo});

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      logo: data['logo'] ?? '',
    );
  }
}

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  final TFLiteService predictor = TFLiteService();

  List<Team> teams = [];
  Team? selectedHomeTeam;
  Team? selectedAwayTeam;
  String result = "";
  String confidence = "";
  bool modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    predictor.loadModel().then((_) {
      setState(() => modelLoaded = true);
    }).catchError((e) {
      print("Model loading error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load prediction model")),
      );
    });
  }

  Future<void> _fetchTeams() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('teams').get();
      if (mounted) {
        setState(() {
          teams = snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();
        });
      }
    } catch (e) {
      print("Error fetching teams: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching teams: $e")),
      );
    }
  }

  Future<void> _predictMatch() async {
    if (!modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Model is still loading...")),
      );
      return;
    }

    if (selectedHomeTeam == null || selectedAwayTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select both teams.")),
      );
      return;
    }

    if (selectedHomeTeam!.id == selectedAwayTeam!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teams must be different.")),
      );
      return;
    }

    try {
      // ✅ Call prediction using only team IDs (model handles Firestore & stats)
      final prediction = await predictor.predictMatch(
        selectedHomeTeam!.id,
        selectedAwayTeam!.id,
      );

      setState(() {
        result = prediction['result'] ?? '';
        confidence = prediction['confidence'] ?? '';
      });

      // Auto-reset page after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            selectedHomeTeam = null;
            selectedAwayTeam = null;
            result = '';
            confidence = '';
          });
        }
      });
    } catch (e) {
      print("Prediction error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Prediction failed: $e")),
      );
    }
  }

  Widget _buildTeamDropdown(String label, Team? selectedTeam, ValueChanged<Team?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        DropdownButton<Team>(
          isExpanded: true,
          value: selectedTeam,
          hint: Text("Choose $label"),
          items: teams.map((team) {
            return DropdownMenuItem<Team>(
              value: team,
              child: Row(
                children: [
                  if (team.logo.isNotEmpty)
                    Image.asset(
                      'assets/teams/${team.logo}',
                      width: 30,
                      height: 30,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                    ),
                  const SizedBox(width: 8),
                  Text(team.name),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Match Predictor")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: teams.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamDropdown("Home Team", selectedHomeTeam, (val) {
                    setState(() => selectedHomeTeam = val);
                  }),
                  const SizedBox(height: 16),
                  _buildTeamDropdown("Away Team", selectedAwayTeam, (val) {
                    setState(() => selectedAwayTeam = val);
                  }),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _predictMatch,
                    child: const Text("Predict Match"),
                  ),
                  const SizedBox(height: 30),
                  if (result.isNotEmpty) ...[
                    Text("Prediction: $result", style: const TextStyle(fontSize: 20)),
                    Text("Confidence: $confidence%", style: const TextStyle(fontSize: 16)),
                  ]
                ],
              ),
      ),
    );
  }
}
