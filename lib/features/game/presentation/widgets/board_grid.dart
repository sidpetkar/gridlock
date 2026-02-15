import 'package:flutter/material.dart';

import '../../application/game_controller.dart' show GamePhase, GridBounds;
import '../../domain/board_engine.dart';

/// Muted pastel palettes that cycle per game round.
/// Each entry: [userColor, botColor, sharedColor].
const List<List<Color>> kColorPalettes = <List<Color>>[
  [Color(0xFFEAE7F2), Color(0xFFD1FAE5), Color(0xFFAEBFC9)], // purple/green
  [Color(0xFFD6EAF8), Color(0xFFFCF3CF), Color(0xFFAEBFC9)], // blue/cream
  [Color(0xFFE8DAEF), Color(0xFFD5F5E3), Color(0xFFAEBFC9)], // lavender/mint
  [Color(0xFFFADBD8), Color(0xFFD4EFDF), Color(0xFFAEBFC9)], // rose/sage
  [Color(0xFFD5F5E3), Color(0xFFFDEBD0), Color(0xFFAEBFC9)], // mint/peach
  [Color(0xFFD6DBDF), Color(0xFFD2B4DE), Color(0xFFAEBFC9)], // silver/orchid
];

class BoardGrid extends StatelessWidget {
  const BoardGrid({
    super.key,
    required this.board,
    required this.selected,
    required this.direction,
    required this.onSelect,
    required this.previewLetters,
    required this.highlightPositions,
    required this.phase,
    required this.onDirectionChosen,
    required this.colorThemeIndex,
    required this.showSelection,
    required this.ghostLetters,
    required this.showDirectionArrows,
    this.gridBounds,
  });

  final BoardState board;
  final Position? selected;
  final Direction direction;
  final ValueChanged<Position> onSelect;
  final Map<Position, String> previewLetters;
  final Map<Position, String> ghostLetters;
  final List<Position> highlightPositions;
  final GamePhase phase;
  final ValueChanged<Direction> onDirectionChosen;
  final int colorThemeIndex;
  final bool showSelection;
  final bool showDirectionArrows;
  final GridBounds? gridBounds;

  @override
  Widget build(BuildContext context) {
    final int minX = _calcMinX();
    final int maxX = _calcMaxX();
    final int minY = _calcMinY();
    final int maxY = _calcMaxY();
    final double width = MediaQuery.of(context).size.width;
    final double cellSize = width < 560 ? 42 : 50;

    final Set<Position> highlightSet = highlightPositions.toSet();
    final List<Color> palette =
        kColorPalettes[colorThemeIndex % kColorPalettes.length];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // ── Grid ──
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int y = minY; y <= maxY; y++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int x = minX; x <= maxX; x++)
                        _GridCell(
                          size: cellSize,
                          position: Position(x, y),
                          cell: board.cells[Position(x, y)],
                          previewLetter: previewLetters[Position(x, y)],
                          ghostLetter: ghostLetters[Position(x, y)],
                          selected:
                              showSelection && selected == Position(x, y),
                          direction: direction,
                          highlight: highlightSet.contains(Position(x, y)),
                          palette: palette,
                          onTap: () => onSelect(Position(x, y)),
                        ),
                    ],
                  ),
              ],
            ),
            // ── Floating direction arrows ──
            if (showDirectionArrows && selected != null)
              ..._buildFloatingArrows(minX, minY, cellSize),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingArrows(int minX, int minY, double cellSize) {
    final Position sel = selected!;
    final double left = (sel.x - minX) * cellSize;
    final double top = (sel.y - minY) * cellSize;
    const double arrowSize = 28;

    return <Widget>[
      // Right arrow → horizontal
      Positioned(
        left: left + cellSize + 4,
        top: top + (cellSize - arrowSize) / 2,
        child: _ArrowButton(
          icon: Icons.arrow_forward,
          size: arrowSize,
          onTap: () => onDirectionChosen(Direction.horizontal),
        ),
      ),
      // Down arrow → vertical
      Positioned(
        left: left + (cellSize - arrowSize) / 2,
        top: top + cellSize + 4,
        child: _ArrowButton(
          icon: Icons.arrow_downward,
          size: arrowSize,
          onTap: () => onDirectionChosen(Direction.vertical),
        ),
      ),
    ];
  }

  // ── Bounds helpers ────────────────────────────────────────────

  int _calcMinX() {
    if (gridBounds != null) {
      return gridBounds!.minX;
    }
    if (board.cells.isEmpty && selected == null && previewLetters.isEmpty) {
      return 0;
    }
    final List<int> v = <int>[
      board.minX,
      selected?.x ?? 0,
      ...previewLetters.keys.map((p) => p.x),
    ];
    return v.reduce((a, b) => a < b ? a : b);
  }

  int _calcMaxX() {
    if (gridBounds != null) {
      return gridBounds!.maxX;
    }
    if (board.cells.isEmpty && selected == null && previewLetters.isEmpty) {
      return 0;
    }
    final List<int> v = <int>[
      board.maxX,
      selected?.x ?? 0,
      ...previewLetters.keys.map((p) => p.x),
    ];
    return v.reduce((a, b) => a > b ? a : b);
  }

  int _calcMinY() {
    if (gridBounds != null) {
      return gridBounds!.minY;
    }
    if (board.cells.isEmpty && selected == null && previewLetters.isEmpty) {
      return 0;
    }
    final List<int> v = <int>[
      board.minY,
      selected?.y ?? 0,
      ...previewLetters.keys.map((p) => p.y),
    ];
    return v.reduce((a, b) => a < b ? a : b);
  }

  int _calcMaxY() {
    if (gridBounds != null) {
      return gridBounds!.maxY;
    }
    if (board.cells.isEmpty && selected == null && previewLetters.isEmpty) {
      return 0;
    }
    final List<int> v = <int>[
      board.maxY,
      selected?.y ?? 0,
      ...previewLetters.keys.map((p) => p.y),
    ];
    return v.reduce((a, b) => a > b ? a : b);
  }
}

// ── Floating arrow button ─────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      color: const Color(0xFF111111),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.6, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Grid cell with finite blink animation ─────────────────────

class _GridCell extends StatefulWidget {
  const _GridCell({
    required this.size,
    required this.position,
    required this.cell,
    required this.previewLetter,
    required this.ghostLetter,
    required this.selected,
    required this.direction,
    required this.highlight,
    required this.palette,
    required this.onTap,
  });

  final double size;
  final Position position;
  final BoardCell? cell;
  final String? previewLetter;
  final String? ghostLetter;
  final bool selected;
  final Direction direction;
  final bool highlight;
  final List<Color> palette; // [userColor, botColor, sharedColor]
  final VoidCallback onTap;

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell>
    with TickerProviderStateMixin {
  AnimationController? _blinkController;
  Animation<double>? _blinkAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.highlight) {
      _startBlink();
    }
  }

  @override
  void didUpdateWidget(covariant _GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !oldWidget.highlight) {
      _startBlink();
    } else if (!widget.highlight && oldWidget.highlight) {
      _stopBlink();
    }
  }

  void _startBlink() {
    _stopBlink();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    // 3 full pulses (down-up) ending at opacity 1.0 – finite, no repeat.
    _blinkAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _blinkController!,
      curve: Curves.easeInOut,
    ));

    // When animation finishes, clean up so the cell renders without opacity.
    _blinkController!.addStatusListener(_onAnimationStatus);
    _blinkController!.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _stopBlink();
        });
      }
    }
  }

  void _stopBlink() {
    _blinkController?.removeStatusListener(_onAnimationStatus);
    _blinkController?.dispose();
    _blinkController = null;
    _blinkAnimation = null;
  }

  @override
  void dispose() {
    _blinkController?.removeStatusListener(_onAnimationStatus);
    _blinkController?.dispose();
    super.dispose();
  }

  Color _cellColor(BoardCell? cell) {
    if (cell == null) {
      return Colors.white;
    }
    if (cell.owners.length > 1) {
      return widget.palette[2]; // shared
    }
    if (cell.owners.contains(PlayerId.a)) {
      return widget.palette[0]; // user
    }
    return widget.palette[1]; // bot
  }

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = BoxDecoration(
      color: _cellColor(widget.cell),
      border: Border.all(
        color: widget.selected
            ? const Color(0xFF111111)
            : const Color(0xFFD1D5DB),
        width: widget.selected ? 1.4 : 1,
      ),
    );

    // Determine what letter/style to show.
    final String displayLetter =
        widget.cell?.letter ?? widget.previewLetter ?? widget.ghostLetter ?? '';
    final bool isGhost =
        widget.cell == null && widget.previewLetter == null && widget.ghostLetter != null;
    final bool isPreview =
        widget.cell == null && widget.previewLetter != null;

    final Widget inner = Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: decoration,
      child: Opacity(
        opacity: isGhost ? 0.28 : 1.0,
        child: Text(
          displayLetter,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isPreview
                ? const Color(0xFF6B7280)
                : const Color(0xFF111111),
          ),
        ),
      ),
    );

    // Only wrap with opacity while the animation is actively running.
    final bool animating = _blinkAnimation != null && _blinkController != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: animating
          ? AnimatedBuilder(
              animation: _blinkAnimation!,
              builder: (_, __) =>
                  Opacity(opacity: _blinkAnimation!.value, child: inner),
            )
          : inner,
    );
  }
}
