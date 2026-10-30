import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/display_panel.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// What a page shows while it has nothing to list yet: its display with
/// dashes, like a clock that isn't set, then a title and one friendly line.
class EmptyState extends StatelessWidget {
  const new({
    required this.readout,
    required this.caption,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  /// Big on the display, such as `--:--`. Screen readers skip it and read
  /// [caption] instead.
  final String readout;

  /// A short label under the readout, shown in capitals.
  final String caption;

  final String title;
  final String message;

  /// Keys under the message.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final device = DeviceColors.of(context);
    return Center(
      // Scrolls instead of overflowing on small screens with large text.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: MaxWidths.text),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              DisplayPanel(
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: FittedBox(
                        fit: .scaleDown,
                        child: Text(
                          readout,
                          style: text.displayMedium?.copyWith(
                            color: device.readout,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      caption.toUpperCase(),
                      semanticsLabel: caption,
                      textAlign: .center,
                      style: text.labelSmall?.copyWith(
                        color: device.displayLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(title, style: text.headlineSmall, textAlign: .center),
              const SizedBox(height: Spacing.sm),
              Text(
                message,
                style: text.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: .center,
              ),
              if (action case final action?) ...[
                const SizedBox(height: Spacing.xl),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
