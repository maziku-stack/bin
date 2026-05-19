import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageMatches extends StatefulWidget {
  const ManageMatches({Key? key}) : super(key: key);

  @override
  State<ManageMatches> createState() => _ManageMatchesState();
}

class _ManageMatchesState extends State<ManageMatches> {
  final CollectionReference matchesCollection =
      FirebaseFirestore.instance.collection('matches');

  final CollectionReference teamsCollection =
      FirebaseFirestore.instance.collection('teams');

  final DatabaseReference realtimeDB =
      FirebaseDatabase.instance.ref().child('upcomingMatches');

  final _formKey = GlobalKey<FormState>();

  String? selectedTeamA;
  String? selectedTeamB;
  DateTime? selectedDate;

  bool isEditing = false;
  String? editingDocId;
  String? realtimeKey;

  List<Map<String, dynamic>> teams = [];

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    final snapshot = await teamsCollection.get();
    teams = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'logo': data['logo'] ?? '',
      };
    }).toList();
    setState(() {});
  }

  void clearControllers() {
    selectedTeamA = null;
    selectedTeamB = null;
    selectedDate = null;
    realtimeKey = null;
  }

  Future<void> addOrUpdateMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedTeamA == null || selectedTeamB == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both teams and a date')),
      );
      return;
    }
    if (selectedTeamA == selectedTeamB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teams must be different')),
      );
      return;
    }

    Map<String, dynamic> firestoreData = {
      'teamA': selectedTeamA ?? '',
      'teamB': selectedTeamB ?? '',
      'matchDate': Timestamp.fromDate(selectedDate!),
      'createdAt': FieldValue.serverTimestamp(),
    };

    Map<String, dynamic> realtimeData = {
      'homeTeam': selectedTeamA ?? '',
      'awayTeam': selectedTeamB ?? '',
      'date': selectedDate!.toIso8601String(),
    };

    try {
      if (isEditing && editingDocId != null) {
        await matchesCollection.doc(editingDocId).update(firestoreData);
        await realtimeDB.child(editingDocId!).update(realtimeData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match updated successfully!')),
        );
      } else {
        DocumentReference newDoc = await matchesCollection.add(firestoreData);
        await realtimeDB.child(newDoc.id).set(realtimeData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match added successfully!')),
        );
      }

      clearControllers();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String? getTeamLogo(String? teamName) {
    final team = teams.firstWhere(
      (t) => t['name'] == teamName,
      orElse: () => {},
    );
    if (team.isEmpty) return null;
    return team['logo'] != null && team['logo'].toString().isNotEmpty
        ? 'assets/teams/${team['logo']}'
        : null;
  }

  void showAddEditDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      isEditing = true;
      editingDocId = doc.id;
      var data = doc.data() as Map<String, dynamic>;
      selectedTeamA = data['teamA'] ?? '';
      selectedTeamB = data['teamB'] ?? '';
      selectedDate = (data['matchDate'] as Timestamp).toDate();
      realtimeKey = editingDocId;
    } else {
      isEditing = false;
      editingDocId = null;
      clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Match' : 'Add New Match'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTeamA,
                  decoration: const InputDecoration(labelText: 'Select Team A'),
                  items: teams.map(
                    (team) => DropdownMenuItem<String>(
                      value: team['name'] ?? '',
                      child: Row(
                        children: [
                          if ((team['logo'] ?? '').toString().isNotEmpty)
                            Image.asset(
                              'assets/teams/${team['logo']}',
                              width: 30,
                              height: 30,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported, size: 30),
                            ),
                          const SizedBox(width: 8),
                          Text(team['name'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  ).toList(),
                  onChanged: (val) => setState(() => selectedTeamA = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please select Team A' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedTeamB,
                  decoration: const InputDecoration(labelText: 'Select Team B'),
                  items: teams.map(
                    (team) => DropdownMenuItem<String>(
                      value: team['name'] ?? '',
                      child: Row(
                        children: [
                          if ((team['logo'] ?? '').toString().isNotEmpty)
                            Image.asset(
                              'assets/teams/${team['logo']}',
                              width: 30,
                              height: 30,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported, size: 30),
                            ),
                          const SizedBox(width: 8),
                          Text(team['name'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  ).toList(),
                  onChanged: (val) => setState(() => selectedTeamB = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Please select Team B' : null,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Match Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : selectedDate!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(fontSize: 10)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              clearControllers();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: addOrUpdateMatch,
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteMatch(String docId) async {
    try {
      await matchesCollection.doc(docId).delete();
      await realtimeDB.child(docId).remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match deleted'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete match: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Matches'),
        backgroundColor: const Color.fromARGB(147, 72, 131, 234),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddEditDialog(),
            tooltip: 'Add Match',
          ),
        ],
      ),
      body: teams.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: matchesCollection.orderBy('matchDate').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final matches = snapshot.data!.docs;
                if (matches.isEmpty) {
                  return const Center(child: Text('No matches found.'));
                }
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    var match = matches[index];
                    var data = match.data() as Map<String, dynamic>;
                    DateTime date = (data['matchDate'] as Timestamp).toDate();

                    final teamALogo = getTeamLogo(data['teamA'] ?? '');
                    final teamBLogo = getTeamLogo(data['teamB'] ?? '');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (teamALogo != null)
                              Image.asset(
                                teamALogo,
                                width: 40,
                                height: 40,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            else
                              const Icon(Icons.sports_soccer, size: 40),
                            const SizedBox(width: 8),
                            Text(data['teamA'] ?? 'Unknown'),
                          ],
                        ),
                        title: const Text('vs', textAlign: TextAlign.center),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(data['teamB'] ?? 'Unknown'),
                            const SizedBox(width: 8),
                            if (teamBLogo != null)
                              Image.asset(
                                teamBLogo,
                                width: 40,
                                height: 40,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            else
                              const Icon(Icons.sports_soccer, size: 40),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Color.fromARGB(255, 54, 136, 244)),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this match?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        deleteMatch(match.id);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Date: ${date.toLocal().toString().split('')[0]}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        isThreeLine: true,
                        onTap: () => showAddEditDialog(doc: match),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
