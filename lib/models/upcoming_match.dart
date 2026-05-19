import 'package:cloud_firestore/cloud_firestore.dart';

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
    final data = doc.data()! as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name']?.toString() ?? 'Team ${doc.id}',
      location: data['location']?.toString() ?? '',
      manager: data['manager']?.toString() ?? '',
      founded: (data['founded'] as int?) ?? 0,
      logoUrl: data['logoUrl']?.toString() ?? '',
    );
  }
}