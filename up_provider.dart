import 'package:flutter/material.dart';
import 'package:esportapp/models/up_repose.dart';
import 'package:esportapp/models/up.dart';

class TeamProvider with ChangeNotifier {
  final TeamRepository _repository = TeamRepository();
  Map<String, Team> _teams = {};
  bool _isLoading = false;
  String? _error;

  Map<String, Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTeams() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _teams = await _repository.getTeams();
      _error = null;
    } catch (e) {
      _error = "Failed to load teams: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTeams() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _teams = await _repository.getTeams(forceRefresh: true);
      _error = null;
    } catch (e) {
      _error = "Refresh failed: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Team? getTeam(String? id) {
    if (id == null || id.isEmpty) return null;
    return _teams[id];
  }

  String getTeamName(String? id) {
    return getTeam(id)?.name ?? 'Team ${id ?? 'Unknown'}';
  }

  String getTeamLogo(String? id) {
    return getTeam(id)?.logoUrl ?? '';
  }
}