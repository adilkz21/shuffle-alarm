import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The orange Stop key. A press calls [onPressed]; holding it for [holdTime]
/// calls [onHeld], the emergency stop that always works. A bar fills along the
/// key and the label counts down, so the hold shows without relying on color.
///
/// It counts from pointer down to pointer up, so a shaky finger that slides a
/// little doesn't start it over. Enter and Space hold it as well, and screen
/// readers get it as a long press.
class HoldToStopKey extends StatefulWidget {
  const new({
    required this.label,
    required this.onPressed,
    required this.onHeld,
    this.holdTime = const Duration(seconds: 5),
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback onHeld;
  final Duration holdTime;

  @override
  State<HoldToStopKey> createState() => _HoldToStopKeyState();
}

class _HoldToStopKeyState extends State<HoldToStopKey>
    with SingleTickerProviderStateMixin {
  late final _hold = AnimationController(vsync: this, duration: widget.holdTime)
    ..addStatusListener((status) {
      if (status == .completed) {
        _startedByKeyboard = false;
        widget.onHeld();
      }
    });
  var _startedByKeyboard = false;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _start() {
    if (!_hold.isAnimating) _hold.forward(from: 0);
  }

  void _cancel() {
    // The finger comes up after the emergency stop has closed this screen.
    if (!mounted) return;
    _hold
      ..stop()
      ..value = 0;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.space) {
      return .ignored;
    }
    if (event is KeyDownEvent) {
      _startedByKeyboard = true;
      _start();
    } else if (event is KeyUpEvent && _startedByKeyboard) {
      _startedByKeyboard = false;
      _cancel();
      widget.onPressed();
    }
    return .handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Semantics(
        onLongPress: widget.onHeld,
        onLongPressHint: 'emergency stop',
        child: Listener(
          onPointerDown: (_) => _start(),
          onPointerUp: (_) => _cancel(),
          onPointerCancel: (_) => _cancel(),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: AnimatedBuilder(
              animation: _hold,
              builder: (context, _) {
                final holding = _hold.value > 0;
                final left = (widget.holdTime.inSeconds * (1 - _hold.value))
                    .ceil();
                return Stack(
                  children: [
                    Positioned.fill(
                      child: FilledButton(
                        onPressed: widget.onPressed,
                        child: FittedBox(
                          fit: .scaleDown,
                          child: Text(
                            holding ? 'Keep holding: $left' : widget.label,
                            textAlign: .center,
                          ),
                        ),
                      ),
                    ),
                    // Sets the height of the key, also with large text.
                    const SizedBox(
                      height: KeyMetrics.minHeight,
                      width: double.infinity,
                    ),
                    Positioned(
                      left: Spacing.lg,
                      right: Spacing.lg,
                      bottom: KeyMetrics.depth + Spacing.xs,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: Align(
                            alignment: .centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _hold.value,
                              child: SizedBox(
                                height: Spacing.xs,
                                child: ColoredBox(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
