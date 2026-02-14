import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/utils/overlay_layout_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OverlayLayoutStore', () {
    test('save and load position and scale', () async {
      await OverlayLayoutStore.save(
        'test_widget',
        const Offset(100, 200),
        0.8,
      );
      final result = await OverlayLayoutStore.load('test_widget');
      expect(result.position, const Offset(100, 200));
      expect(result.scale, 0.8);
    });

    test('load returns nulls for unknown id', () async {
      final result = await OverlayLayoutStore.load('unknown');
      expect(result.position, isNull);
      expect(result.scale, isNull);
    });

    test('clear removes saved data', () async {
      await OverlayLayoutStore.save(
        'test_widget',
        const Offset(50, 50),
        1.0,
      );
      await OverlayLayoutStore.clear('test_widget');
      final result = await OverlayLayoutStore.load('test_widget');
      expect(result.position, isNull);
      expect(result.scale, isNull);
    });

    test('clearAll removes all overlay data', () async {
      await OverlayLayoutStore.save('w1', const Offset(10, 10), 1.0);
      await OverlayLayoutStore.save('w2', const Offset(20, 20), 0.5);
      await OverlayLayoutStore.clearAll();
      final r1 = await OverlayLayoutStore.load('w1');
      final r2 = await OverlayLayoutStore.load('w2');
      expect(r1.position, isNull);
      expect(r2.position, isNull);
    });
  });
}
