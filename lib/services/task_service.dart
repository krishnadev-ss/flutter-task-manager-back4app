import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/task_model.dart';

/// All Back4App "Task" class CRUD operations.
class TaskService {
  static const String _className = 'Task';

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Fetches all tasks owned by the currently authenticated user.
  ///
  /// Results are ordered by creation date (newest first). An optional
  /// [filterCompleted] restricts results to complete / incomplete tasks.
  Future<List<TaskModel>> getTasks({bool? filterCompleted}) async {
    final ParseUser? user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) throw TaskException('No authenticated user');

    final query = QueryBuilder<ParseObject>(ParseObject(_className))
      ..whereEqualTo('user', user)
      ..orderByDescending('createdAt')
      ..includeObject(['user']);

    if (filterCompleted != null) {
      query.whereEqualTo('isCompleted', filterCompleted);
    }

    final response = await query.query();

    if (response.success) {
      final results = response.results ?? [];
      return results
          .map((e) => TaskModel.fromParseObject(e as ParseObject))
          .toList();
    }

    throw TaskException(_errorFrom(response));
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<TaskModel> createTask(TaskModel task) async {
    final ParseUser? user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) throw TaskException('No authenticated user');

    final parseObject = task.toParseObject(user: user);

    // Restrict read/write to the owner only
    final acl = ParseACL(owner: user);
    acl.setPublicReadAccess(allowed: false);
    acl.setPublicWriteAccess(allowed: false);
    parseObject.setACL(acl);

    final response = await parseObject.save();

    if (response.success && response.result != null) {
      return TaskModel.fromParseObject(response.result as ParseObject);
    }

    throw TaskException(_errorFrom(response));
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<TaskModel> updateTask(TaskModel task) async {
    if (task.objectId == null) {
      throw TaskException('Cannot update a task without an objectId');
    }

    final parseObject = task.toParseObject();
    final response = await parseObject.save();

    if (response.success && response.result != null) {
      return TaskModel.fromParseObject(response.result as ParseObject);
    }

    // Some Parse versions return success without result on PATCH — refetch
    if (response.success) {
      return task; // Return the model we sent; it reflects the intended state
    }

    throw TaskException(_errorFrom(response));
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteTask(String objectId) async {
    final parseObject = ParseObject(_className)..objectId = objectId;
    final response = await parseObject.delete();

    if (!response.success) {
      throw TaskException(_errorFrom(response));
    }
  }

  // ─── Toggle ───────────────────────────────────────────────────────────────

  Future<TaskModel> toggleCompletion(TaskModel task) {
    return updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _errorFrom(ParseResponse response) {
    if (response.error != null) return response.error!.message;
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Thrown by [TaskService] when a Back4App operation fails.
class TaskException implements Exception {
  const TaskException(this.message);

  final String message;

  @override
  String toString() => message;
}
