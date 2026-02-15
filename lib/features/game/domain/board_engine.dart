enum PlayerId { a, b }

enum Direction { horizontal, vertical }

class Position {
  const Position(this.x, this.y);

  final int x;
  final int y;

  Position next(Direction direction) {
    if (direction == Direction.horizontal) {
      return Position(x + 1, y);
    }
    return Position(x, y + 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class BoardCell {
  const BoardCell({required this.letter, required this.owners});

  final String letter;
  final Set<PlayerId> owners;

  BoardCell copyWith({String? letter, Set<PlayerId>? owners}) {
    return BoardCell(
      letter: letter ?? this.letter,
      owners: owners ?? this.owners,
    );
  }
}

class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.start,
    required this.direction,
    required this.player,
    required this.positions,
  });

  final String word;
  final Position start;
  final Direction direction;
  final PlayerId player;
  final List<Position> positions;
}

class BoardState {
  const BoardState({
    required this.cells,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.history,
  });

  factory BoardState.empty() {
    return const BoardState(
      cells: {},
      minX: 0,
      maxX: 0,
      minY: 0,
      maxY: 0,
      history: [],
    );
  }

  final Map<Position, BoardCell> cells;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  final List<PlacedWord> history;

  bool get isEmpty => cells.isEmpty;

  int get width => (maxX - minX) + 1;
  int get height => (maxY - minY) + 1;
}

class BoardEngine {
  BoardState placeWord({
    required BoardState board,
    required String word,
    required Position start,
    required Direction direction,
    required PlayerId player,
  }) {
    final Map<Position, BoardCell> nextCells = Map<Position, BoardCell>.from(
      board.cells,
    );
    final List<Position> positions = _positionsForWord(
      word: word,
      start: start,
      direction: direction,
    );

    int minX = board.isEmpty ? start.x : board.minX;
    int maxX = board.isEmpty ? start.x : board.maxX;
    int minY = board.isEmpty ? start.y : board.minY;
    int maxY = board.isEmpty ? start.y : board.maxY;

    for (int i = 0; i < positions.length; i++) {
      final Position position = positions[i];
      final String letter = word[i];
      final BoardCell? existing = nextCells[position];

      if (existing == null) {
        nextCells[position] = BoardCell(letter: letter, owners: {player});
      } else {
        final Set<PlayerId> updatedOwners = Set<PlayerId>.from(existing.owners)
          ..add(player);
        nextCells[position] = existing.copyWith(owners: updatedOwners);
      }

      minX = position.x < minX ? position.x : minX;
      maxX = position.x > maxX ? position.x : maxX;
      minY = position.y < minY ? position.y : minY;
      maxY = position.y > maxY ? position.y : maxY;
    }

    final List<PlacedWord> history = List<PlacedWord>.from(board.history)
      ..add(
        PlacedWord(
          word: word,
          start: start,
          direction: direction,
          player: player,
          positions: positions,
        ),
      );

    return BoardState(
      cells: nextCells,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      history: history,
    );
  }

  List<Position> _positionsForWord({
    required String word,
    required Position start,
    required Direction direction,
  }) {
    final List<Position> positions = <Position>[];
    Position cursor = start;
    for (int i = 0; i < word.length; i++) {
      positions.add(cursor);
      cursor = cursor.next(direction);
    }
    return positions;
  }
}
