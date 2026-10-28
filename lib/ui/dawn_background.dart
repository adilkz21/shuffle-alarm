import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/theme.dart';

/// The sky behind every page: a gradient from top to bottom, with a sunrise
/// glow rising from the bottom edge.
class DawnBackground extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sky = skyFor(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky.gradient,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            // Below the bottom edge, so only the top of the glow shows.
            center: const Alignment(0, 1.4),
            radius: 1.2,
            colors: [sky.glow, sky.glow.withValues(alpha: 0)],
          ),
        ),
        child: child,
      ),
    );
  }
}
