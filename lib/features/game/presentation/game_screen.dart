import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/sound_service.dart';
import '../application/game_controller.dart';
import '../domain/board_engine.dart';
import '../domain/scoring_engine.dart';
import 'home_screen.dart';
import 'widgets/board_grid.dart';
// import 'widgets/timer_bar.dart'; // TODO: re-enable for timed mode
import 'widgets/word_input_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late final FocusNode _inputFocusNode;
  late final AnimationController _sheetAnimController;

  @override
  void initState() {
    super.initState();
    _inputFocusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _sheetAnimController.dispose();
    super.dispose();
  }

  /// Intercepts keyboard events on the input FocusNode to handle arrow-key
  /// grid navigation, direction selection, and Enter-while-arrows-showing.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final GameState state = ref.read(gameControllerProvider);
    final GameController controller =
        ref.read(gameControllerProvider.notifier);

    // ── State 1: Direction arrows showing ──
    if (state.showDirectionArrows) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        controller.chooseDirection(Direction.horizontal);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        controller.chooseDirection(Direction.vertical);
        return KeyEventResult.handled;
      }
      // Block other arrow keys and Enter while choosing direction.
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        return KeyEventResult.handled;
      }
      // Let letter keys through to the text field.
      return KeyEventResult.ignored;
    }

    // ── State 2: No draft word → arrow keys navigate grid ──
    if (state.draftWord.isEmpty && state.phase == GamePhase.playing) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        controller.moveSelectionByArrow(1, 0);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        controller.moveSelectionByArrow(-1, 0);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        controller.moveSelectionByArrow(0, 1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        controller.moveSelectionByArrow(0, -1);
        return KeyEventResult.handled;
      }
    }

    // ── State 3: Typing word → let text field handle everything ──
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = ref.watch(gameControllerProvider);
    final GameController controller =
        ref.read(gameControllerProvider.notifier);
    final ScoreBoard scores = controller.scores;
    final Map<Position, String> previewLetters =
        controller.draftPreviewLetters;
    final bool wide = MediaQuery.of(context).size.width >= 980;

    final bool showSel = controller.isHumanInputEnabled;

    // ── Visual cursor: advances as user types ──
    // Only advance after direction has been chosen (arrows hidden).
    Position? visualCursor = state.selectedPosition;
    if (state.draftWord.isNotEmpty &&
        !state.showDirectionArrows &&
        visualCursor != null) {
      Position cursor = visualCursor;
      for (int i = 0; i < state.draftWord.length; i++) {
        cursor = cursor.next(state.direction);
      }
      visualCursor = cursor;
    }

    final Widget board = BoardGrid(
      board: state.board,
      selected: visualCursor,
      direction: state.direction,
      onSelect: (Position pos) {
        controller.selectPosition(pos);
        // On mobile during seed phases: open keyboard directly (no direction needed)
        if (!wide &&
            (state.phase == GamePhase.seedA ||
                state.phase == GamePhase.seedB)) {
          _showKeyboardSheet(context, controller);
        }
      },
      previewLetters: previewLetters,
      ghostLetters: state.ghostHintLetters,
      gridBounds: state.gridBounds,
      highlightPositions: state.lastBotMovePositions,
      phase: state.phase,
      onDirectionChosen: (Direction dir) {
        controller.chooseDirection(dir);
        if (wide) {
          _inputFocusNode.requestFocus();
        } else {
          // Direction chosen → NOW open keyboard
          _showKeyboardSheet(context, controller);
        }
      },
      colorThemeIndex: state.colorThemeIndex,
      showSelection: showSel,
      showDirectionArrows: state.showDirectionArrows,
      isMobile: !wide,
    );

    // Wrap board with game-over overlay when finished.
    final Widget boardArea = Stack(
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.clearSelection,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(wide ? 12 : 0),
            child: board,
          ),
        ),
        if (state.phase == GamePhase.finished)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.85),
              child: Center(
                child: _GameOverCard(
                  message: state.message,
                  scores: scores,
                  opponentType: state.opponentType,
                  onRestart: controller.resetGame,
                ),
              ),
            ),
          ),
      ],
    );

    // ── Moves history (inline, scrollable with bottom fade) ──
    final Widget movesSection = _InlineMoveHistory(
      history: state.board.history,
      opponentType: state.opponentType,
    );

    // ── Controls ──
    final Widget controlsSection = WordInputPanel(
      phase: state.phase,
      onSubmit: (word) async => controller.submitWord(word),
      onChanged: controller.updateDraftWord,
      onPass: () async => controller.passTurn(),
      onOfflineHint: () {
        final String? hint = controller.showGhostHintOnGrid();
        if (hint == null) {
          _showInfo(context, 'No ghost hint found at this position.');
        }
      },
      onAiHint: () async {
        final String? hint = await controller.requestAiHint();
        if (!context.mounted) {
          return;
        }
        _showInfo(
          context,
          hint == null
              ? 'AI hint unavailable. Add GEMINI_API_KEY to enable.'
              : 'AI hint: $hint',
        );
      },
      isAiThinking: state.isAiThinking,
      liveValidationMessage: state.liveValidationMessage,
      inputNonce: state.inputNonce,
      isInputEnabled: controller.isHumanInputEnabled,
      inputFocusNode: _inputFocusNode,
    );

    // ── Stats ──
    final Widget statsSection = _ScoreGrid(state: state, scores: scores);

    // ── Wide layout: side panel matches board height ──
    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context, state, controller),
                const SizedBox(height: 8),
                _buildMessage(context, state),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(flex: 2, child: boardArea),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 340,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Stats at the top.
                            statsSection,
                            const SizedBox(height: 12),
                            controlsSection,
                            const SizedBox(height: 12),
                            // Moves fills remaining space.
                            Expanded(child: movesSection),
                            const SizedBox(height: 12),
                            _RestartButton(onPressed: controller.resetGame),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Mobile layout (no scroll, everything fits) ──
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Score header: User left-aligned, Bot right-aligned
              _MobileScoreHeader(state: state, scores: scores),
              const SizedBox(height: 8),
              // Grid + commentary: natural height, slightly above center
              Expanded(
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 1),
                    // Grid takes natural height based on width
                    boardArea,
                    // Commentary stuck right below grid
                    if (state.message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          state.message,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 11,
                                  ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const Spacer(flex: 4),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Bottom bar: Home | Skip | Restart
              _MobileBottomBar(
                onHome: () async {
                  await SoundService.playButtonTap();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      pageBuilder: (_, __, ___) => const HomeScreen(),
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
                onSkip: () async {
                  await SoundService.playButtonTap();
                  await controller.passTurn();
                },
                onRestart: () async {
                  await SoundService.playButtonTap();
                  controller.resetGame();
                },
                isInputEnabled: controller.isHumanInputEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeyboardSheet(
      BuildContext context, GameController controller) {
    if (!controller.isHumanInputEnabled) return;

    final TextEditingController textController = TextEditingController();

    _sheetAnimController.reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      transitionAnimationController: _sheetAnimController,
      builder: (BuildContext sheetContext) {
        return _KeyboardSheet(
          textController: textController,
          controller: controller,
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, GameState state, GameController controller) {
    return Row(
      children: <Widget>[
        Text(
          'Gridlock',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        _OpponentSelector(
          value: state.opponentType,
          onChanged: controller.setOpponentType,
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, GameState state) {
    return Text(
      state.message,
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: const Color(0xFF555555)),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

// ── Inline move history with bottom fade ──────────────────────

class _InlineMoveHistory extends StatelessWidget {
  const _InlineMoveHistory({
    required this.history,
    required this.opponentType,
  });

  final List<PlacedWord> history;
  final OpponentType opponentType;

  String _label(PlayerId player) {
    if (opponentType == OpponentType.bot) {
      return player == PlayerId.b ? 'Bot' : 'User';
    }
    return player == PlayerId.a ? 'Player A' : 'Player B';
  }

  @override
  Widget build(BuildContext context) {
    final List<PlacedWord> reversed = history.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Moves',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: reversed.isEmpty
                ? Center(
                    child: Text(
                      'No moves yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  )
                : ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: <double>[0.0, 0.7, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      itemCount: reversed.length,
                      itemBuilder: (context, index) {
                        final PlacedWord move = reversed[index];
                        final bool isBot = move.player == PlayerId.b;
                        final Color wordColor = isBot
                            ? const Color(0xFF166534)
                            : const Color(0xFF5B21B6);
                        final String dirIcon =
                            move.direction == Direction.horizontal
                                ? '→'
                                : '↓';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: const Color(0xFF6B7280)),
                              children: <TextSpan>[
                                TextSpan(
                                    text: '${_label(move.player)}: '),
                                TextSpan(
                                  text: move.word,
                                  style: TextStyle(
                                    color: wordColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: ' $dirIcon'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Game-over card overlay ────────────────────────────────────

class _GameOverCard extends StatelessWidget {
  const _GameOverCard({
    required this.message,
    required this.scores,
    required this.opponentType,
    required this.onRestart,
  });

  final String message;
  final ScoreBoard scores;
  final OpponentType opponentType;
  final VoidCallback onRestart;

  String _label(PlayerId player) {
    if (opponentType == OpponentType.bot) {
      return player == PlayerId.b ? 'Bot' : 'User';
    }
    return player == PlayerId.a ? 'Player A' : 'Player B';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Game Over',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF555555)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _scoreColumn(context, _label(PlayerId.a),
                  scores.playerA.toStringAsFixed(1)),
              _scoreColumn(context, _label(PlayerId.b),
                  scores.playerB.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRestart,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn(BuildContext context, String label, String score) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Text(score,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }
}

// ── Score grid (table layout) ─────────────────────────────────

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.state, required this.scores});

  final GameState state;
  final ScoreBoard scores;

  @override
  Widget build(BuildContext context) {
    final String labelA = _labelFor(PlayerId.a, state.opponentType);
    final String labelB = _labelFor(PlayerId.b, state.opponentType);

    final TextStyle headerStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(
            fontWeight: FontWeight.w700, color: const Color(0xFF6B7280));
    final TextStyle valueStyle = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(
            fontWeight: FontWeight.w600, color: const Color(0xFF111111));
    final TextStyle labelStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: const Color(0xFF6B7280));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  const SizedBox.shrink(),
                  Center(child: Text(labelA, style: headerStyle)),
                  Center(child: Text(labelB, style: headerStyle)),
                ],
              ),
              _tableRow('Score', scores.playerA.toStringAsFixed(1),
                  scores.playerB.toStringAsFixed(1), labelStyle, valueStyle),
              _tableRow('Session', '${state.sessionWinsA}',
                  '${state.sessionWinsB}', labelStyle, valueStyle),
              _tableRow('Moves', '${state.movesA}', '${state.movesB}',
                  labelStyle, valueStyle),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String label, String valA, String valB,
      TextStyle labelStyle, TextStyle valueStyle) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(label, style: labelStyle),
        ),
        Center(child: Text(valA, style: valueStyle)),
        Center(child: Text(valB, style: valueStyle)),
      ],
    );
  }

  String _labelFor(PlayerId player, OpponentType mode) {
    if (mode == OpponentType.bot) {
      return player == PlayerId.b ? 'Bot' : 'User';
    }
    return player == PlayerId.a ? 'Player A' : 'Player B';
  }
}

// ── Restart button: outlined, fills on hover ──────────────────

class _RestartButton extends StatefulWidget {
  const _RestartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RestartButton> createState() => _RestartButtonState();
}

class _RestartButtonState extends State<_RestartButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _hovered
          ? FilledButton(
              onPressed: widget.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Restart'),
            )
          : OutlinedButton(
              onPressed: widget.onPressed,
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Restart'),
            ),
    );
  }
}

// ── Keyboard bottom sheet with autocorrect ─────────────────────

class _KeyboardSheet extends StatefulWidget {
  const _KeyboardSheet({
    required this.textController,
    required this.controller,
  });

  final TextEditingController textController;
  final GameController controller;

  @override
  State<_KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends State<_KeyboardSheet> {
  List<String> _suggestions = const <String>[];

  void _onChanged(String value) {
    widget.controller.updateDraftWord(value);
    final String upper = value.trim().toUpperCase();
    if (upper.length >= 4) {
      setState(() {
        _suggestions =
            widget.controller.getAutocompleteSuggestions(upper, limit: 5);
      });
    } else {
      setState(() {
        _suggestions = const <String>[];
      });
    }
  }

  Future<void> _submit(String word) async {
    Navigator.of(context).pop();
    await widget.controller.submitWord(word);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Suggestions chips
            if (_suggestions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, int i) {
                    final String word = _suggestions[i];
                    return GestureDetector(
                      onTap: () {
                        widget.textController.text = word;
                        widget.textController.selection =
                            TextSelection.collapsed(offset: word.length);
                        _onChanged(word);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          word,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Input field with send button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: widget.textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: _onChanged,
                      onSubmitted: _submit,
                      cursorColor: const Color(0xFF111111),
                      decoration: InputDecoration(
                        hintText: 'Type your word',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: const Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: const Color(0xFF111111),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _submit(widget.textController.text),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Opponent selector dropdown ────────────────────────────────

class _OpponentSelector extends StatelessWidget {
  const _OpponentSelector(
      {required this.value, required this.onChanged});

  final OpponentType value;
  final ValueChanged<OpponentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<OpponentType>(
      value: value,
      items: const <DropdownMenuItem<OpponentType>>[
        DropdownMenuItem(
            value: OpponentType.local, child: Text('2P local')),
        DropdownMenuItem(
            value: OpponentType.bot, child: Text('vs bot')),
      ],
      onChanged: (OpponentType? value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

// ── Mobile score header ────────────────────────────────────────

class _MobileScoreHeader extends StatelessWidget {
  const _MobileScoreHeader({
    required this.state,
    required this.scores,
  });

  final GameState state;
  final ScoreBoard scores;

  String _labelFor(PlayerId player) {
    if (state.opponentType == OpponentType.bot) {
      return player == PlayerId.b ? 'BOT' : 'USER';
    }
    return player == PlayerId.a ? 'PLAYER A' : 'PLAYER B';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        // User – left aligned
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _labelFor(PlayerId.a),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
            ),
            Text(
              scores.playerA.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
            ),
          ],
        ),
        const Spacer(),
        // Bot – right aligned
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              _labelFor(PlayerId.b),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
            ),
            Text(
              scores.playerB.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111111),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Mobile bottom bar: Home | Skip | Restart ────────────────────

class _MobileBottomBar extends StatelessWidget {
  const _MobileBottomBar({
    required this.onHome,
    required this.onSkip,
    required this.onRestart,
    required this.isInputEnabled,
  });

  final VoidCallback onHome;
  final VoidCallback onSkip;
  final VoidCallback onRestart;
  final bool isInputEnabled;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: const Color(0xFF111111),
        );
    final TextStyle disabled = base.copyWith(color: const Color(0xFFBDBDBD));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        GestureDetector(
          onTap: onHome,
          child: Text('Home', style: base),
        ),
        GestureDetector(
          onTap: isInputEnabled ? onSkip : null,
          child: Text('Skip', style: isInputEnabled ? base : disabled),
        ),
        GestureDetector(
          onTap: onRestart,
          child: Text('Restart', style: base),
        ),
      ],
    );
  }
}
