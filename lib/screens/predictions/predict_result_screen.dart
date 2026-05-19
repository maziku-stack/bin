import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManagePredictions extends StatefulWidget {
  const ManagePredictions({Key? key}) : super(key: key);

  @override
  State<ManagePredictions> createState() => _ManagePredictionsState();
}

class _ManagePredictionsState extends State<ManagePredictions> {
  final CollectionReference predictionsCollection =
      FirebaseFirestore.instance.collection('predictions');

  Future<void> deletePrediction(String docId) async {
    try {
      await predictionsCollection.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prediction deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete prediction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Predictions'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: predictionsCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading predictions'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final predictions = snapshot.data!.docs;

          if (predictions.isEmpty) {
            return const Center(child: Text('No predictions found.'));
          }

          return ListView.builder(
            itemCount: predictions.length,
            itemBuilder: (context, index) {
              var pred = predictions[index];
              var data = pred.data() as Map<String, dynamic>;

              final teamA = data['teamA'] ?? 'Team A';
              final teamB = data['teamB'] ?? 'Team B';
              final prediction = data['prediction'] ?? 'Unknown';
              final confidence = data['confidence'] ?? 'N/A';
              final userId = data['userId'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('$teamA vs $teamB'),
                  subtitle: Text(
                    'Prediction: $prediction\n'
                    'Confidence: $confidence\n'
                    'By: $userId',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromARGB(255, 54, 165, 244)),
                    onPressed: () => deletePrediction(pred.id),
                    tooltip: 'Delete Prediction',
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
