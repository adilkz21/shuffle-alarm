import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/key_border.dart';

const _rect = Rect.fromLTWH(0, 0, 120, 60);
const _side = BorderSide(width: 1.5, color: Color(0xFF776F63));
const _depth = 6.0;

void main() {
  test('a raised key fills its box, with the edge under the face', () {
    const key = KeyBorder(side: _side, depth: _depth);

    expect(key.getOuterPath(_rect).getBounds(), _rect);
    expect(key.faceOf(_rect), const Rect.fromLTRB(0, 0, 120, 54));
  });

  test('a pressed key sinks by its depth and hides the edge', () {
    const key = KeyBorder(side: _side, depth: _depth, travel: _depth);

    const sunk = Rect.fromLTRB(0, 6, 120, 60);
    expect(key.getOuterPath(_rect).getBounds(), sunk);
    expect(key.faceOf(_rect), sunk);
  });

  test('content insets follow the face', () {
    expect(
      const KeyBorder(side: _side, depth: _depth).dimensions,
      const EdgeInsets.only(left: 1.5, top: 1.5, right: 1.5, bottom: 7.5),
    );
    expect(
      const KeyBorder(side: _side, depth: _depth, travel: _depth).dimensions,
      const EdgeInsets.only(left: 1.5, top: 7.5, right: 1.5, bottom: 1.5),
    );
  });

  test('halfway between raised and pressed is half sunk', () {
    final lerped = ShapeBorder.lerp(
      const KeyBorder(side: _side, depth: _depth),
      const KeyBorder(side: _side, depth: _depth, travel: _depth),
      0.5,
    );

    expect(lerped, isA<KeyBorder>());
    expect((lerped! as KeyBorder).travel, 3);
  });

  test('the inner path sits inside the outline', () {
    const key = KeyBorder(side: _side, depth: _depth);

    expect(
      key.getInnerPath(_rect).getBounds(),
      const Rect.fromLTRB(1.5, 1.5, 118.5, 58.5),
    );
  });

  test('blends with other shapes in both directions', () {
    const key = KeyBorder(side: _side, depth: _depth);
    const other = RoundedRectangleBorder();

    expect(ShapeBorder.lerp(key, other, 0), isNotNull);
    expect(ShapeBorder.lerp(other, key, 1), isNotNull);
    expect(key.lerpTo(key, 0.5), key);
  });

  test('copyWith without values changes nothing', () {
    const key = KeyBorder(side: _side, depth: _depth, travel: 2);

    expect(key.copyWith(), key);
  });

  test('toString names the depth and travel', () {
    expect(
      const KeyBorder(side: _side, depth: _depth, travel: 2).toString(),
      allOf(contains('depth: 6.0'), contains('travel: 2.0')),
    );
  });

  test('copyWith keeps the depth, travel and corners', () {
    const key = KeyBorder(
      side: _side,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      depth: _depth,
      travel: _depth,
    );

    final copy = key.copyWith(side: const BorderSide(width: 3));

    expect(copy.side.width, 3);
    expect(copy.depth, _depth);
    expect(copy.travel, _depth);
    expect(copy.borderRadius, key.borderRadius);
  });

  test('scale grows the outline, corners, depth and travel', () {
    const key = KeyBorder(
      side: _side,
      borderRadius: BorderRadius.all(Radius.circular(10)),
      depth: _depth,
      travel: _depth,
    );

    final scaled = key.scale(2) as KeyBorder;

    expect(scaled.side.width, 3);
    expect(scaled.borderRadius, const BorderRadius.all(Radius.circular(20)));
    expect(scaled.depth, 12);
    expect(scaled.travel, 12);
  });

  test('keys with the same values are equal', () {
    expect(
      const KeyBorder(side: _side, depth: _depth),
      const KeyBorder(side: _side, depth: _depth),
    );
    expect(
      const KeyBorder(side: _side, depth: _depth).hashCode,
      const KeyBorder(side: _side, depth: _depth).hashCode,
    );
    expect(
      const KeyBorder(side: _side, depth: _depth),
      isNot(const KeyBorder(side: _side, depth: _depth, travel: 1)),
    );
  });

  group('paints', () {
    Future<RenderObject> show(WidgetTester tester, KeyBorder key) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox.fromSize(
            size: _rect.size,
            child: DecoratedBox(decoration: ShapeDecoration(shape: key)),
          ),
        ),
      );
      return tester.renderObject(find.byType(DecoratedBox));
    }

    testWidgets('the edge and the outline in the outline color', (
      tester,
    ) async {
      final box = await show(
        tester,
        const KeyBorder(side: _side, depth: _depth),
      );

      expect(
        box,
        paints
          ..drrect(color: _side.color)
          ..drrect(color: _side.color),
      );
    });

    testWidgets('only the outline when pressed', (tester) async {
      final box = await show(
        tester,
        const KeyBorder(side: _side, depth: _depth, travel: _depth),
      );

      expect(box, paintsExactlyCountTimes(#drawDRRect, 1));
    });

    testWidgets('nothing without an outline', (tester) async {
      final box = await show(tester, const KeyBorder(depth: _depth));

      expect(box, paintsNothing);
    });
  });
}
