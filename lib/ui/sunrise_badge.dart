import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/theme.dart';

/// The Dawn illustration: a warm sun with an icon in the middle and sound
/// waves around it. Drawn in code, so there are no image files to license.
class SunriseBadge extends StatelessWidget {
  const new({required this.icon, this.size = 176, super.key});

  final IconData icon;

  /// Width and height, including the sound waves.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sun = size * 0.46;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SoundWavesPainter(
          primary: colors.primary,
          secondary: colors.secondary,
          tertiary: colors.tertiary,
        ),
        child: Center(
          child: Container(
            width: sun,
            height: sun,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: sunColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: sunColors.last.withValues(alpha: 0.35),
                  blurRadius: sun * 0.6,
                ),
              ],
            ),
            child: Icon(icon, size: sun * 0.46, color: onSun),
          ),
        ),
      ),
    );
  }
}

/// Three rings around the sun, fading outwards, with a few dots drifting
/// off like notes.
class _SoundWavesPainter extends CustomPainter {
  new({required this.primary, required this.secondary, required this.tertiary});

  final Color primary;
  final Color secondary;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final (scale, color, alpha) in [
      (0.62, primary, 0.45),
      (0.80, secondary, 0.30),
      (1.0, primary, 0.16),
    ]) {
      canvas.drawCircle(
        center,
        radius * scale,
        ring..color = color.withValues(alpha: alpha),
      );
    }
    for (final (angle, scale, color) in [
      (-0.7, 1.0, secondary),
      (2.5, 0.80, tertiary),
      (1.2, 1.0, primary),
    ]) {
      canvas.drawCircle(
        center + Offset.fromDirection(angle, radius * scale),
        3.5,
        Paint()..color = color.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_SoundWavesPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.tertiary != tertiary;
}
