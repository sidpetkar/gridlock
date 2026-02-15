import 'board_engine.dart';

class ScoreBoard {
  const ScoreBoard({required this.playerA, required this.playerB});

  final double playerA;
  final double playerB;
}

class ScoringEngine {
  ScoreBoard calculate(BoardState board) {
    double a = 0;
    double b = 0;

    for (final BoardCell cell in board.cells.values) {
      if (cell.owners.isEmpty) {
        continue;
      }
      final double share = 1 / cell.owners.length;
      if (cell.owners.contains(PlayerId.a)) {
        a += share;
      }
      if (cell.owners.contains(PlayerId.b)) {
        b += share;
      }
    }

    return ScoreBoard(playerA: a, playerB: b);
  }
}
