import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The clock radio's display: a dark window where times, sounds and codes
/// show in amber. It stays dark in both modes. Text and icons inside are
/// amber unless their own style says otherwise. Why: docs/DECISIONS.md
/// (D15).
class DisplayPanel extends StatelessWidget {
  const new({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Spacing.lg,
      vertical: Spacing.xl,
    ),
    super.key,
  });

  final Widget child;

  /// Space between the rim and [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final device = DeviceColors.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: device.display,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(Corners.panel)),
          side: BorderSide(color: device.displayBorder),
        ),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyLarge!
              .copyWith(color: device.readout),
          child: IconTheme.merge(
            data: IconThemeData(color: device.readout),
            child: child,
          ),
        ),
      ),
    );
  }
}
