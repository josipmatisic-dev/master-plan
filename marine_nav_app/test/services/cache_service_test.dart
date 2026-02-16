import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = CacheService(maxEntries: 5);
      await cache.init();
    });

    test('initializes successfully', () {
      expect(cache.isInitialized, true);
      expect(cache.entryCount, 0);
    });

    test('put and get a value', () async {
      await cache.put('key1', 'value1');
      expect(cache.get('key1'), 'value1');
    });

    test('returns null for missing key', () {
      expect(cache.get('nonexistent'), isNull);
    });

    test('tracks hits and misses', () async {
      await cache.put('key1', 'value1');
      cache.get('key1'); // hit
      cache.get('missing'); // miss

      expect(cache.hits, 1);
      expect(cache.misses, 1);
    });

    test('delete removes entry', () async {
      await cache.put('key1', 'value1');
      expect(cache.get('key1'), 'value1');

      await cache.delete('key1');
      expect(cache.get('key1'), isNull);
      expect(cache.entryCount, 0);
    });

    test('clear removes all entries', () async {
      await cache.put('a', '1');
      await cache.put('b', '2');
      await cache.put('c', '3');
      expect(cache.entryCount, 3);

      await cache.clear();
      expect(cache.entryCount, 0);
      expect(cache.hits, 0);
      expect(cache.misses, 0);

      // After clear, get returns null (registers a miss)
      expect(cache.get('a'), isNull);
      expect(cache.misses, 1);
    });

    test('TTL expiration', () async {
      await cache.put('temp', 'data', ttl: const Duration(milliseconds: 1));

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 10));

      expect(cache.get('temp'), isNull);
      expect(cache.misses, 1);
    });

    test('non-expired TTL returns value', () async {
      await cache.put('temp', 'data', ttl: const Duration(hours: 1));

      expect(cache.get('temp'), 'data');
      expect(cache.hits, 1);
    });

    test('LRU eviction when maxEntries exceeded', () async {
      // maxEntries = 5, add 7 entries
      for (int i = 0; i < 7; i++) {
        await cache.put('key$i', 'value$i');
      }

      // Should have evicted oldest 2 entries
      expect(cache.entryCount, 5);
      expect(cache.get('key0'), isNull); // evicted
      expect(cache.get('key1'), isNull); // evicted
      expect(cache.get('key2'), 'value2'); // kept
      expect(cache.get('key6'), 'value6'); // kept
    });

    test('overwrites existing key', () async {
      await cache.put('key1', 'old');
      await cache.put('key1', 'new');
      expect(cache.get('key1'), 'new');
      expect(cache.entryCount, 1);
    });

    test('totalSizeBytes reflects stored data', () async {
      await cache.put('key1', 'hello');
      expect(cache.totalSizeBytes, greaterThan(0));
    });

    test('persists across instances', () async {
      await cache.put('persistent', 'data');

      // Create new instance with same SharedPreferences
      final cache2 = CacheService(maxEntries: 5);
      await cache2.init();

      expect(cache2.get('persistent'), 'data');
    });

    test('purges expired entries on init', () async {
      await cache.put('expiring', 'data', ttl: const Duration(milliseconds: 1));

      await Future.delayed(const Duration(milliseconds: 10));

      // Re-init should purge expired
      final cache2 = CacheService(maxEntries: 5);
      await cache2.init();

      expect(cache2.entryCount, 0);
    });

    test('throws StateError if not initialized', () {
      final uninit = CacheService();
      expect(() => uninit.get('key'), throwsStateError);
    });

    test('handles empty string values', () async {
      await cache.put('empty', '');
      expect(cache.get('empty'), '');
    });

    test('handles JSON string values', () async {
      const json = '{"lat":43.5,"lng":16.4}';
      await cache.put('position', json);
      expect(cache.get('position'), json);
    });

    test('putJson and getJson handle structured data', () async {
      final data = {'lat': 43.5, 'lng': 16.4, 'active': true};
      await cache.putJson('settings', data);

      final retrieved = cache.getJson('settings');
      expect(retrieved, equals(data));
      expect(retrieved!['lat'], 43.5);
    });

    test('getJson returns null for invalid JSON', () async {
      await cache.put('bad_json', '{incomplete');
      expect(cache.getJson('bad_json'), isNull);
    });
  });
}
