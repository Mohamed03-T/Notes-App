import 'package:flutter/material.dart';

/// Types of draggable items in the app.
enum DragItemType { folder, note, page }

/// Represents an item being dragged (folder, note, or page).
class DragItem {
  final String id;
  final DragItemType type;

  DragItem({required this.id, required this.type});
}

/// Callback to decide whether a dragged item can be accepted at the target.
typedef WillAcceptCallback = bool Function(DragItem data, DragTargetDetails details);

/// Callback when a dragged item is moved over a target (e.g., for UI feedback).
typedef OnMoveCallback = void Function(DragItem data, DragTargetDetails details);

/// Callback when a dragged item leaves a target without dropping.
typedef OnLeaveCallback = void Function(DragItem data);

/// Callback when a dragged item is dropped on a target.
typedef OnAcceptCallback = void Function(DragItem data, int oldIndex, int newIndex);

/// Manager interface for handling drag & drop events.
abstract class DragDropManager {
  /// Called to check if the target will accept the dragged [data].
  bool onWillAccept(DragItem data, DragTargetDetails details);

  /// Called continuously when a dragged [data] moves over a target.
  void onMove(DragItem data, DragTargetDetails details);

  /// Called when a dragged [data] leaves a target without dropping.
  void onLeave(DragItem data);

  /// Called when a dragged [data] is dropped. Implements reordering or moving logic.
  /// [oldIndex] the original index of the item, [newIndex] the target index.
  Future<void> onAccept(DragItem data, int oldIndex, int newIndex);
}

/// Default manager that dispatches drag-and-drop events to the NotesRepository.
class DefaultDragDropManager implements DragDropManager {

  @override
  bool onWillAccept(DragItem data, DragTargetDetails details) {
    // by default accept any reorder within same type
    return true;
  }

  @override
  void onMove(DragItem data, DragTargetDetails details) {
    // optional: implement hover feedback if needed
  }

  @override
  void onLeave(DragItem data) {
    // optional: handle leave feedback
  }

  @override
  Future<void> onAccept(DragItem data, int oldIndex, int newIndex) {
    // Default implementation not supported; implement per-screen logic
    throw UnimplementedError('Use onReorder in Reorderable widget');
  }
}
