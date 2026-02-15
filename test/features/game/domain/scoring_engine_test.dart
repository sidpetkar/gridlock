import 'package:flutter_test/flutter_test.dart';
import 'package:gridlock/features/game/domain/board_engine.dart';
import 'package:gridlock/features/game/domain/scoring_engine.dart';

void main() {
  test('splits score for shared cells', () {
    final BoardEngine engine = BoardEngine();
    final ScoringEngine scoring = ScoringEngine();
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

    final ScoreBoard score = scoring.calculate(board);

    expect(score.playerA, 7.5);
    expect(score.playerB, 6.5);
  });
}
