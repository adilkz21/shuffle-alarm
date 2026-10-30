import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/core/ring_run.dart';
import 'package:shuffle_alarm/features/ringing/try_ring.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/platform/motion_sensor.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The Alarms tab: no alarm list yet (PLAN.md, later stages), but "Try a ring"
/// lets a tester feel one.
class AlarmsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = ref.watch(tryRingProvider);
    return AppPage(
      title: 'Alarms',
      subtitle: 'Wake up to something new',
      actions: const [SettingsButton()],
      body: switch (ring.phase) {
        .waiting => _Waiting(snoozeLeft: ring.snoozeLeft),
        .idle || .ringing => _TryARing(lastEnd: ring.lastEnd),
      },
    );
  }
}

/// A ring is on its way. The screen doesn't say when, so it is a surprise.
class _Waiting extends ConsumerWidget {
  const new({required this.snoozeLeft});

  final Duration? snoozeLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = snoozeLeft;
    return EmptyState(
      readout: left == null ? '--:--' : _minutesAndSeconds(left),
      caption: left == null ? 'Ring on its way' : 'Snoozed',
      title: left == null ? 'Lie down and close your eyes' : 'Snoozed',
      message: left == null
          ? 'It rings at a random moment in the next 5 minutes. Keep this '
                'page open.'
          : 'It rings again soon. Keep this page open.',
      action: OutlinedButton(
        onPressed: ref.read(tryRingProvider.notifier).cancelWaiting,
        child: const Text('Cancel'),
      ),
    );
  }
}

String _minutesAndSeconds(Duration time) {
  final seconds = time.inSeconds.clamp(0, 3599);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(seconds ~/ 60)}:${two(seconds % 60)}';
}

/// When the ring should come.
enum _When { now, randomMoment }

/// "Try a ring", then when it should ring, then, only where the browser asks
/// for it first, why it asks for the motion sensor.
class _TryARing extends ConsumerStatefulWidget {
  const new({required this.lastEnd});

  final RingEnd? lastEnd;

  @override
  ConsumerState<_TryARing> createState() => _TryARingState();
}

class _TryARingState extends ConsumerState<_TryARing> {
  var _choosing = false;
  _When? _explaining;

  void _start(_When when) {
    final ring = ref.read(tryRingProvider.notifier);
    switch (when) {
      case .now:
        ring.ringNow().ignore();
      case .randomMoment:
        ring.ringAtRandomMoment().ignore();
    }
  }

  void _choose(_When when) {
    if (ref.read(motionSensorProvider).needsPermission) {
      setState(() => _explaining = when);
    } else {
      _start(when);
    }
  }

  void _allowMotion(_When when) {
    // Both have to start straight from this tap.
    ref.read(motionSensorProvider).requestPermission().ignore();
    _start(when);
  }

  @override
  Widget build(BuildContext context) {
    final caption = switch (widget.lastEnd) {
      null => 'No alarm set',
      .taskDone => 'Last try: task done',
      .emergencyStop => 'Last try: emergency stop',
      .cap => 'Last try: missed, it hit the 10-minute cap',
      .snoozed => 'Last try: snoozed',
    };
    if (_explaining case final chosen?) {
      return EmptyState(
        readout: '--:--',
        caption: caption,
        title: 'One task uses motion',
        message:
            'The Move task counts your movement with the motion sensor. Your '
            'browser will ask if that’s OK. Nothing leaves this device.',
        action: Column(
          crossAxisAlignment: .stretch,
          spacing: Spacing.md,
          children: [
            FilledButton(
              onPressed: () => _allowMotion(chosen),
              child: const Text('Continue'),
            ),
            OutlinedButton(
              onPressed: () => _start(chosen),
              child: const Text('Skip the Move task'),
            ),
          ],
        ),
      );
    }
    return EmptyState(
      readout: '--:--',
      caption: caption,
      title: 'No alarms yet',
      message: 'Each one plays a new sound every 30 seconds until you’re up.',
      action: _choosing
          ? Column(
              crossAxisAlignment: .stretch,
              spacing: Spacing.md,
              children: [
                FilledButton(
                  onPressed: () => _choose(.now),
                  child: const Text('Ring now'),
                ),
                OutlinedButton(
                  onPressed: () => _choose(.randomMoment),
                  child: const Text('Within 5 minutes'),
                ),
              ],
            )
          : FilledButton(
              onPressed: () => setState(() => _choosing = true),
              child: const Text('Try a ring'),
            ),
    );
  }
}
