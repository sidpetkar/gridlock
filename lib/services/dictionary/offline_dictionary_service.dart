import 'package:flutter/services.dart';

// ── Lightweight Trie for fast prefix / membership / suggestion lookup ──

class _TrieNode {
  final Map<String, _TrieNode> children = <String, _TrieNode>{};
  bool isWord = false;
}

class _Trie {
  final _TrieNode _root = _TrieNode();

  void insert(String word) {
    _TrieNode node = _root;
    for (int i = 0; i < word.length; i++) {
      final String ch = word[i];
      node = node.children.putIfAbsent(ch, () => _TrieNode());
    }
    node.isWord = true;
  }

  bool contains(String word) {
    _TrieNode? node = _root;
    for (int i = 0; i < word.length; i++) {
      node = node?.children[word[i]];
      if (node == null) {
        return false;
      }
    }
    return node?.isWord ?? false;
  }

  bool hasPrefix(String prefix) {
    _TrieNode? node = _root;
    for (int i = 0; i < prefix.length; i++) {
      node = node?.children[prefix[i]];
      if (node == null) {
        return false;
      }
    }
    return true;
  }

  /// Collect all words under [prefix] (up to [limit]).
  List<String> wordsWithPrefix(String prefix, {int limit = 20}) {
    _TrieNode? node = _root;
    for (int i = 0; i < prefix.length; i++) {
      node = node?.children[prefix[i]];
      if (node == null) {
        return const <String>[];
      }
    }
    final List<String> results = <String>[];
    _collect(node!, prefix, results, limit);
    return results;
  }

  void _collect(
    _TrieNode node,
    String current,
    List<String> results,
    int limit,
  ) {
    if (results.length >= limit) {
      return;
    }
    if (node.isWord) {
      results.add(current);
    }
    for (final MapEntry<String, _TrieNode> entry in node.children.entries) {
      _collect(entry.value, current + entry.key, results, limit);
      if (results.length >= limit) {
        return;
      }
    }
  }
}

// ── Dictionary service ──────────────────────────────────────────────────

class OfflineDictionaryService {
  final _Trie _trie = _Trie();
  Set<String> _words = <String>{};
  List<String> _wordList = <String>[];
  Set<String> _commonWords = <String>{};
  final Map<int, List<String>> _wordsByLength = <int, List<String>>{};

  /// Common words indexed by each letter they contain (3-8 letters only).
  final Map<String, List<String>> _commonByLetter = <String, List<String>>{};

  /// Full dictionary words indexed by letter (3-8 letters), used as fallback.
  final Map<String, List<String>> _allByLetter = <String, List<String>>{};

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get words => _wordList;

  Future<void> ensureLoaded() async {
    if (_isLoaded) {
      return;
    }

    // Load full dictionary.
    final String raw = await rootBundle.loadString(
      'assets/dictionary/words_en.txt',
    );
    final List<String> parsed =
        raw
            .split(RegExp(r'\r?\n'))
            .map((line) => line.trim().toUpperCase())
            .where(
              (line) => line.length >= 2 && RegExp(r'^[A-Z]+$').hasMatch(line),
            )
            .toSet()
            .toList()
          ..sort((a, b) => a.length.compareTo(b.length));
    _wordList = parsed;
    _words = parsed.toSet();

    // Insert all words into Trie.
    for (final String word in _wordList) {
      _trie.insert(word);
    }

    // Load common words.
    final String commonRaw = await rootBundle.loadString(
      'assets/dictionary/common_words.txt',
    );
    final Set<String> commonParsed = commonRaw
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim().toUpperCase())
        .where(
          (line) => line.length >= 2 && RegExp(r'^[A-Z]+$').hasMatch(line),
        )
        .toSet();

    // Compute common words as those present in BOTH files (before union).
    // This ensures abbreviations only in common_words.txt don't qualify.
    _commonWords = commonParsed.where((w) => _words.contains(w)).toSet();

    // Union: add any common word missing from the main dictionary so that
    // words like MIAMI (only in common_words.txt) are always playable
    // for human players.
    for (final String cw in commonParsed) {
      if (_words.add(cw)) {
        _trie.insert(cw);
        _wordList.add(cw);
      }
    }

    // Build indexes.
    _wordsByLength.clear();
    _commonByLetter.clear();
    _allByLetter.clear();

    for (final String word in _wordList) {
      _wordsByLength.putIfAbsent(word.length, () => <String>[]).add(word);
      if (word.length >= 3 && word.length <= 8) {
        _indexByLetter(word, _allByLetter);
      }
    }

    // Index common words by letter for bot priority.
    for (final String word in _commonWords) {
      if (word.length >= 3 && word.length <= 8) {
        _indexByLetter(word, _commonByLetter);
      }
    }

    _isLoaded = true;
  }

  void _indexByLetter(String word, Map<String, List<String>> index) {
    final Set<String> seen = <String>{};
    for (int i = 0; i < word.length; i++) {
      final String ch = word[i];
      if (seen.add(ch)) {
        index.putIfAbsent(ch, () => <String>[]).add(word);
      }
    }
  }

  bool isValidWord(String word) {
    return _trie.contains(word.toUpperCase());
  }

  bool isCommonWord(String word) {
    return _commonWords.contains(word.toUpperCase());
  }

  bool hasPrefix(String prefix) {
    return _trie.hasPrefix(prefix.toUpperCase());
  }

  List<String> autocomplete(String prefix, {int limit = 10}) {
    return _trie.wordsWithPrefix(prefix.toUpperCase(), limit: limit);
  }

  /// Bot-priority candidates: common words first, then full dictionary fallback.
  List<String> getWordsForLetter(String letter) {
    final String ch = letter.toUpperCase();
    return _commonByLetter[ch] ?? const <String>[];
  }

  /// Full dictionary fallback for a letter.
  List<String> getAllWordsForLetter(String letter) {
    final String ch = letter.toUpperCase();
    return _allByLetter[ch] ?? const <String>[];
  }

  String? findByPattern(String pattern) {
    final String uppercase = pattern.toUpperCase();
    final RegExp regex = RegExp('^${uppercase.replaceAll('_', '[A-Z]')}\$');
    // Try common words first.
    for (final String word in _commonWords) {
      if (word.length == uppercase.length && regex.hasMatch(word)) {
        return word;
      }
    }
    for (final String word in _wordList) {
      if (word.length == uppercase.length && regex.hasMatch(word)) {
        return word;
      }
    }
    return null;
  }

  /// Return **all** words matching a pattern (e.g. "_E_MI_AL").
  /// Underscore = any letter.  Common words come first when
  /// [commonFirst] is true.  Results are capped at [limit].
  List<String> findAllByPattern(
    String pattern, {
    int limit = 50,
    bool commonFirst = true,
  }) {
    final String uppercase = pattern.toUpperCase();
    if (!uppercase.contains('_')) {
      // Fully specified – just check membership.
      if (_words.contains(uppercase)) {
        return <String>[uppercase];
      }
      return const <String>[];
    }

    final RegExp regex = RegExp('^${uppercase.replaceAll('_', '[A-Z]')}\$');
    final int targetLen = uppercase.length;
    final List<String> results = <String>[];
    final Set<String> seen = <String>{};

    // Pre-filter by length for speed.
    if (commonFirst) {
      final List<String>? bucket = _wordsByLength[targetLen];
      if (bucket != null) {
        for (final String word in bucket) {
          if (_commonWords.contains(word) && regex.hasMatch(word)) {
            if (seen.add(word)) {
              results.add(word);
              if (results.length >= limit) {
                return results;
              }
            }
          }
        }
      }
    }

    final List<String>? bucket = _wordsByLength[targetLen];
    if (bucket != null) {
      for (final String word in bucket) {
        if (regex.hasMatch(word) && seen.add(word)) {
          results.add(word);
          if (results.length >= limit) {
            return results;
          }
        }
      }
    }

    return results;
  }

  /// Retrieve all words of a specific [length].
  List<String> getWordsByLength(int length) {
    return _wordsByLength[length] ?? const <String>[];
  }

  String? suggestClosestWord(String word, {int maxDistance = 2}) {
    final String target = word.toUpperCase();
    if (target.length < 3) {
      return null;
    }
    if (_words.contains(target)) {
      return target;
    }

    String? best;
    int bestDistance = maxDistance + 1;
    final int minLength = target.length - maxDistance;
    final int maxLengthAllowed = target.length + maxDistance;

    for (int length = minLength; length <= maxLengthAllowed; length++) {
      final List<String>? bucket = _wordsByLength[length];
      if (bucket == null) {
        continue;
      }
      for (final String candidate in bucket) {
        if (candidate[0] != target[0]) {
          continue;
        }
        final int distance = _levenshteinLimited(
          target,
          candidate,
          bestDistance - 1,
        );
        if (distance >= 0 && distance < bestDistance) {
          bestDistance = distance;
          best = candidate;
          if (bestDistance == 1) {
            return best;
          }
        }
      }
    }
    return best;
  }

  int _levenshteinLimited(String a, String b, int maxDistance) {
    if ((a.length - b.length).abs() > maxDistance) {
      return -1;
    }
    List<int> previous = List<int>.generate(b.length + 1, (i) => i);
    for (int i = 1; i <= a.length; i++) {
      final List<int> current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      int minInRow = current[0];
      for (int j = 1; j <= b.length; j++) {
        final int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = _min3(
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        );
        if (current[j] < minInRow) {
          minInRow = current[j];
        }
      }
      if (minInRow > maxDistance) {
        return -1;
      }
      previous = current;
    }
    return previous[b.length] <= maxDistance ? previous[b.length] : -1;
  }

  int _min3(int a, int b, int c) {
    int min = a < b ? a : b;
    if (c < min) {
      min = c;
    }
    return min;
  }
}
