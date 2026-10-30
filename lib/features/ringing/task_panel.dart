import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/core/wake_up_task.dart';
import 'package:shuffle_alarm/features/ringing/try_ring.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The running wake-up task: what to do, how far it is, its keys and the way
/// to an easier task.
class TaskPanel extends ConsumerWidget {
  const new({
    required this.task,
    required this.now,
    required this.lastResponse,
    required this.canTakeEasierTask,
    super.key,
  });

  final WakeUpTask task;
  final Duration now;
  final TaskResponse? lastResponse;
  final bool canTakeEasierTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    final secondsLeft = (task.deadline - now).inSeconds.clamp(
      0,
      task.timeLimit.inSeconds,
    );
    final response = switch (lastResponse) {
      .right => 'Yes!',
      .wrong => 'Not that one',
      _ => '',
    };
    return Column(
      crossAxisAlignment: .stretch,
      spacing: Spacing.sm,
      children: [
        Semantics(
          header: true,
          child: Text(_title(task), style: text.titleLarge),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            '${_progress(task)}${response.isEmpty ? '' : ' · $response'}',
            style: text.titleSmall,
          ),
        ),
        Text(
          '$secondsLeft s left',
          style: text.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: Spacing.xs),
        switch (task) {
          final WhichSoundTask task => _WhichSoundKeys(task: task),
          CatchTheChangeTask() => OutlinedButton(
            onPressed: ref.read(tryRingProvider.notifier).tapCatchTheChange,
            child: const Text('It changed!'),
          ),
          MoveTask() => Text(
            'Walk around, or swing your arm with the phone in your hand.',
            style: text.bodyLarge,
          ),
          final LitKeyTask task => _LitKeys(task: task),
        },
        if (canTakeEasierTask)
          Align(
            child: TextButton(
              onPressed: ref.read(tryRingProvider.notifier).takeEasierTask,
              child: const Text('Try an easier task'),
            ),
          ),
      ],
    );
  }
}

String _title(WakeUpTask task) => switch (task) {
  WhichSoundTask() => 'Which sound is playing?',
  CatchTheChangeTask() => 'Tap when the sound changes',
  MoveTask() => 'Move for ${MoveTask.secondsNeeded} seconds',
  LitKeyTask() => 'Press the lit key',
};

String _progress(WakeUpTask task) => switch (task) {
  WhichSoundTask() => '${task.progress} of ${task.progressNeeded} in a row',
  CatchTheChangeTask() => '${task.progress} of ${task.progressNeeded} caught',
  MoveTask() => '${task.progress} of ${task.progressNeeded} seconds',
  LitKeyTask() => '${task.progress} of ${task.progressNeeded} presses',
};

class _WhichSoundKeys extends ConsumerWidget {
  const new({required this.task});

  final WhichSoundTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // While the new sound is on its way, the keys wait with no titles, so
    // nothing on the page jumps under a half-awake thumb.
    final waiting = task.options.isEmpty || task.wantsNewSound;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: Spacing.sm,
      children: [
        if (waiting)
          for (var i = 0; i < WhichSoundTask.optionCount; i++)
            const OutlinedButton(onPressed: null, child: Text('…'))
        else
          for (final option in task.options)
            OutlinedButton(
              onPressed: () =>
                  ref.read(tryRingProvider.notifier).answerWhichSound(option),
              child: Text(option.title),
            ),
      ],
    );
  }
}

class _LitKeys extends ConsumerWidget {
  const new({required this.task});

  final LitKeyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // All three keys take the height of the lit one, so none jumps when the
    // light moves.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        spacing: Spacing.sm,
        children: [
          for (var key = 0; key < LitKeyTask.keyCount; key++)
            Expanded(
              child: Semantics(
                label: key == task.litKey
                    ? 'Lit key'
                    : 'Key ${key + 1}, not lit',
                excludeSemantics: true,
                button: true,
                onTap: () =>
                    ref.read(tryRingProvider.notifier).pressLitKey(key),
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(tryRingProvider.notifier).pressLitKey(key),
                  // The lit key differs by its icon and word too, not only by
                  // its color (D15).
                  child: key == task.litKey
                      ? const FittedBox(
                          fit: .scaleDown,
                          child: Column(
                            children: [
                              Icon(Icons.lightbulb_rounded),
                              Text('LIT'),
                            ],
                          ),
                        )
                      : const Text('–'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
