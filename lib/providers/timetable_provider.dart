import 'package:flutter/material.dart';
import '../models/timetable.dart';
import '../models/class_session.dart';
import '../services/storage_service.dart';

class TimetableProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<Timetable> _timetables = [];
  String? _activeTimetableId;

  TimetableProvider(this._storageService, {String? initialActiveId}) {
    _timetables = _storageService.loadTimetables();
    _activeTimetableId = initialActiveId;

    if (_activeTimetableId == null || !timetables.any((t) => t.id == _activeTimetableId && !t.isArchived)) {
      final firstActive = _timetables.where((t) => !t.isArchived).toList();
      if (firstActive.isNotEmpty) {
        _activeTimetableId = firstActive.first.id;
      } else if (_timetables.isNotEmpty) {
        _activeTimetableId = _timetables.first.id;
      }
    }
  }

  List<Timetable> get timetables => List.unmodifiable(_timetables);

  List<Timetable> get activeTimetables => _timetables.where((t) => !t.isArchived).toList();

  List<Timetable> get archivedTimetables => _timetables.where((t) => t.isArchived).toList();

  String? get activeTimetableId => _activeTimetableId;

  Timetable? get activeTimetable {
    if (_activeTimetableId == null) return null;
    try {
      return _timetables.firstWhere((t) => t.id == _activeTimetableId);
    } catch (_) {
      return _timetables.isNotEmpty ? _timetables.first : null;
    }
  }

  void setActiveTimetable(String timetableId) {
    if (_activeTimetableId != timetableId) {
      _activeTimetableId = timetableId;
      notifyListeners();
    }
  }

  /// Create a new timetable with user custom name
  Future<Timetable> createTimetable(String name) async {
    final newTt = Timetable(
      id: 'tt_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'College Routine' : name.trim(),
      isArchived: false,
      createdAt: DateTime.now(),
      sessions: [],
    );
    _timetables.add(newTt);
    _activeTimetableId = newTt.id;
    notifyListeners();
    await _storageService.saveTimetables(_timetables);
    return newTt;
  }

  /// Rename an existing timetable
  Future<void> renameTimetable(String id, String newName) async {
    final idx = _timetables.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _timetables[idx] = _timetables[idx].copyWith(name: newName);
      notifyListeners();
      await _storageService.saveTimetables(_timetables);
    }
  }

  /// Archive a timetable (e.g. past semester) without deleting its historical logs
  Future<void> archiveTimetable(String id) async {
    final idx = _timetables.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _timetables[idx] = _timetables[idx].copyWith(isArchived: true);
      // Switch active if this was active
      if (_activeTimetableId == id) {
        final remaining = activeTimetables;
        _activeTimetableId = remaining.isNotEmpty ? remaining.first.id : null;
      }
      notifyListeners();
      await _storageService.saveTimetables(_timetables);
    }
  }

  /// Unarchive an archived timetable
  Future<void> unarchiveTimetable(String id) async {
    final idx = _timetables.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _timetables[idx] = _timetables[idx].copyWith(isArchived: false);
      _activeTimetableId ??= id;
      notifyListeners();
      await _storageService.saveTimetables(_timetables);
    }
  }

  /// Delete a timetable entirely
  Future<void> deleteTimetable(String id) async {
    _timetables.removeWhere((t) => t.id == id);
    if (_activeTimetableId == id) {
      final remaining = activeTimetables;
      _activeTimetableId = remaining.isNotEmpty ? remaining.first.id : null;
    }
    notifyListeners();
    await _storageService.saveTimetables(_timetables);
  }

  // --- Class Sessions inside Active Timetable ---

  List<ClassSession> getSessionsForDay(int dayOfWeek) {
    final current = activeTimetable;
    if (current == null) return [];
    final sessions = current.sessions.where((s) => s.dayOfWeek == dayOfWeek).toList();
    // Sort chronologically
    sessions.sort((a, b) {
      final cmp = a.startHour.compareTo(b.startHour);
      if (cmp != 0) return cmp;
      return a.startMinute.compareTo(b.startMinute);
    });
    return sessions;
  }

  List<String> getUniqueSubjects() {
    final current = activeTimetable;
    if (current == null) return [];
    return current.sessions.map((s) => s.subject.trim()).toSet().toList()..sort();
  }

  Future<void> addClassSession(ClassSession session) async {
    final current = activeTimetable;
    if (current == null) return;

    final updatedSessions = List<ClassSession>.from(current.sessions)..add(session);
    final idx = _timetables.indexWhere((t) => t.id == current.id);
    if (idx != -1) {
      _timetables[idx] = current.copyWith(sessions: updatedSessions);
      notifyListeners();
      await _storageService.saveTimetables(_timetables);
    }
  }

  Future<void> updateClassSession(ClassSession updatedSession) async {
    final current = activeTimetable;
    if (current == null) return;

    final updatedSessions = current.sessions.map((s) {
      return s.id == updatedSession.id ? updatedSession : s;
    }).toList();

    final idx = _timetables.indexWhere((t) => t.id == current.id);
    if (idx != -1) {
      _timetables[idx] = current.copyWith(sessions: updatedSessions);
      notifyListeners();
      await _storageService.saveTimetables(_timetables);
    }
  }

  Future<void> deleteClassSession(String sessionId) async {
    final current = activeTimetable;
    if (current == null) return;

    final updatedSessions = current.sessions.where((s) => s.id != sessionId).toList();
    final idx = _timetables.indexWhere((t) => t.id == current.id);
    if (idx != -1) {
      _timetables[idx] = current.copyWith(sessions: updatedSessions);
      notifyListeners();
      await _storageService.saveTimetables(_timetables);
    }
  }

  /// Bulk replace all timetables (for backup restore)
  Future<void> replaceAll(List<Timetable> newTimetables) async {
    _timetables = List.from(newTimetables);
    if (!timetables.any((t) => t.id == _activeTimetableId && !t.isArchived)) {
      final active = activeTimetables;
      _activeTimetableId = active.isNotEmpty ? active.first.id : null;
    }
    notifyListeners();
    await _storageService.saveTimetables(_timetables);
  }
}
