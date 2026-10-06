import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Key-value persistence behind every notifier. Hive in the app, a plain map
/// in tests.
abstract interface class Store {
  T? get<T>(String key);
  List<String>? getStringList(String key);
  Future<void> put(String key, Object value);
  Future<void> remove(String key);
  Iterable<String> get keys;
}

class HiveStore implements Store {
  HiveStore(this._box);
  final Box<dynamic> _box;

  static Future<HiveStore> open() async {
    await Hive.initFlutter();
    return HiveStore(await Hive.openBox<dynamic>('save'));
  }

  @override
  T? get<T>(String key) => _box.get(key) as T?;

  @override
  List<String>? getStringList(String key) =>
      (_box.get(key) as List<dynamic>?)?.cast<String>();

  @override
  Future<void> put(String key, Object value) => _box.put(key, value);

  @override
  Future<void> remove(String key) => _box.delete(key);

  @override
  Iterable<String> get keys => _box.keys.cast<String>();
}

class MemoryStore implements Store {
  MemoryStore([Map<String, Object>? initial]) : _data = {...?initial};
  final Map<String, Object> _data;

  @override
  T? get<T>(String key) => _data[key] as T?;

  @override
  List<String>? getStringList(String key) =>
      (_data[key] as List<dynamic>?)?.cast<String>();

  @override
  Future<void> put(String key, Object value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Iterable<String> get keys => _data.keys;
}

/// Overridden in `main` (HiveStore) and in tests (MemoryStore).
final storeProvider =
    Provider<Store>((ref) => throw UnimplementedError('storeProvider'));

/// Injectable clock for lives regeneration and the daily reward.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
