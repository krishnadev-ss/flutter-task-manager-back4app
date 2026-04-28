import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Domain model that maps to the Back4App "Task" Parse class.
class TaskModel {
  final String? objectId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskModel({
    this.objectId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns a copy of this model with the given fields replaced.
  TaskModel copyWith({
    String? objectId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      objectId: objectId ?? this.objectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Parse serialization ──────────────────────────────────────────────────

  /// Build a [TaskModel] from a [ParseObject] returned by Back4App.
  factory TaskModel.fromParseObject(ParseObject obj) {
    return TaskModel(
      objectId: obj.objectId,
      title: obj.get<String>('title') ?? '',
      description: obj.get<String>('description') ?? '',
      isCompleted: obj.get<bool>('isCompleted') ?? false,
      dueDate: obj.get<DateTime>('dueDate'),
      createdAt: obj.createdAt,
      updatedAt: obj.updatedAt,
    );
  }

  /// Convert this model to a [ParseObject] ready to be saved to Back4App.
  ///
  /// [user] is required when creating a new task so we can set the ACL owner
  /// and the "user" pointer field.
  ParseObject toParseObject({ParseUser? user}) {
    final object = ParseObject('Task');

    // Set objectId only when updating an existing record
    if (objectId != null) object.objectId = objectId;

    object
      ..set<String>('title', title)
      ..set<String>('description', description)
      ..set<bool>('isCompleted', isCompleted);

    if (dueDate != null) {
      object.set<DateTime>('dueDate', dueDate!);
    } else if (objectId != null) {
      // Setting to null tells Parse Server to remove a previously stored date
      object.set('dueDate', null);
    }

    // Attach owner pointer for new tasks
    if (user != null) {
      object.set<ParseUser>('user', user);
    }

    return object;
  }
}
