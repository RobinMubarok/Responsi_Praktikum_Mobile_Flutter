import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

/// Service penyimpanan lokal menggunakan SharedPreferences untuk menyimpan
/// lokasi favorit, riwayat pencarian, dan lokasi terakhir yang dipilih.
class LocalStorageService {
  static const String _favoritesKey = 'favorite_locations';
  static const String _historyKey = 'search_history';
  static const String _selectedLocationKey = 'selected_location';
  static const int _maxHistoryItems = 10;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Memuat daftar lokasi favorit dari Local Storage.
  Future<List<LocationModel>> getFavorites() async {
    return _readLocationList(_favoritesKey);
  }

  /// Menyimpan daftar lokasi favorit ke Local Storage.
  Future<void> saveFavorites(List<LocationModel> favorites) async {
    await _writeLocationList(_favoritesKey, favorites);
  }

  /// Memuat riwayat pencarian dari Local Storage.
  Future<List<LocationModel>> getSearchHistory() async {
    return _readLocationList(_historyKey);
  }

  /// Menambahkan lokasi ke riwayat pencarian (unik, terbaru di atas, maks 10 item).
  Future<List<LocationModel>> addSearchHistory(LocationModel location) async {
    final current = await getSearchHistory();
    final updated = [
      location,
      ...current.where((item) => item != location),
    ];
    if (updated.length > _maxHistoryItems) {
      updated.removeRange(_maxHistoryItems, updated.length);
    }
    await _writeLocationList(_historyKey, updated);
    return updated;
  }

  /// Menghapus satu item dari riwayat pencarian.
  Future<List<LocationModel>> removeSearchHistoryItem(
    LocationModel location,
  ) async {
    final current = await getSearchHistory();
    final updated = current.where((item) => item != location).toList();
    await _writeLocationList(_historyKey, updated);
    return updated;
  }

  /// Menghapus seluruh riwayat pencarian.
  Future<void> clearSearchHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_historyKey);
  }

  /// Memuat lokasi terakhir yang dipilih pengguna.
  Future<LocationModel?> getSelectedLocation() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_selectedLocationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return LocationModel.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Menyimpan lokasi yang sedang dipilih ke Local Storage.
  Future<void> saveSelectedLocation(LocationModel location) async {
    final prefs = await _prefs;
    await prefs.setString(_selectedLocationKey, jsonEncode(location.toJson()));
  }

  Future<List<LocationModel>> _readLocationList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocationModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocationList(
    String key,
    List<LocationModel> locations,
  ) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(locations.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }
}
