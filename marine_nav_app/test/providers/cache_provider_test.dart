import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/services/cache_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'cache_provider_test.mocks.dart';

@GenerateMocks([CacheService])
void main() {
  late MockCacheService mockCacheService;
  late CacheProvider cacheProvider;

  setUp(() async {
    mockCacheService = MockCacheService();
    cacheProvider = CacheProvider(cacheService: mockCacheService);

    // Default stubs for stats used in init/refreshStats
    when(mockCacheService.init()).thenAnswer((_) async {});
    when(mockCacheService.totalSizeBytes).thenReturn(0);
    when(mockCacheService.entryCount).thenReturn(0);
    when(mockCacheService.hits).thenReturn(0);
    when(mockCacheService.misses).thenReturn(0);

    // Initialize provider to enable other methods
    await cacheProvider.init();
  });

  group('CacheProvider', () {
    test('init calls service init and notifyListeners', () async {
      // Re-create provider to test init specifically
      mockCacheService = MockCacheService();
      cacheProvider = CacheProvider(cacheService: mockCacheService);

      when(mockCacheService.init()).thenAnswer((_) async {});
      when(mockCacheService.totalSizeBytes).thenReturn(0);
      when(mockCacheService.entryCount).thenReturn(0);
      when(mockCacheService.hits).thenReturn(0);
      when(mockCacheService.misses).thenReturn(0);

      bool notified = false;
      cacheProvider.addListener(() => notified = true);

      await cacheProvider.init();

      verify(mockCacheService.init()).called(1);
      expect(notified, isTrue);
    });

    test('putJson delegates to service and notifies', () async {
      const key = 'test_key';
      const data = {'data': 'value'};

      when(mockCacheService.putJson(key, data)).thenAnswer((_) async {});

      bool notified = false;
      cacheProvider.addListener(() => notified = true);

      await cacheProvider.putJson(key, data);

      verify(mockCacheService.putJson(key, data)).called(1);
      expect(notified, isTrue);
    });

    test('getJson delegates to service', () async {
      const key = 'test_key';
      const expectedData = {'data': 'value'};

      when(mockCacheService.getJson(key)).thenReturn(expectedData);

      final result = cacheProvider.getJson(key);

      verify(mockCacheService.getJson(key)).called(1);
      expect(result, equals(expectedData));
    });

    test('clear delegates to service and notifies', () async {
      when(mockCacheService.clear()).thenAnswer((_) async {});

      bool notified = false;
      cacheProvider.addListener(() => notified = true);

      await cacheProvider.clear();

      verify(mockCacheService.clear()).called(1);
      expect(notified, isTrue);
    });

    test('remove delegates to service and notifies', () async {
      const key = 'test_key';
      when(mockCacheService.delete(key)).thenAnswer((_) async {});

      bool notified = false;
      cacheProvider.addListener(() => notified = true);

      await cacheProvider.remove(key);

      verify(mockCacheService.delete(key)).called(1);
      expect(notified, isTrue);
    });

    test('stats getters delegate to service', () {
      when(mockCacheService.hits).thenReturn(10);
      when(mockCacheService.misses).thenReturn(5);
      when(mockCacheService.entryCount).thenReturn(20);
      when(mockCacheService.totalSizeBytes).thenReturn(1024);

      cacheProvider.refreshStats(); // Trigger stats update from service

      expect(cacheProvider.stats.hits, 10);
      expect(cacheProvider.stats.misses, 5);
      expect(cacheProvider.stats.entryCount, 20);
      expect(cacheProvider.stats.totalSize, 1024);
    });
  });
}
