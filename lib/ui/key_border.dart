import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The shape of a physical key: a rounded face with an edge under it, both
/// drawn in the outline's color. [travel] says how far the key is pushed
/// in: at 0 the whole edge shows, at [depth] the key has sunk and the edge
/// is hidden. The face moves down with it, and so does content laid out
/// with [dimensions].
///
/// The button themes in `theme.dart` give it to every Material button, so
/// buttons look and press like keys. Why: docs/DECISIONS.md (D15).
class KeyBorder extends OutlinedBorder {
  const new({
    super.side,
    this.borderRadius = const BorderRadius.all(Radius.circular(Corners.key)),
    this.depth = KeyMetrics.depth,
    this.travel = 0,
  }) : assert(depth >= 0, 'depth must not be negative'),
       assert(travel >= 0 && travel <= depth, 'travel must be within depth');

  final BorderRadius borderRadius;

  /// Height of the edge under the face.
  final double depth;

  /// How far the key is pushed in, from 0 to [depth].
  final double travel;

  /// Where the face is when the whole key fills [rect].
  Rect faceOf(Rect rect) => Rect.fromLTRB(
    rect.left,
    rect.top + travel,
    rect.right,
    rect.bottom - depth + travel,
  );

  /// The face and the part of the edge that shows under it.
  Rect _footprintOf(Rect rect) =>
      Rect.fromLTRB(rect.left, rect.top + travel, rect.right, rect.bottom);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(
    left: side.strokeInset,
    top: side.strokeInset + travel,
    right: side.strokeInset,
    bottom: side.strokeInset + depth - travel,
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      borderRadius.toRRect(_footprintOf(rect)).deflate(side.strokeInset),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.toRRect(_footprintOf(rect)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final paint = Paint()..color = side.color;
    final footprint = borderRadius.toRRect(_footprintOf(rect));
    if (travel < depth) {
      // The footprint minus the face is the edge.
      canvas.drawDRRect(footprint, borderRadius.toRRect(faceOf(rect)), paint);
    }
    if (side.width > 0) {
      canvas.drawDRRect(
        footprint.inflate(side.strokeOutset),
        footprint.deflate(side.strokeInset),
        paint,
      );
    }
  }

  @override
  KeyBorder copyWith({
    BorderSide? side,
    BorderRadius? borderRadius,
    double? depth,
    double? travel,
  }) => KeyBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    depth: depth ?? this.depth,
    travel: travel ?? this.travel,
  );

  @override
  ShapeBorder scale(double t) => KeyBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    depth: depth * t,
    travel: travel * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is KeyBorder ? _lerpKeys(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is KeyBorder ? _lerpKeys(this, b, t) : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is KeyBorder &&
      other.side == side &&
      other.borderRadius == borderRadius &&
      other.depth == depth &&
      other.travel == travel;

  @override
  int get hashCode => Object.hash(side, borderRadius, depth, travel);

  @override
  String toString() =>
      'KeyBorder($side, $borderRadius, depth: $depth, travel: $travel)';
}

/// The key between [a] and [b]; at 0.5 a key going down is half sunk.
KeyBorder _lerpKeys(KeyBorder a, KeyBorder b, double t) => KeyBorder(
  side: BorderSide.lerp(a.side, b.side, t),
  borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
  depth: lerpDouble(a.depth, b.depth, t)!,
  travel: lerpDouble(a.travel, b.travel, t)!,
);
