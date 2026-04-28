import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';

enum TaskStatus { initial, loading, loaded, error }

/// Active filter applied to the task list in the dashboard.
enum TaskFilter { all, active, completed }

/// Manages the task list state and exposes filtered / searched views.
class TaskProvider extends ChangeNotifier {
  TaskProvider() : _taskService = TaskService();

  final TaskService _taskService;

  List<TaskModel> _allTasks = [];
  TaskStatus _status = TaskStatus.initial;
  String? _errorMessage;
  String _searchQuery = '';
  TaskFilter _filter = TaskFilter.all;

  // ─── Getters ──────────────────────────────────────────────────────────────

  /// The subset of tasks that matches the current filter + search query.
  List<TaskModel> get tasks => _computeFilteredTasks();

  /// The total number of tasks without any filter (used for badge counts).
  int get totalCount => _allTasks.length;
  int get activeCount => _allTasks.where((t) => !t.isCompleted).length;
  int get completedCount => _allTasks.where((t) => t.isCompleted).length;

  TaskStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TaskFilter get filter => _filter;
  bool get isLoading => _status == TaskStatus.loading;

  // ─── Called by the ProxyProvider when auth user changes ──────────────────

  void updateUser(UserModel? user) {
    if (user == null) {
      _allTasks = [];
      _status = TaskStatus.initial;
      _searchQuery = '';
      _filter = TaskFilter.all;
      notifyListeners();
    }
  }

  // ─── Data operations ──────────────────────────────────────────────────────

  /// Loads all tasks from Back4App for the authenticated user.
  Future<void> loadTasks({bool silent = false}) async {
    if (!silent) {
      _status = TaskStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _allTasks = await _taskService.getTasks();
      _status = TaskStatus.loaded;
      _errorMessage = null;
    } on TaskException catch (e) {
      _errorMessage = e.message;
      _status = TaskStatus.error;
    } catch (_) {
      _errorMessage = 'Failed to load tasks. Check your connection.';
      _status = TaskStatus.error;
    }

    notifyListeners();
  }

  /// Creates a new task and prepends it to the local list.
  Future<bool> createTask(TaskModel task) async {
    try {
      final created = await _taskService.createTask(task);
      _allTasks.insert(0, created);
      _status = TaskStatus.loaded;
      notifyListeners();
      return true;
    } on TaskException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to create task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing task in Back4App and in the local list.
  Future<bool> updateTask(TaskModel task) async {
    try {
      final updated = await _taskService.updateTask(task);
      _replaceTask(updated);
      notifyListeners();
      return true;
    } on TaskException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Deletes a task from Back4App and removes it from the local list.
  Future<bool> deleteTask(String objectId) async {
    try {
      await _taskService.deleteTask(objectId);
      _allTasks.removeWhere((t) => t.objectId == objectId);
      notifyListeners();
      return true;
    } on TaskException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Optimistically toggles completion, then syncs with Back4App.
  /// Reverts on failure to keep UI consistent.
  Future<void> toggleCompletion(TaskModel task) async {
    // Optimistic local update
    _replaceTask(task.copyWith(isCompleted: !task.isCompleted));
    notifyListeners();

    try {
      final updated = await _taskService.toggleCompletion(task);
      _replaceTask(updated);
      notifyListeners();
    } catch (_) {
      // Revert on failure
      _replaceTask(task);
      _errorMessage = 'Failed to update task status.';
      notifyListeners();
    }
  }

  // ─── Filter / search ──────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    if (_filter != filter) {
      _filter = filter;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  List<TaskModel> _computeFilteredTasks() {
    var result = List<TaskModel>.from(_allTasks);

    // Completion filter
    switch (_filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        break;
    }

    // Search filter (case-insensitive, matches title + description)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  void _replaceTask(TaskModel updated) {
    final index = _allTasks.indexWhere((t) => t.objectId == updated.objectId);
    if (index != -1) _allTasks[index] = updated;
  }
}
