import 'package:flutter_test/flutter_test.dart';
import 'package:gridlock/features/game/domain/board_engine.dart';

void main() {
  group('BoardEngine', () {
    test('places first word horizontally and updates bounds', () {
      final BoardEngine engine = BoardEngine();
      final BoardState result = engine.placeWord(
        board: BoardState.empty(),
        word: 'ELEPHANT',
        start: const Position(0, 0),
        direction: Direction.horizontal,
        player: PlayerId.a,
      );

      expect(result.width, 8);
      expect(result.height, 1);
      expect(result.cells[const Position(0, 0)]?.letter, 'E');
      expect(result.cells[const Position(7, 0)]?.letter, 'T');
    });

    test('shared intersection keeps both owners', () {
      final BoardEngine engine = BoardEngine();
      BoardState board = engine.placeWord(
        board: BoardState.empty(),
        word: 'ELEPHANT',
        start: const Position(0, 0),
        direction: Direction.horizontal,
        player: PlayerId.a,
      );
      board = engine.placeWord(
        board: board,
        word: 'ECLIPSE',
        start: const Position(0, 0),
        direction: Direction.vertical,
        player: PlayerId.b,
      );

      final BoardCell? shared = board.cells[const Position(0, 0)];
      expect(shared, isNotNull);
      expect(shared!.owners.length, 2);
      expect(shared.owners.contains(PlayerId.a), isTrue);
      expect(shared.owners.contains(PlayerId.b), isTrue);
    });
  });
}
