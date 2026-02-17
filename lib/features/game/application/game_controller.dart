import 'dart:async';
import 'dart:math' show Random, min;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/domain/board_engine.dart';
import '../../game/domain/move_validator.dart';
import '../../game/domain/scoring_engine.dart';
import '../../../services/dictionary/offline_dictionary_service.dart';
import '../../../services/hints/gemini_hint_service.dart';
import '../../../services/settings_service.dart';

const int kDefaultTurnSeconds = 30;
const int kMaxConsecutiveSkips = 4;

enum GamePhase { seedA, seedB, playing, finished }

enum InputMode { fullWord, cellWalk }

enum OpponentType { local, bot }

enum RoundOutcome { none, playerA, playerB, tie }

const Object _keepField = Object();

/// Immutable rectangle that locks the grid after seed phase.
class GridBounds {
  const GridBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  bool containsPosition(Position pos) {
    return pos.x >= minX && pos.x <= maxX && pos.y >= minY && pos.y <= maxY;
  }
}

class GameState {
  const GameState({
    required this.board,
    required this.phase,
    required this.currentPlayer,
    required this.direction,
    required this.inputMode,
    required this.remainingSeconds,
    required this.consecutiveSkips,
    required this.message,
    required this.selectedPosition,
    required this.opponentType,
    required this.isDictionaryReady,
    required this.totalTurnTime,
    required this.isAiThinking,
    required this.draftWord,
    required this.liveValidationMessage,
    required this.sessionWinsA,
    required this.sessionWinsB,
    required this.roundsPlayed,
    required this.lastRoundOutcome,
    required this.inputNonce,
    required this.isPaused,
    required this.gridBounds,
    required this.movesA,
    required this.movesB,
    required this.availableMoves,
    required this.lastBotMovePositions,
    required this.colorThemeIndex,
    required this.ghostHintLetters,
    required this.showDirectionArrows,
    required this.userSkipCount,
  });

  factory GameState.initial({int turnSeconds = kDefaultTurnSeconds}) {
    return GameState(
      board: BoardState.empty(),
      phase: GamePhase.seedA,
      currentPlayer: PlayerId.a,
      direction: Direction.horizontal,
      inputMode: InputMode.fullWord,
      remainingSeconds: turnSeconds,
      consecutiveSkips: 0,
      message: 'Player A: Enter first horizontal word.',
      selectedPosition: Position(0, 0),
      opponentType: OpponentType.bot,
      isDictionaryReady: false,
      totalTurnTime: {PlayerId.a: 0, PlayerId.b: 0},
      isAiThinking: false,
      draftWord: '',
      liveValidationMessage: null,
      sessionWinsA: 0,
      sessionWinsB: 0,
      roundsPlayed: 0,
      lastRoundOutcome: RoundOutcome.none,
      inputNonce: 0,
      isPaused: false,
      gridBounds: null,
      movesA: 0,
      movesB: 0,
      availableMoves: const <String>[],
      lastBotMovePositions: const <Position>[],
      colorThemeIndex: Random().nextInt(12),
      ghostHintLetters: const <Position, String>{},
      showDirectionArrows: false,
      userSkipCount: 0,
    );
  }

  int get totalMoves => movesA + movesB;

  final BoardState board;
  final GamePhase phase;
  final PlayerId currentPlayer;
  final Direction direction;
  final InputMode inputMode;
  final int remainingSeconds;
  final int consecutiveSkips;
  final String message;
  final Position? selectedPosition;
  final OpponentType opponentType;
  final bool isDictionaryReady;
  final Map<PlayerId, int> totalTurnTime;
  final bool isAiThinking;
  final String draftWord;
  final String? liveValidationMessage;
  final int sessionWinsA;
  final int sessionWinsB;
  final int roundsPlayed;
  final RoundOutcome lastRoundOutcome;
  final int inputNonce;
  final bool isPaused;
  final GridBounds? gridBounds;
  final int movesA;
  final int movesB;

  /// Words the current player could play (computed on turn start).
  final List<String> availableMoves;

  /// Cell positions of the last word placed by the bot (for blink animation).
  final List<Position> lastBotMovePositions;

  /// Cycles through color palettes each new game for visual variety.
  final int colorThemeIndex;

  /// Ghost hint letters shown on the grid (position → letter).
  final Map<Position, String> ghostHintLetters;

  /// Whether floating direction arrows are visible on the grid.
  final bool showDirectionArrows;

  /// How many consecutive turns the user has skipped / timed out.
  /// Resets when the user successfully places a word.
  final int userSkipCount;

  GameState copyWith({
    BoardState? board,
    GamePhase? phase,
    PlayerId? currentPlayer,
    Direction? direction,
    InputMode? inputMode,
    int? remainingSeconds,
    int? consecutiveSkips,
    String? message,
    Position? selectedPosition,
    OpponentType? opponentType,
    bool? isDictionaryReady,
    Map<PlayerId, int>? totalTurnTime,
    bool? isAiThinking,
    String? draftWord,
    Object? liveValidationMessage = _keepField,
    int? sessionWinsA,
    int? sessionWinsB,
    int? roundsPlayed,
    RoundOutcome? lastRoundOutcome,
    int? inputNonce,
    bool? isPaused,
    Object? gridBounds = _keepField,
    int? movesA,
    int? movesB,
    List<String>? availableMoves,
    List<Position>? lastBotMovePositions,
    int? colorThemeIndex,
    Map<Position, String>? ghostHintLetters,
    bool? showDirectionArrows,
    int? userSkipCount,
  }) {
    return GameState(
      board: board ?? this.board,
      phase: phase ?? this.phase,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      direction: direction ?? this.direction,
      inputMode: inputMode ?? this.inputMode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      consecutiveSkips: consecutiveSkips ?? this.consecutiveSkips,
      message: message ?? this.message,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      opponentType: opponentType ?? this.opponentType,
      isDictionaryReady: isDictionaryReady ?? this.isDictionaryReady,
      totalTurnTime: totalTurnTime ?? this.totalTurnTime,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      draftWord: draftWord ?? this.draftWord,
      liveValidationMessage: liveValidationMessage == _keepField
          ? this.liveValidationMessage
          : liveValidationMessage as String?,
      sessionWinsA: sessionWinsA ?? this.sessionWinsA,
      sessionWinsB: sessionWinsB ?? this.sessionWinsB,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      lastRoundOutcome: lastRoundOutcome ?? this.lastRoundOutcome,
      inputNonce: inputNonce ?? this.inputNonce,
      isPaused: isPaused ?? this.isPaused,
      gridBounds: gridBounds == _keepField
          ? this.gridBounds
          : gridBounds as GridBounds?,
      movesA: movesA ?? this.movesA,
      movesB: movesB ?? this.movesB,
      availableMoves: availableMoves ?? this.availableMoves,
      lastBotMovePositions: lastBotMovePositions ?? this.lastBotMovePositions,
      colorThemeIndex: colorThemeIndex ?? this.colorThemeIndex,
      ghostHintLetters: ghostHintLetters ?? this.ghostHintLetters,
      showDirectionArrows: showDirectionArrows ?? this.showDirectionArrows,
      userSkipCount: userSkipCount ?? this.userSkipCount,
    );
  }
}

final offlineDictionaryProvider = Provider<OfflineDictionaryService>((ref) {
  return OfflineDictionaryService();
});

final geminiHintProvider = Provider<GeminiHintService>((ref) {
  const String key = String.fromEnvironment('GEMINI_API_KEY');
  return GeminiHintService(apiKey: key);
});

final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) {
    final controller = GameController(
      dictionary: ref.read(offlineDictionaryProvider),
      boardEngine: BoardEngine(),
      moveValidator: MoveValidator(),
      scoringEngine: ScoringEngine(),
      geminiHintService: ref.read(geminiHintProvider),
      readSettings: () => ref.read(settingsProvider),
    );
    controller.initialize();
    return controller;
  },
);

class GameController extends StateNotifier<GameState> {
  GameController({
    required OfflineDictionaryService dictionary,
    required BoardEngine boardEngine,
    required MoveValidator moveValidator,
    required ScoringEngine scoringEngine,
    required GeminiHintService geminiHintService,
    required SettingsState Function() readSettings,
  }) : _dictionary = dictionary,
       _boardEngine = boardEngine,
       _moveValidator = moveValidator,
       _scoringEngine = scoringEngine,
       _geminiHintService = geminiHintService,
       _readSettings = readSettings,
       super(GameState.initial(turnSeconds: readSettings().timerSeconds));

  final OfflineDictionaryService _dictionary;
  final BoardEngine _boardEngine;
  final MoveValidator _moveValidator;
  final ScoringEngine _scoringEngine;
  final GeminiHintService _geminiHintService;
  final SettingsState Function() _readSettings;
  Timer? _turnTimer;
  bool _botTurnInProgress = false;

  int get _turnSeconds => _readSettings().timerSeconds;
  bool get _timerEnabled => _readSettings().timerEnabled;

  /// Cached ghost hint candidates for the current selection + direction.
  List<String> _ghostCandidates = const <String>[];

  /// Index of the next candidate to show (wraps around).
  int _ghostCandidateIndex = 0;

  /// Position + direction the candidates were computed for.
  Position? _ghostCandidatePos;
  Direction? _ghostCandidateDir;

  /// Autocomplete suggestions for a prefix (for the mobile keyboard).
  List<String> getAutocompleteSuggestions(String prefix, {int limit = 5}) {
    if (prefix.length < 4) return const <String>[];
    return _dictionary.autocomplete(prefix, limit: limit);
  }

  /// Suggest the closest dictionary word (for "did you mean?" hints).
  String? suggestClosest(String word) {
    if (word.length < 4) return null;
    return _dictionary.suggestClosestWord(word, maxDistance: 2);
  }

  // ── Lifecycle ──────────────────────────────────────────────

  Future<void> initialize() async {
    await _dictionary.ensureLoaded();
    state = state.copyWith(
      isDictionaryReady: true,
      message:
          '${_playerLabel(state.currentPlayer)}: Enter first horizontal word.',
    );
    if (_timerEnabled) _startTurnTimer();
    unawaited(_maybePlayBotTurn());
  }

  void resetGame() {
    _turnTimer?.cancel();
    _botTurnInProgress = false;
    const PlayerId starter = PlayerId.a;
    state = GameState.initial(turnSeconds: _turnSeconds).copyWith(
      opponentType: state.opponentType,
      isDictionaryReady: state.isDictionaryReady,
      currentPlayer: starter,
      message: '${_playerLabel(starter)}: Enter first horizontal word.',
      sessionWinsA: state.sessionWinsA,
      sessionWinsB: state.sessionWinsB,
      roundsPlayed: state.roundsPlayed,
      lastRoundOutcome: state.lastRoundOutcome,
      inputNonce: state.inputNonce + 1,
      isPaused: false,
      colorThemeIndex: Random().nextInt(12),
      userSkipCount: 0,
    );
    if (_timerEnabled) _startTurnTimer();
    unawaited(_maybePlayBotTurn());
  }

  void setOpponentType(OpponentType type) {
    if (state.opponentType == type) {
      return;
    }
    _turnTimer?.cancel();
    const PlayerId starter = PlayerId.a;
    state = GameState.initial(turnSeconds: _turnSeconds).copyWith(
      opponentType: type,
      isDictionaryReady: state.isDictionaryReady,
      currentPlayer: starter,
      message:
          '${_playerLabel(starter, opponentType: type)}: Enter first horizontal word.',
      inputNonce: state.inputNonce + 1,
      isPaused: false,
    );
    if (_timerEnabled) _startTurnTimer();
    unawaited(_maybePlayBotTurn());
  }

  /// Called when settings change (e.g. timer toggled on/off or duration
  /// changed) so the running game can adapt without a full reset.
  void syncTimerSettings() {
    if (_timerEnabled) {
      // Update remaining seconds to the new duration if the timer wasn't
      // already running, or if the new duration is shorter than current
      // remaining time.
      if (_turnTimer == null || !_turnTimer!.isActive) {
        state = state.copyWith(remainingSeconds: _turnSeconds);
        _startTurnTimer();
      } else if (state.remainingSeconds > _turnSeconds) {
        state = state.copyWith(remainingSeconds: _turnSeconds);
      }
    } else {
      // Timer disabled – stop counting and reset display.
      _turnTimer?.cancel();
      _turnTimer = null;
    }
  }

  // ── UI interaction (human-gated) ──────────────────────────

  void selectPosition(Position position) {
    if (!_isHumanInputEnabled) {
      return;
    }
    state = state.copyWith(
      selectedPosition: position,
      showDirectionArrows: state.phase == GamePhase.playing,
      draftWord: '',
      liveValidationMessage: null,
      inputNonce: state.inputNonce + 1,
    );
  }

  /// Clears the active cell selection and hides direction arrows.
  void clearSelection() {
    state = state.copyWith(
      showDirectionArrows: false,
      draftWord: '',
      liveValidationMessage: null,
      inputNonce: state.inputNonce + 1,
      ghostHintLetters: const <Position, String>{},
    );
  }

  void setDirection(Direction direction) {
    if (!_isHumanInputEnabled) {
      return;
    }
    state = state.copyWith(direction: direction);
  }

  /// Called when user explicitly picks direction from arrows (click or key).
  void chooseDirection(Direction direction) {
    if (!_isHumanInputEnabled) {
      return;
    }
    state = state.copyWith(
      direction: direction,
      showDirectionArrows: false,
    );
  }

  /// Moves the selection by one cell using arrow keys. Only during playing
  /// phase and within grid bounds.
  void moveSelectionByArrow(int dx, int dy) {
    if (!_isHumanInputEnabled || state.phase != GamePhase.playing) {
      return;
    }
    final Position? current = state.selectedPosition;
    if (current == null) {
      return;
    }
    final Position next = Position(current.x + dx, current.y + dy);
    final GridBounds? bounds = state.gridBounds;
    if (bounds != null && !bounds.containsPosition(next)) {
      return; // don't move outside grid
    }
    state = state.copyWith(
      selectedPosition: next,
      showDirectionArrows: false,
      draftWord: '',
      liveValidationMessage: null,
      inputNonce: state.inputNonce + 1,
      ghostHintLetters: const <Position, String>{},
    );
  }

  void updateDraftWord(String rawWord) {
    if (!_isHumanInputEnabled) {
      return;
    }
    final String word = _normalize(rawWord);
    final String? live = _validateDraft(word);

    // Show direction arrows when first letter is typed during playing phase.
    bool arrows = state.showDirectionArrows;
    if (word.isNotEmpty && state.draftWord.isEmpty &&
        state.phase == GamePhase.playing && !arrows) {
      arrows = true;
    }
    // Hide arrows when draft is cleared.
    if (word.isEmpty) {
      arrows = false;
    }

    state = state.copyWith(
      draftWord: word,
      liveValidationMessage: live,
      ghostHintLetters: const <Position, String>{},
      showDirectionArrows: arrows,
    );
  }

  bool get isHumanInputEnabled => _isHumanInputEnabled;

  void togglePause() {
    if (state.phase == GamePhase.finished) {
      return;
    }
    final bool nextPaused = !state.isPaused;
    // Don't overwrite message -- the UI shows pause state separately.
    state = state.copyWith(isPaused: nextPaused);
    if (!nextPaused) {
      unawaited(_maybePlayBotTurn());
    }
  }

  // ── Public submit / pass (human-gated wrappers) ───────────

  Future<void> passTurn() async {
    if (state.phase == GamePhase.finished || !_isHumanInputEnabled) {
      return;
    }

    // During seed phases, auto-play on behalf of user instead of skipping.
    if (state.phase == GamePhase.seedA || state.phase == GamePhase.seedB) {
      final int newSkips = state.userSkipCount + 1;
      state = state.copyWith(userSkipCount: newSkips);
      await _autoPlaySeedOnBehalf();
      return;
    }

    // During playing phase, track consecutive user skips.
    final int newSkips = state.userSkipCount + 1;
    if (newSkips >= 3) {
      state = state.copyWith(userSkipCount: newSkips);
      _finishGame("Looks like you stepped away. Let's wrap this one up!");
      return;
    }
    state = state.copyWith(userSkipCount: newSkips);
    await _passTurnInternal();
  }

  /// Called from UI. Gates on human-input then delegates to internal.
  Future<void> submitWord(String rawWord) async {
    if (!state.isDictionaryReady ||
        state.phase == GamePhase.finished ||
        !_isHumanInputEnabled) {
      return;
    }
    final int prevMoves = state.totalMoves;
    await _submitWordInternal(rawWord);
    // Reset skip counter when user successfully places a word.
    if (state.totalMoves > prevMoves) {
      state = state.copyWith(userSkipCount: 0);
    }
  }

  // ── Internal submit (NO human gate -- bot uses this) ──────

  Future<void> _submitWordInternal(String rawWord) async {
    if (!state.isDictionaryReady || state.phase == GamePhase.finished) {
      return;
    }

    final String word = _normalize(rawWord);
    if (word.length < 3) {
      state = state.copyWith(message: 'Enter at least 3 letters.');
      return;
    }
    if (!_dictionary.isValidWord(word)) {
      final String? suggestion = _dictionary.suggestClosestWord(word);
      state = state.copyWith(
        message: suggestion == null
            ? 'Not in dictionary.'
            : 'Not in dictionary. Did you mean "$suggestion"?',
      );
      return;
    }

    // ── Seed A: first horizontal word ──
    if (state.phase == GamePhase.seedA) {
      final PlayerId seedAPlayer = state.currentPlayer;
      final PlayerId seedBPlayer = _otherPlayer(seedAPlayer);
      final MoveValidationResult validation = _moveValidator.validatePlacement(
        board: state.board,
        word: word,
        start: const Position(0, 0),
        direction: Direction.horizontal,
        requireIntersection: false,
      );
      if (!validation.isValid) {
        state = state.copyWith(message: validation.error);
        return;
      }
      final BoardState nextBoard = _boardEngine.placeWord(
        board: state.board,
        word: word,
        start: const Position(0, 0),
        direction: Direction.horizontal,
        player: seedAPlayer,
      );
      state = state.copyWith(
        board: nextBoard,
        phase: GamePhase.seedB,
        currentPlayer: seedBPlayer,
        direction: Direction.vertical,
        selectedPosition: const Position(0, 0),
        remainingSeconds: _turnSeconds,
        draftWord: '',
        liveValidationMessage: null,
        inputNonce: state.inputNonce + 1,
        movesA: seedAPlayer == PlayerId.a ? state.movesA + 1 : state.movesA,
        movesB: seedAPlayer == PlayerId.b ? state.movesB + 1 : state.movesB,
        message:
            '${_playerLabel(seedBPlayer)}: Enter vertical word with overlap.',
      );
      await _maybePlayBotTurn();
      return;
    }

    // ── Seed B: vertical word overlapping seed A ──
    if (state.phase == GamePhase.seedB) {
      final _SeedPlacement? placement = _buildSecondSeedPlacement(word);
      if (placement == null) {
        state = state.copyWith(
          message:
              'Second word must overlap a shared letter from the first word.',
        );
        return;
      }
      final MoveValidationResult validation = _moveValidator.validatePlacement(
        board: state.board,
        word: word,
        start: placement.start,
        direction: Direction.vertical,
        requireIntersection: true,
      );
      if (!validation.isValid || validation.intersections != 1) {
        state = state.copyWith(
          message: 'Need exactly one clean overlap for seed word.',
        );
        return;
      }

      final BoardState nextBoard = _boardEngine.placeWord(
        board: state.board,
        word: word,
        start: placement.start,
        direction: Direction.vertical,
        player: state.currentPlayer,
      );

      // Lock grid bounds after cross is formed.
      final GridBounds bounds = GridBounds(
        minX: nextBoard.minX,
        maxX: nextBoard.maxX,
        minY: nextBoard.minY,
        maxY: nextBoard.maxY,
      );

      final PlayerId seedBPlayer = state.currentPlayer;
      final PlayerId next = _otherPlayer(seedBPlayer);
      state = state.copyWith(
        board: nextBoard,
        phase: GamePhase.playing,
        currentPlayer: next,
        direction: Direction.horizontal,
        selectedPosition: Position(nextBoard.minX, nextBoard.minY),
        remainingSeconds: _turnSeconds,
        consecutiveSkips: 0,
        draftWord: '',
        liveValidationMessage: null,
        inputNonce: state.inputNonce + 1,
        gridBounds: bounds,
        movesA: seedBPlayer == PlayerId.a ? state.movesA + 1 : state.movesA,
        movesB: seedBPlayer == PlayerId.b ? state.movesB + 1 : state.movesB,
        message: next == PlayerId.a && state.opponentType == OpponentType.bot
            ? 'Game on. You\'re next!'
            : 'Game on. ${_playerLabel(next)} to move.',
      );
      await _maybePlayBotTurn();
      return;
    }

    // ── Normal play ──
    final Position? start = state.selectedPosition;
    if (start == null) {
      state = state.copyWith(message: 'Select a starting cell.');
      return;
    }

    final MoveValidationResult validation = _moveValidator.validatePlacement(
      board: state.board,
      word: word,
      start: start,
      direction: state.direction,
      requireIntersection: true,
      bounds: state.gridBounds,
    );
    if (!validation.isValid) {
      state = state.copyWith(message: validation.error);
      return;
    }

    final BoardState nextBoard = _boardEngine.placeWord(
      board: state.board,
      word: word,
      start: start,
      direction: state.direction,
      player: state.currentPlayer,
    );

    final PlayerId placer = state.currentPlayer;
    state = state.copyWith(
      board: nextBoard,
      draftWord: '',
      liveValidationMessage: null,
      inputNonce: state.inputNonce + 1,
      movesA: placer == PlayerId.a ? state.movesA + 1 : state.movesA,
      movesB: placer == PlayerId.b ? state.movesB + 1 : state.movesB,
    );
    _endCurrentTurnAndRotate(
      newMessage: '${_playerLabel(placer)} placed $word',
      resetSkips: true,
    );
    _evaluateEndState();
    await _maybePlayBotTurn();
  }

  // ── Pass internal (no human gate) ─────────────────────────

  Future<void> _passTurnInternal() async {
    if (state.phase == GamePhase.finished) {
      return;
    }
    _endCurrentTurnAndRotate(newMessage: 'Turn skipped.', resetSkips: false);
    _evaluateEndState();
    await _maybePlayBotTurn();
  }

  // ── Hints ─────────────────────────────────────────────────

  /// Shows ghost hint letters on the grid (max 2 empty-cell letters).
  /// Each click cycles to the next valid candidate.  If the position or
  /// direction changed since last click, candidates are recomputed.
  String? showGhostHintOnGrid() {
    if (!state.isDictionaryReady || state.phase == GamePhase.finished) {
      return null;
    }
    final Position? start = state.selectedPosition;
    if (start == null) {
      return null;
    }

    // Re-compute candidates when selection / direction changed.
    if (start != _ghostCandidatePos ||
        state.direction != _ghostCandidateDir ||
        _ghostCandidates.isEmpty) {
      _ghostCandidates = _computeGhostCandidates(start, state.direction);
      _ghostCandidateIndex = 0;
      _ghostCandidatePos = start;
      _ghostCandidateDir = state.direction;
    }

    if (_ghostCandidates.isEmpty) {
      return null;
    }

    // Pick the current candidate, then advance index (wrap).
    final String word = _ghostCandidates[_ghostCandidateIndex];
    _ghostCandidateIndex =
        (_ghostCandidateIndex + 1) % _ghostCandidates.length;

    // Build ghost letters — reveal at most 2 empty cells.
    final Map<Position, String> ghost = <Position, String>{};
    final List<MapEntry<Position, String>> empties = <MapEntry<Position, String>>[];
    Position cursor = start;
    for (int i = 0; i < word.length; i++) {
      if (!state.board.cells.containsKey(cursor)) {
        empties.add(MapEntry(cursor, word[i]));
      }
      cursor = cursor.next(state.direction);
    }
    // Pick up to 2 letters spread across the empty cells.
    if (empties.length <= 2) {
      for (final MapEntry<Position, String> e in empties) {
        ghost[e.key] = e.value;
      }
    } else {
      // Spread: first and middle.
      ghost[empties.first.key] = empties.first.value;
      ghost[empties[empties.length ~/ 2].key] =
          empties[empties.length ~/ 2].value;
    }

    state = state.copyWith(
      ghostHintLetters: ghost,
      message: 'Ghost hint — guess the word!',
    );
    return word;
  }

  /// Compute all valid words placeable at [start] in [dir].
  List<String> _computeGhostCandidates(Position start, Direction dir) {
    final List<String> results = <String>[];
    final Set<String> seen = <String>{};
    for (int length = 3; length <= 8; length++) {
      final String pattern = _patternAt(
        start: start,
        direction: dir,
        length: length,
      );
      if (!pattern.contains('_')) {
        continue;
      }
      final List<String> matches = _dictionary.findAllByPattern(
        pattern,
        limit: 20,
        commonFirst: true,
      );
      for (final String candidate in matches) {
        if (seen.contains(candidate)) {
          continue;
        }
        final MoveValidationResult validation =
            _moveValidator.validatePlacement(
          board: state.board,
          word: candidate,
          start: start,
          direction: dir,
          requireIntersection: true,
          bounds: state.gridBounds,
        );
        if (validation.isValid) {
          seen.add(candidate);
          results.add(candidate);
        }
      }
    }
    return results;
  }

  /// Legacy getter kept for hint service fallback.
  String? getOfflineGhostHint() => showGhostHintOnGrid();

  Future<String?> requestAiHint() async {
    final Position? selected = state.selectedPosition;
    if (selected == null || state.phase == GamePhase.finished) {
      return null;
    }
    state = state.copyWith(isAiThinking: true);
    final String prompt =
        'Suggest one uppercase English word for this board. Start at ${selected.x},${selected.y} '
        'direction ${state.direction.name}. Keep answer to one word only.\nBoard:\n${_boardToAscii()}';
    final String? response = await _geminiHintService.getHint(prompt);
    state = state.copyWith(isAiThinking: false);
    return response;
  }

  ScoreBoard get scores => _scoringEngine.calculate(state.board);

  Map<Position, String> get draftPreviewLetters {
    final String word = state.draftWord;
    if (word.isEmpty) {
      return const <Position, String>{};
    }
    final _DraftPlacement? placement = _draftPlacementFor(word);
    if (placement == null) {
      return const <Position, String>{};
    }

    final Map<Position, String> preview = <Position, String>{};
    Position cursor = placement.start;
    for (int i = 0; i < word.length; i++) {
      if (!state.board.cells.containsKey(cursor)) {
        preview[cursor] = word[i];
      }
      cursor = cursor.next(placement.direction);
    }
    return preview;
  }

  // ── Timer ─────────────────────────────────────────────────

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.phase == GamePhase.finished) {
        timer.cancel();
        return;
      }
      if (state.isPaused) {
        return;
      }
      if (state.remainingSeconds <= 1) {
        final bool isHumanTurn = state.opponentType == OpponentType.bot &&
            state.currentPlayer == PlayerId.a;

        // ── Seed phase timeout: auto-play on behalf of user ──
        if (isHumanTurn &&
            (state.phase == GamePhase.seedA ||
                state.phase == GamePhase.seedB)) {
          final int newSkips = state.userSkipCount + 1;
          state = state.copyWith(userSkipCount: newSkips);
          await _autoPlaySeedOnBehalf();
          return;
        }

        // ── Playing phase timeout (human turn) ──
        if (isHumanTurn && state.phase == GamePhase.playing) {
          final int newSkips = state.userSkipCount + 1;
          if (newSkips >= 3) {
            state = state.copyWith(userSkipCount: newSkips);
            _finishGame(
                "Looks like you stepped away. Let's wrap this one up!");
            return;
          }

          List<String> missedWords = _computeAvailableWords();
          state = state.copyWith(userSkipCount: newSkips);
          await _passTurnInternal();

          String timeoutMsg = 'Time up. ${state.message}';
          if (missedWords.isNotEmpty) {
            final String suggestions = missedWords.take(5).join(', ');
            timeoutMsg += ' You could have played: $suggestions';
          }
          state = state.copyWith(
            remainingSeconds: _turnSeconds,
            message: timeoutMsg,
          );
          return;
        }

        // ── Bot timeout or non-bot game ──
        await _passTurnInternal();
        state = state.copyWith(
          remainingSeconds: _turnSeconds,
          message: 'Time up. ${state.message}',
        );
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  // ── Turn rotation ─────────────────────────────────────────

  void _endCurrentTurnAndRotate({
    required String newMessage,
    required bool resetSkips,
  }) {
    final int spent = _turnSeconds - state.remainingSeconds;
    final PlayerId justPlayed = state.currentPlayer;
    final PlayerId nextPlayer =
        justPlayed == PlayerId.a ? PlayerId.b : PlayerId.a;
    final Map<PlayerId, int> nextTimes = <PlayerId, int>{
      ...state.totalTurnTime,
      justPlayed: (state.totalTurnTime[justPlayed] ?? 0) + spent,
    };

    state = state.copyWith(
      currentPlayer: nextPlayer,
      remainingSeconds: _turnSeconds,
      selectedPosition: state.gridBounds != null
          ? Position(state.gridBounds!.minX, state.gridBounds!.minY)
          : const Position(0, 0),
      direction: Direction.horizontal,
      consecutiveSkips: resetSkips ? 0 : state.consecutiveSkips + 1,
      totalTurnTime: nextTimes,
      message: nextPlayer == PlayerId.a && state.opponentType == OpponentType.bot
          ? '$newMessage. You\'re next!'
          : '$newMessage. ${_playerLabel(nextPlayer)} next.',
      lastBotMovePositions: const <Position>[],
      ghostHintLetters: const <Position, String>{},
      showDirectionArrows: false,
    );
  }

  void _evaluateEndState() {
    if (state.consecutiveSkips >= kMaxConsecutiveSkips) {
      _finishGame('No more moves left!');
      return;
    }
    if (state.board.width * state.board.height >= 400) {
      _finishGame('Board limit reached!');
    }
  }

  void _finishGame(String reason) {
    final ScoreBoard finalScores = scores;
    final RoundOutcome outcome = _outcome(finalScores);
    final int nextA =
        state.sessionWinsA + (outcome == RoundOutcome.playerA ? 1 : 0);
    final int nextB =
        state.sessionWinsB + (outcome == RoundOutcome.playerB ? 1 : 0);
    final String winner = _winnerLabel(finalScores);
    state = state.copyWith(
      phase: GamePhase.finished,
      message: '$reason $winner wins!',
      remainingSeconds: 0,
      sessionWinsA: nextA,
      sessionWinsB: nextB,
      roundsPlayed: state.roundsPlayed + 1,
      lastRoundOutcome: outcome,
    );
  }

  String _winnerLabel(ScoreBoard scoreBoard) {
    final bool isBotMode = state.opponentType == OpponentType.bot;
    final String labelA = isBotMode ? 'You' : _playerLabel(PlayerId.a);
    final String labelB = isBotMode ? 'Bot' : _playerLabel(PlayerId.b);
    if (scoreBoard.playerA > scoreBoard.playerB) {
      return labelA;
    }
    if (scoreBoard.playerB > scoreBoard.playerA) {
      return labelB;
    }
    final int aTime = state.totalTurnTime[PlayerId.a] ?? 0;
    final int bTime = state.totalTurnTime[PlayerId.b] ?? 0;
    if (aTime == bTime) {
      return "It's a tie —  nobody";
    }
    return aTime < bTime ? labelA : labelB;
  }

  // ── Bot turn logic ────────────────────────────────────────

  Future<void> _maybePlayBotTurn() async {
    if (_botTurnInProgress) {
      return;
    }
    if (state.opponentType != OpponentType.bot ||
        state.currentPlayer != PlayerId.b) {
      return;
    }
    if (state.phase == GamePhase.finished || state.isPaused) {
      return;
    }
    _botTurnInProgress = true;
    state = state.copyWith(isAiThinking: true, message: 'Bot is thinking...');

    try {
      // Retry up to 3 times on unexpected errors instead of silently skipping.
      int retries = 0;
      const int maxRetries = 3;
      while (retries < maxRetries) {
        try {
          // Small visual delay so user sees the "thinking" state.
          await Future<void>.delayed(const Duration(milliseconds: 500));

          if (state.phase == GamePhase.seedB) {
            await _botPlaySeed();
            return;
          }

          await _botPlayNormal();
          return; // success
        } catch (_) {
          retries++;
          if (retries >= maxRetries) {
            // Absolute last resort after repeated failures – board may be
            // genuinely deadlocked.
            await _passTurnInternal();
          }
        }
      }
    } finally {
      _botTurnInProgress = false;
      if (state.isAiThinking) {
        state = state.copyWith(isAiThinking: false);
      }
    }
  }

  /// Bot seed turn: find a vertical word that overlaps the horizontal seed.
  /// Collects all valid candidates, groups by score tier, and picks randomly
  /// to avoid predictable patterns.
  Future<void> _botPlaySeed() async {
    if (state.board.history.isEmpty) {
      await _passTurnInternal();
      return;
    }
    final PlacedWord firstWord = state.board.history.first;

    // Collect unique letters from the first word.
    final Set<String> uniqueLetters = firstWord.word.split('').toSet();

    int bestScore = 0;
    final List<String> topCandidates = <String>[];

    // Search common words only (beginner-level bot uses simple words).
    for (final String letter in uniqueLetters) {
      final List<String> candidates =
          _dictionary.getWordsForLetter(letter);

      for (final String candidate in candidates) {
        // Allow words up to length 12 for the seed.
        if (candidate.length < 3 || candidate.length > 12) {
          continue;
        }
        // Guard: ensure candidate is actually in the dictionary.
        if (!_dictionary.isValidWord(candidate)) {
          continue;
        }
        final _SeedPlacement? placement =
            _buildSecondSeedPlacement(candidate);
        if (placement == null) {
          continue;
        }
        final MoveValidationResult validation =
            _moveValidator.validatePlacement(
          board: state.board,
          word: candidate,
          start: placement.start,
          direction: Direction.vertical,
          requireIntersection: true,
        );
        if (validation.isValid && validation.intersections == 1) {
          final int score = candidate.length;
          if (score > bestScore) {
            bestScore = score;
            topCandidates.clear();
            topCandidates.add(candidate);
          } else if (score == bestScore) {
            topCandidates.add(candidate);
          }
        }
      }
    }

    if (topCandidates.isNotEmpty) {
      // Pick randomly among top-scoring candidates.
      final String chosen =
          topCandidates[Random().nextInt(topCandidates.length)];
      await _submitWordInternal(chosen);
      // If submit didn't advance past seedB (shouldn't happen), pass.
      if (state.phase == GamePhase.seedB) {
        await _passTurnInternal();
      }
    } else {
      // Truly no overlapping word found (extremely unlikely).
      await _passTurnInternal();
    }
  }

  /// Auto-play a seed word on behalf of the user when they time out or skip.
  Future<void> _autoPlaySeedOnBehalf() async {
    if (state.phase == GamePhase.seedA) {
      // Pick a common starting word (4-7 letters).
      final Set<String> candidates = <String>{};
      for (final String letter
          in const <String>['E', 'A', 'T', 'O', 'S', 'R', 'I', 'N']) {
        for (final String word in _dictionary.getWordsForLetter(letter)) {
          if (word.length >= 4 && word.length <= 7) {
            candidates.add(word);
            if (candidates.length >= 30) break;
          }
        }
        if (candidates.length >= 30) break;
      }
      if (candidates.isNotEmpty) {
        final List<String> list = candidates.toList();
        final String chosen = list[Random().nextInt(list.length)];
        state = state.copyWith(
          message: 'Bot played "$chosen" on your behalf.',
          remainingSeconds: _turnSeconds,
        );
        await _submitWordInternal(chosen);
      }
    } else if (state.phase == GamePhase.seedB) {
      // Reuse the bot's seed-finding logic to place a vertical word.
      state = state.copyWith(
        message: 'Bot is placing the second seed for you...',
        remainingSeconds: _turnSeconds,
      );
      await _botPlaySeed();
      // If _botPlaySeed couldn't find a word (shouldn't happen), pass.
      if (state.phase == GamePhase.seedB) {
        await _passTurnInternal();
      }
    }
  }

  /// Bot normal turn: uses the exhaustive multi-pass move finder.
  /// Never passes unless the board is genuinely deadlocked.
  Future<void> _botPlayNormal() async {
    final _BotMove? move = _findBotMoveExhaustive();
    if (move == null) {
      // Board is genuinely deadlocked – no valid move exists.
      await _passTurnInternal();
      return;
    }
    state = state.copyWith(
      selectedPosition: move.start,
      direction: move.direction,
    );

    // Compute the positions this word will occupy for blink animation.
    final List<Position> movePositions = <Position>[];
    Position cursor = move.start;
    for (int i = 0; i < move.word.length; i++) {
      movePositions.add(cursor);
      cursor = cursor.next(move.direction);
    }

    await _submitWordInternal(move.word);

    // Store positions so the UI can blink them.
    state = state.copyWith(lastBotMovePositions: movePositions);
  }

  // ── Grid-slot scanner ──────────────────────────────────────

  /// Scans every row and column within the locked grid bounds and returns
  /// all potential word-placement "slots" – regions that contain at least
  /// one existing letter and at least one empty cell.
  List<_GridSlot> _scanGridSlots() {
    final GridBounds? bounds = state.gridBounds;
    if (bounds == null) {
      return const <_GridSlot>[];
    }

    final List<_GridSlot> slots = <_GridSlot>[];
    final int maxWordLen = 8;
    final int minWordLen = 4;

    // ── Horizontal slots (each row) ──
    for (int y = bounds.minY; y <= bounds.maxY; y++) {
      for (int startX = bounds.minX; startX <= bounds.maxX; startX++) {
        final int maxLen = min(maxWordLen, bounds.maxX - startX + 1);
        for (int len = minWordLen; len <= maxLen; len++) {
          int filled = 0;
          int empty = 0;
          final StringBuffer pattern = StringBuffer();

          for (int dx = 0; dx < len; dx++) {
            final BoardCell? cell =
                state.board.cells[Position(startX + dx, y)];
            if (cell != null) {
              filled++;
              pattern.write(cell.letter);
            } else {
              empty++;
              pattern.write('_');
            }
          }

          if (filled > 0 && empty > 0) {
            slots.add(_GridSlot(
              start: Position(startX, y),
              direction: Direction.horizontal,
              length: len,
              pattern: pattern.toString(),
              filledCount: filled,
              emptyCount: empty,
            ));
          }
        }
      }
    }

    // ── Vertical slots (each column) ──
    for (int x = bounds.minX; x <= bounds.maxX; x++) {
      for (int startY = bounds.minY; startY <= bounds.maxY; startY++) {
        final int maxLen = min(maxWordLen, bounds.maxY - startY + 1);
        for (int len = minWordLen; len <= maxLen; len++) {
          int filled = 0;
          int empty = 0;
          final StringBuffer pattern = StringBuffer();

          for (int dy = 0; dy < len; dy++) {
            final BoardCell? cell =
                state.board.cells[Position(x, startY + dy)];
            if (cell != null) {
              filled++;
              pattern.write(cell.letter);
            } else {
              empty++;
              pattern.write('_');
            }
          }

          if (filled > 0 && empty > 0) {
            slots.add(_GridSlot(
              start: Position(x, startY),
              direction: Direction.vertical,
              length: len,
              pattern: pattern.toString(),
              filledCount: filled,
              emptyCount: empty,
            ));
          }
        }
      }
    }

    // Sort: prefer more-constrained slots (more filled letters) so pattern
    // matching resolves faster and yields better words.
    slots.sort((a, b) => b.filledCount.compareTo(a.filledCount));

    return slots;
  }

  // ── Multi-pass exhaustive bot move finder ──────────────────

  /// Finds the best valid move across three escalating strategies.
  /// When [collectAll] is provided, every valid move found is appended to it
  /// (used for the "available words" feature).  Returns `null` only when the
  /// board is genuinely deadlocked (no legal move exists).
  _BotMove? _findBotMoveExhaustive({List<_BotMove>? collectAll}) {
    final List<_BotMove> topMoves = <_BotMove>[];
    int bestScore = 0;
    final Set<String> seenKeys = <String>{}; // dedup "word@x,y,dir"

    void consider(String word, Position start, Direction dir,
        MoveValidationResult result) {
      // Belt-and-suspenders: never propose a word absent from the dictionary.
      if (!_dictionary.isValidWord(word)) {
        return;
      }
      // Beginner-level bot: only use common, everyday words ≥ 4 letters.
      if (word.length < 4) {
        return;
      }
      if (!_dictionary.isCommonWord(word)) {
        return;
      }
      final String key =
          '$word@${start.x},${start.y},${dir == Direction.horizontal ? 'h' : 'v'}';
      if (!seenKeys.add(key)) {
        return; // duplicate
      }
      final _BotMove move =
          _BotMove(word: word, start: start, direction: dir);
      collectAll?.add(move);
      final int score =
          word.length + result.intersections * 2 + result.newCells;
      if (score > bestScore) {
        bestScore = score;
        topMoves.clear();
        topMoves.add(move);
      } else if (score == bestScore) {
        topMoves.add(move);
      }
    }

    // ── Pass 1: Slot-based pattern matching (most grid-aware) ──
    final List<_GridSlot> slots = _scanGridSlots();
    for (final _GridSlot slot in slots) {
      if (!slot.pattern.contains('_')) {
        continue;
      }
      final List<String> matches = _dictionary.findAllByPattern(
        slot.pattern,
        limit: 15,
        commonFirst: true,
      );
      for (final String word in matches) {
        final MoveValidationResult result = _moveValidator.validatePlacement(
          board: state.board,
          word: word,
          start: slot.start,
          direction: slot.direction,
          requireIntersection: true,
          bounds: state.gridBounds,
        );
        if (result.isValid) {
          consider(word, slot.start, slot.direction, result);
        }
      }
      // Early exit if we already have a strong move and aren't collecting all.
      if (bestScore >= 12 && collectAll == null) {
        return topMoves[Random().nextInt(topMoves.length)];
      }
    }

    if (topMoves.isNotEmpty && collectAll == null) {
      return topMoves[Random().nextInt(topMoves.length)];
    }

    // ── Pass 2: Anchor-based search (common words only for beginner bot) ──
    final List<MapEntry<Position, BoardCell>> anchors =
        state.board.cells.entries.toList();

    for (final MapEntry<Position, BoardCell> anchor in anchors) {
      final String letter = anchor.value.letter;
      final List<String> candidates =
          _dictionary.getWordsForLetter(letter);

      for (final String word in candidates) {
        if (word.length < 4 || word.length > 8) {
          continue;
        }
        for (int i = 0; i < word.length; i++) {
          if (word[i] != letter) {
            continue;
          }

          // Try both directions.
          for (final Direction dir in Direction.values) {
            final Position start = dir == Direction.horizontal
                ? Position(anchor.key.x - i, anchor.key.y)
                : Position(anchor.key.x, anchor.key.y - i);

            final MoveValidationResult result =
                _moveValidator.validatePlacement(
              board: state.board,
              word: word,
              start: start,
              direction: dir,
              requireIntersection: true,
              bounds: state.gridBounds,
            );
            if (result.isValid) {
              consider(word, start, dir, result);
            }
          }
        }
      }
    }

    return topMoves.isEmpty ? null : topMoves[Random().nextInt(topMoves.length)];
  }

  // ── Available-moves helper (for user timeout feedback) ─────

  /// Quickly scans the board for valid moves and returns up to 10 unique
  /// word strings the current player could have played.
  List<String> _computeAvailableWords() {
    if (state.phase != GamePhase.playing || state.gridBounds == null) {
      return const <String>[];
    }

    final List<_BotMove> allMoves = <_BotMove>[];
    _findBotMoveExhaustive(collectAll: allMoves);

    // Deduplicate by word text and return up to 10 unique words.
    final Set<String> unique = <String>{};
    for (final _BotMove move in allMoves) {
      unique.add(move.word);
      if (unique.length >= 10) {
        break;
      }
    }
    return unique.toList();
  }

  // ── Seed overlap helper ───────────────────────────────────

  _SeedPlacement? _buildSecondSeedPlacement(String secondWord) {
    if (state.board.history.isEmpty) {
      return null;
    }
    final PlacedWord first = state.board.history.first;
    if (first.direction != Direction.horizontal) {
      return null;
    }
    for (int j = 0; j < secondWord.length; j++) {
      final String secondLetter = secondWord[j];
      for (int i = 0; i < first.word.length; i++) {
        if (first.word[i] == secondLetter) {
          final int overlapX = first.start.x + i;
          final int overlapY = first.start.y;
          return _SeedPlacement(start: Position(overlapX, overlapY - j));
        }
      }
    }
    return null;
  }

  // ── Pattern helper for ghost hints ────────────────────────

  String _patternAt({
    required Position start,
    required Direction direction,
    required int length,
  }) {
    final StringBuffer buffer = StringBuffer();
    Position cursor = start;
    for (int i = 0; i < length; i++) {
      final BoardCell? cell = state.board.cells[cursor];
      buffer.write(cell?.letter ?? '_');
      cursor = cursor.next(direction);
    }
    return buffer.toString();
  }

  // ── Board ASCII for AI hint ───────────────────────────────

  String _boardToAscii() {
    final BoardState board = state.board;
    if (board.cells.isEmpty) {
      return '(empty)';
    }
    final StringBuffer output = StringBuffer();
    for (int y = board.minY; y <= board.maxY; y++) {
      for (int x = board.minX; x <= board.maxX; x++) {
        output.write(board.cells[Position(x, y)]?.letter ?? '.');
      }
      output.writeln();
    }
    return output.toString();
  }

  // ── Utility ───────────────────────────────────────────────

  String _normalize(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

  String _playerLabel(PlayerId player, {OpponentType? opponentType}) {
    final OpponentType mode = opponentType ?? state.opponentType;
    if (mode == OpponentType.bot) {
      return player == PlayerId.b ? 'Bot' : 'User';
    }
    return player == PlayerId.a ? 'Player A' : 'Player B';
  }

  PlayerId _otherPlayer(PlayerId player) =>
      player == PlayerId.a ? PlayerId.b : PlayerId.a;

  RoundOutcome _outcome(ScoreBoard scoreBoard) {
    if (scoreBoard.playerA > scoreBoard.playerB) {
      return RoundOutcome.playerA;
    }
    if (scoreBoard.playerB > scoreBoard.playerA) {
      return RoundOutcome.playerB;
    }
    return RoundOutcome.tie;
  }

  // ── Live validation ───────────────────────────────────────

  String? _validateDraft(String word) {
    if (word.isEmpty) {
      return null;
    }
    if (word.length < 3) {
      return 'Keep typing (minimum 3 letters).';
    }
    if (!_dictionary.isValidWord(word)) {
      final String? suggestion =
          word.length >= 5 ? _dictionary.suggestClosestWord(word) : null;
      return suggestion == null
          ? 'Live check: not in dictionary yet.'
          : 'Live check: not in dictionary. Did you mean "$suggestion"?';
    }
    final _DraftPlacement? placement = _draftPlacementFor(word);
    if (placement == null) {
      return 'No valid overlap/placement path found.';
    }
    final MoveValidationResult validation = _moveValidator.validatePlacement(
      board: state.board,
      word: word,
      start: placement.start,
      direction: placement.direction,
      requireIntersection: placement.requireIntersection,
      bounds: state.gridBounds,
    );
    if (!validation.isValid) {
      return validation.error;
    }
    return 'Live check: valid move.';
  }

  bool get _isHumanInputEnabled {
    if (state.isPaused || state.phase == GamePhase.finished) {
      return false;
    }
    if (!state.isDictionaryReady || state.isAiThinking) {
      return false;
    }
    if (state.opponentType == OpponentType.bot &&
        state.currentPlayer == PlayerId.b) {
      return false;
    }
    return true;
  }

  _DraftPlacement? _draftPlacementFor(String word) {
    if (state.phase == GamePhase.finished) {
      return null;
    }
    if (state.phase == GamePhase.seedA) {
      return const _DraftPlacement(
        start: Position(0, 0),
        direction: Direction.horizontal,
        requireIntersection: false,
      );
    }
    if (state.phase == GamePhase.seedB) {
      final _SeedPlacement? placement = _buildSecondSeedPlacement(word);
      if (placement == null) {
        return null;
      }
      return _DraftPlacement(
        start: placement.start,
        direction: Direction.vertical,
        requireIntersection: true,
      );
    }
    final Position? start = state.selectedPosition;
    if (start == null) {
      return null;
    }
    return _DraftPlacement(
      start: start,
      direction: state.direction,
      requireIntersection: true,
    );
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }
}

// ── Private data classes ──────────────────────────────────────

class _SeedPlacement {
  const _SeedPlacement({required this.start});
  final Position start;
}

class _BotMove {
  const _BotMove({
    required this.word,
    required this.start,
    required this.direction,
  });

  final String word;
  final Position start;
  final Direction direction;
}

/// A potential word-placement region on the grid.
///
/// [pattern] uses letters for filled cells and '_' for empty cells,
/// e.g. "_E__I_AL".  The slot has at least one filled and one empty cell.
class _GridSlot {
  const _GridSlot({
    required this.start,
    required this.direction,
    required this.length,
    required this.pattern,
    required this.filledCount,
    required this.emptyCount,
  });

  final Position start;
  final Direction direction;
  final int length;
  final String pattern;
  final int filledCount;
  final int emptyCount;
}

class _DraftPlacement {
  const _DraftPlacement({
    required this.start,
    required this.direction,
    required this.requireIntersection,
  });

  final Position start;
  final Direction direction;
  final bool requireIntersection;
}
