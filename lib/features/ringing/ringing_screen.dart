import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/ringing/hold_to_stop_key.dart';
import 'package:shuffle_alarm/features/ringing/task_panel.dart';
import 'package:shuffle_alarm/features/ringing/try_ring.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/display_panel.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The ringing screen: a big clock, the playing sound, Stop and Snooze. Stop
/// opens a wake-up task; holding it for 5 s is the emergency stop. Why:
/// docs/DECISIONS.md (D17).
class RingingScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = ref.watch(tryRingProvider);
    final controls = ref.read(tryRingProvider.notifier);
    final run = ring.run;
    final task = run?.task;
    return PopScope(
      canPop: false,
      child: AppPage(
        title: 'Wake up',
        body: Column(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: MaxWidths.text),
                    child: Column(
                      crossAxisAlignment: .stretch,
                      spacing: Spacing.lg,
                      children: [
                        _Display(
                          soundTitle: run?.playing?.sound.title,
                          showsTitle: run?.showsSoundTitle ?? true,
                        ),
                        if (run?.soundFailing ?? false)
                          Semantics(
                            liveRegion: true,
                            child: Column(
                              children: [
                                const Text('The sound can’t play.'),
                                TextButton(
                                  onPressed: controls.turnSoundOn,
                                  child: const Text('Turn the sound on'),
                                ),
                              ],
                            ),
                          ),
                        if (task != null)
                          TaskPanel(
                            task: task,
                            now: ring.now,
                            lastResponse: ring.lastResponse,
                            canTakeEasierTask: run?.canTakeEasierTask ?? false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.all(Spacing.lg),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: MaxWidths.tabBar),
                  child: Row(
                    spacing: Spacing.md,
                    children: [
                      // Gone during a task, so a half-awake tap can't snooze
                      // by mistake.
                      if (task == null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controls.snooze,
                            // On one line on the narrowest screens as well.
                            child: const FittedBox(
                              fit: .scaleDown,
                              child: Text('Snooze'),
                            ),
                          ),
                        ),
                      Expanded(
                        child: HoldToStopKey(
                          label: task == null ? 'Stop' : 'Hold 5 s to stop',
                          onPressed: controls.pressStop,
                          onHeld: controls.emergencyStop,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Display extends StatelessWidget {
  const new({required this.soundTitle, required this.showsTitle});

  final String? soundTitle;
  final bool showsTitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final device = DeviceColors.of(context);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.now(),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final label = !showsTitle ? 'Sound hidden' : soundTitle ?? 'Starting…';
    return DisplayPanel(
      child: Column(
        spacing: Spacing.md,
        children: [
          FittedBox(
            fit: .scaleDown,
            child: Text(
              time,
              style: text.displayLarge?.copyWith(color: device.readout),
            ),
          ),
          Text(
            label,
            textAlign: .center,
            style: text.titleLarge?.copyWith(color: device.readout),
          ),
        ],
      ),
    );
  }
}
