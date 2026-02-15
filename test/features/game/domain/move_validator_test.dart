import 'package:flutter_test/flutter_test.dart';
import 'package:gridlock/features/game/domain/board_engine.dart';
import 'package:gridlock/features/game/domain/move_validator.dart';

void main() {
  group('MoveValidator', () {
    test('rejects non-intersecting move when intersection is required', () {
      final BoardEngine engine = BoardEngine();
      final MoveValidator validator = MoveValidator();
      final BoardState board = engine.placeWord(
        board: BoardState.empty(),
        word: 'ELEPHANT',
        start: const Position(0, 0),
        direction: Direction.horizontal,
        player: PlayerId.a,
      );

      final MoveValidationResult result = validator.validatePlacement(
        board: board,
        word: 'RIVER',
        start: const Position(10, 10),
        direction: Direction.horizontal,
        requireIntersection: true,
      );

      expect(result.isValid, isFalse);
    });

    test('accepts intersecting move with matching letter', () {
      final BoardEngine engine = BoardEngine();
      final MoveValidator validator = MoveValidator();
      final BoardState board = engine.placeWord(
        board: BoardState.empty(),
        word: 'ELEPHANT',
        start: const Position(0, 0),
        direction: Direction.horizontal,
        player: PlayerId.a,
      );

      final MoveValidationResult result = validator.validatePlacement(
        board: board,
        word: 'ECLIPSE',
        start: const Position(0, 0),
        direction: Direction.vertical,
        requireIntersection: true,
      );

      expect(result.isValid, isTrue);
      expect(result.intersections, 1);
    });
  });
}
