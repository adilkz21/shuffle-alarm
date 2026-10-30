import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// One tab of a [KeyTabBar].
class KeyTab {
  const new({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The tabs as keys in a tray. The open tab stays pressed in and its light
/// is on, like a preset button on a radio, so it differs in shape and not
/// only in color. Why: docs/DECISIONS.md (D15).
class KeyTabBar extends StatelessWidget {
  const new({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Marks the light on the open tab.
  static const lightKey = Key('KeyTabBar.light');

  final List<KeyTab> tabs;

  /// The open tab.
  final int selectedIndex;

  /// Called with the index of the tab that was tapped.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceColors.of(context).tray,
        borderRadius: const BorderRadius.all(Radius.circular(Corners.panel)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.sm),
        child: Row(
          crossAxisAlignment: .end,
          spacing: Spacing.sm,
          children: [
            for (final (index, tab) in tabs.indexed)
              Expanded(
                child: _TabKey(
                  tab: tab,
                  open: index == selectedIndex,
                  onPressed: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tab as a neutral key; the theme keeps a selected key pressed in.
class _TabKey extends StatefulWidget {
  const new({required this.tab, required this.open, required this.onPressed});

  final KeyTab tab;
  final bool open;
  final VoidCallback onPressed;

  @override
  State<_TabKey> createState() => _TabKeyState();
}

class _TabKeyState extends State<_TabKey> {
  late final _states = WidgetStatesController({
    if (widget.open) WidgetState.selected,
  });

  @override
  void didUpdateWidget(_TabKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    _states.update(WidgetState.selected, widget.open);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        selected: widget.open,
        child: OutlinedButton(
          statesController: _states,
          onPressed: widget.onPressed,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size.fromHeight(KeyMetrics.tabHeight),
            ),
            textStyle: WidgetStatePropertyAll(text.labelMedium),
            iconSize: const WidgetStatePropertyAll(KeyMetrics.icon),
          ),
          child: Column(
            mainAxisSize: .min,
            spacing: Spacing.xs,
            children: [
              SizedBox.square(
                dimension: KeyMetrics.light,
                child: widget.open
                    ? const _Light(key: KeyTabBar.lightKey)
                    : null,
              ),
              Icon(widget.tab.icon),
              FittedBox(fit: .scaleDown, child: Text(widget.tab.label)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lit dot on the open tab.
class _Light extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const CircleBorder(),
        color: DeviceColors.of(context).led,
      ),
    );
  }
}
