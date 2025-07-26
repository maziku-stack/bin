import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esportapp/models/up_provider.dart';
import 'package:flutter/material.dart';
// Add this
import 'package:provider/provider.dart'; // Add this

class ManageTeams extends StatefulWidget {
  const ManageTeams({Key? key}) : super(key: key);

  @override
  State<ManageTeams> createState() => _ManageTeamsState();
}

class _ManageTeamsState extends State<ManageTeams> {
  final CollectionReference teamsCollection =
      FirebaseFirestore.instance.collection('teams');

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _foundedController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();

  bool isEditing = false;
  String? editingDocId;

  void clearControllers() {
    _nameController.clear();
    _foundedController.clear();
    _managerController.clear();
    _logoUrlController.clear();
  }

  Future<void> addOrUpdateTeam() async {
    if (!_formKey.currentState!.validate()) return;

    String name = _nameController.text.trim();
    int founded = int.parse(_foundedController.text.trim());
    String manager = _managerController.text.trim();
    String logoFileName = _logoUrlController.text.trim();

    final data = {
      'name': name,
      'founded': founded,
      'manager': manager,
      'logoUrl': logoFileName,
    };

    try {
      if (isEditing && editingDocId != null) {
        await teamsCollection.doc(editingDocId).update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team updated successfully!')),
        );
      } else {
        await teamsCollection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team added successfully!')),
        );
      }

      // Refresh team provider after update
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      teamProvider.refreshTeams();

      clearControllers();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed: ${e.toString()}')),
      );
    }
  }

  void showAddEditDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      isEditing = true;
      editingDocId = doc.id;
      var data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _foundedController.text = data['founded']?.toString() ?? '';
      _managerController.text = data['manager'] ?? '';
      _logoUrlController.text = data['logoUrl'] ?? '';
    } else {
      isEditing = false;
      editingDocId = null;
      clearControllers();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Team' : 'Add New Team'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Team Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter team name' : null,
                ),
                TextFormField(
                  controller: _foundedController,
                  decoration: const InputDecoration(labelText: 'Founded Year'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter founded year';
                    }
                    if (int.tryParse(val) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _managerController,
                  decoration: const InputDecoration(labelText: 'Manager'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter manager name' : null,
                ),
                TextFormField(
                  controller: _logoUrlController,
                  decoration: const InputDecoration(
                      labelText: 'Logo File Name (e.g. chelsea.png)'),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Enter logo file name'
                      : null,
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
            onPressed: addOrUpdateTeam,
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTeam(String docId) async {
    try {
      await teamsCollection.doc(docId).delete();
      
      // Refresh team provider after deletion
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      teamProvider.refreshTeams();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team deleted'),
          backgroundColor: Color.fromARGB(255, 105, 180, 224),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete team: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
        backgroundColor: const Color.fromARGB(221, 93, 179, 248),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddEditDialog(),
            tooltip: 'Add Team',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teamsCollection.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data!.docs;

          if (teams.isEmpty) {
            return const Center(child: Text('No teams found.'));
          }

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              var team = teams[index];
              var data = team.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['logoUrl'] != null &&
                          data['logoUrl'].toString().isNotEmpty
                      ? CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/teams/${data['logoUrl']}'),
                          backgroundColor: Colors.transparent,
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.image_not_supported),
                        ),
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Text(
                      'Founded: ${data['founded']?.toString() ?? 'N/A'}\nManager: ${data['manager'] ?? 'N/A'}'),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 12,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showAddEditDialog(doc: team),
                        tooltip: 'Edit Team',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteTeam(team.id),
                        tooltip: 'Delete Team',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}