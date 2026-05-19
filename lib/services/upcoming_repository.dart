import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esportapp/models/up.dart';

class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Team> _teamsCache = {};
  DateTime? _lastFetchTime;
  static const Duration cacheDuration = Duration(minutes: 30);

  Future<Map<String, Team>> getTeams({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cache if still valid
    if (!forceRefresh && 
        _lastFetchTime != null && 
        now.difference(_lastFetchTime!) < cacheDuration) {
      return _teamsCache;
    }

    try {
      final snapshot = await _firestore.collection('teams').get();
      _teamsCache.clear();
      
      for (final doc in snapshot.docs) {
        final team = Team.fromFirestore(doc);
        _teamsCache[doc.id] = team;
      }
      
      _lastFetchTime = now;
      return _teamsCache;
    } catch (e) {
      // Return cache even if stale when network fails
      if (_teamsCache.isNotEmpty) return _teamsCache;
      rethrow;
    }
  }

  Future<Team?> getTeamById(String id) async {
    if (_teamsCache.containsKey(id)) {
      return _teamsCache[id];
    }
    
    try {
      final doc = await _firestore.collection('teams').doc(id).get();
      if (!doc.exists) return null;
      
      final team = Team.fromFirestore(doc);
      _teamsCache[id] = team;
      return team;
    } catch (e) {
      return null;
    }
  }

  Stream<Map<String, Team>> teamsStream() {
    return _firestore.collection('teams').snapshots().map((snapshot) {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added || 
            doc.type == DocumentChangeType.modified) {
          _teamsCache[doc.doc.id] = Team.fromFirestore(doc.doc);
        } else if (doc.type == DocumentChangeType.removed) {
          _teamsCache.remove(doc.doc.id);
        }
      }
      _lastFetchTime = DateTime.now();
      return Map<String, Team>.from(_teamsCache);
    });
  }
}