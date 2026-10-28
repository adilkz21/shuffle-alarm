import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/sunrise_badge.dart';

/// What a page shows while it has nothing to list yet: the sunrise
/// illustration, a title and one friendly line.
class EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      // Scrolls instead of overflowing on small screens with large text.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: .min,
            children: [
              SunriseBadge(icon: icon),
              const SizedBox(height: 28),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: .center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: .center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
