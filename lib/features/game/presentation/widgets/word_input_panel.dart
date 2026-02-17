import 'package:flutter/material.dart';

import '../../../../services/haptic_service.dart';
import '../../application/game_controller.dart';

class WordInputPanel extends StatefulWidget {
  const WordInputPanel({
    super.key,
    required this.phase,
    required this.onSubmit,
    required this.onChanged,
    required this.onPass,
    required this.onOfflineHint,
    required this.onAiHint,
    required this.isAiThinking,
    required this.liveValidationMessage,
    required this.inputNonce,
    required this.isInputEnabled,
    required this.inputFocusNode,
  });

  final GamePhase phase;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onChanged;
  final VoidCallback onPass;
  final VoidCallback onOfflineHint;
  final VoidCallback onAiHint;
  final bool isAiThinking;
  final String? liveValidationMessage;
  final int inputNonce;
  final bool isInputEnabled;
  final FocusNode inputFocusNode;

  @override
  State<WordInputPanel> createState() => _WordInputPanelState();
}

class _WordInputPanelState extends State<WordInputPanel> {
  late final TextEditingController _wordController;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController();
    // Auto-focus the text field when widget first appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isInputEnabled) {
        widget.inputFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WordInputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inputNonce != oldWidget.inputNonce) {
      _wordController.clear();
    }
    // Auto-focus when input becomes enabled (e.g. after bot turn).
    if (widget.isInputEnabled && !oldWidget.isInputEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.inputFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiveValid =
        widget.liveValidationMessage == 'Live check: valid move.';

    const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Controls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _wordController,
              focusNode: widget.inputFocusNode,
              enabled: widget.isInputEnabled,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: widget.onSubmit,
              onChanged: widget.onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Type your word here',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF9CA3AF),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          if (widget.liveValidationMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.liveValidationMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isLiveValid
                    ? const Color(0xFF166534)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // ── Button grid: 2x2, equal width ──
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: widget.isInputEnabled
                      ? () {
                          HapticService.heavyTap();
                          widget.onSubmit(_wordController.text);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    shape: buttonShape,
                    backgroundColor: const Color(0xFF111111),
                  ),
                  child: const Text('Submit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isInputEnabled
                      ? () {
                          HapticService.mediumTap();
                          widget.onPass();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(shape: buttonShape),
                  child: const Text('Pass'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isInputEnabled
                      ? () {
                          HapticService.lightTap();
                          widget.onOfflineHint();
                        }
                      : null,
                  style: OutlinedButton.styleFrom(shape: buttonShape),
                  child: const Text('Ghost hint'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      widget.isInputEnabled && !widget.isAiThinking
                          ? () {
                              HapticService.lightTap();
                              widget.onAiHint();
                            }
                          : null,
                  style: OutlinedButton.styleFrom(shape: buttonShape),
                  child: Text(widget.isAiThinking ? 'Thinking...' : 'AI hint'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
