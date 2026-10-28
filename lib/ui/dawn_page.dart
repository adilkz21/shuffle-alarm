import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/dawn_background.dart';

/// A full page in the Dawn look: the sky background, a large serif title
/// with an optional subtitle, and the page content.
class DawnPage extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.actions = const [],
    super.key,
  });

  final String title;

  /// A short line under the title.
  final String? subtitle;

  /// Replaces the automatic back button.
  final Widget? leading;

  final List<Widget> actions;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DawnBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: leading,
          actions: actions,
          title: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(title),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // The bottom inset includes the floating tab bar, if there is one.
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}
