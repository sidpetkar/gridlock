import 'board_engine.dart';
import '../application/game_controller.dart' show GridBounds;

class MoveValidationResult {
  const MoveValidationResult({
    required this.isValid,
    required this.error,
    required this.intersections,
    required this.newCells,
  });

  factory MoveValidationResult.valid({
    required int intersections,
    required int newCells,
  }) {
    return MoveValidationResult(
      isValid: true,
      error: null,
      intersections: intersections,
      newCells: newCells,
    );
  }

  factory MoveValidationResult.invalid(String error) {
    return MoveValidationResult(
      isValid: false,
      error: error,
      intersections: 0,
      newCells: 0,
    );
  }

  final bool isValid;
  final String? error;
  final int intersections;
  final int newCells;
}

class MoveValidator {
  MoveValidationResult validatePlacement({
    required BoardState board,
    required String word,
    required Position start,
    required Direction direction,
    required bool requireIntersection,
    GridBounds? bounds,
  }) {
    if (word.trim().isEmpty) {
      return MoveValidationResult.invalid('Enter a word.');
    }

    if (word.length < 3) {
      return MoveValidationResult.invalid('Word must be at least 3 letters.');
    }

    final String normalized = _normalize(word);
    if (normalized.length != word.length) {
      return MoveValidationResult.invalid(
        'Only alphabetic letters are allowed.',
      );
    }

    // Check every position fits within locked grid bounds.
    if (bounds != null) {
      Position boundsCheck = start;
      for (int i = 0; i < normalized.length; i++) {
        if (!bounds.containsPosition(boundsCheck)) {
          return MoveValidationResult.invalid(
            'Word extends outside the grid boundary.',
          );
        }
        boundsCheck = boundsCheck.next(direction);
      }
    }

    int intersections = 0;
    int newCells = 0;
    Position cursor = start;

    for (int i = 0; i < normalized.length; i++) {
      final BoardCell? existing = board.cells[cursor];
      final String nextLetter = normalized[i];

      if (existing != null) {
        if (existing.letter != nextLetter) {
          return MoveValidationResult.invalid('Letter conflict on the board.');
        }
        intersections++;
      } else {
        newCells++;
      }

      cursor = cursor.next(direction);
    }

    if (newCells == 0) {
      return MoveValidationResult.invalid(
        'Move must add at least one new letter.',
      );
    }

    if (requireIntersection && intersections == 0) {
      return MoveValidationResult.invalid(
        'Word must intersect existing letters.',
      );
    }

    // ── Duplicate word check ──
    // Reject if the exact same word string was already placed.
    for (final PlacedWord placed in board.history) {
      if (placed.word == normalized) {
        return MoveValidationResult.invalid(
          'Word "$normalized" has already been played.',
        );
      }
    }

    // ── Trivial extension check ──
    // Reject if the new word's positions are a superset or subset of an
    // existing word in the same direction (e.g. DUCK → DUCKS or DUCKS → DUCK).
    final Set<Position> newPositions = <Position>{};
    Position posBuilder = start;
    for (int i = 0; i < normalized.length; i++) {
      newPositions.add(posBuilder);
      posBuilder = posBuilder.next(direction);
    }

    for (final PlacedWord placed in board.history) {
      if (placed.direction != direction) {
        continue;
      }
      final Set<Position> existingPositions = placed.positions.toSet();

      // New word contains all cells of an existing word (superset).
      if (existingPositions.every((p) => newPositions.contains(p))) {
        return MoveValidationResult.invalid(
          'Word is a trivial extension of "${placed.word}".',
        );
      }
      // Existing word contains all cells of the new word (subset).
      if (newPositions.every((p) => existingPositions.contains(p))) {
        return MoveValidationResult.invalid(
          'Word is already covered by "${placed.word}".',
        );
      }
    }

    return MoveValidationResult.valid(
      intersections: intersections,
      newCells: newCells,
    );
  }

  String _normalize(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  }
}
