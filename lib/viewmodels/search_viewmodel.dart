import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status state pencarian lokasi.
enum SearchStatus { idle, loading, loaded, empty, error }

/// ViewModel untuk Search / Location Screen (pola MVVM).
class SearchViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  SearchViewModel({
    required this._apiService,
    required this._storageService,
  });

  SearchStatus _status = SearchStatus.idle;
  List<LocationModel> _results = const [];
  List<LocationModel> _searchHistory = const [];
  String? _errorMessage;
  String _query = '';

  SearchStatus get status => _status;
  List<LocationModel> get results => _results;
  List<LocationModel> get searchHistory => _searchHistory;
  String? get errorMessage => _errorMessage;
  String get query => _query;

  /// Memuat riwayat pencarian tersimpan dari Local Storage.
  Future<void> loadHistory() async {
    _searchHistory = await _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Melakukan pencarian kota ke Open-Meteo Geocoding API.
  Future<void> searchLocations(String input) async {
    final trimmed = input.trim();
    _query = trimmed;

    if (trimmed.isEmpty) {
      _results = const [];
      _errorMessage = null;
      _status = SearchStatus.idle;
      notifyListeners();
      return;
    }

    _status = SearchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final locations = await _apiService.searchLocations(trimmed);
      _results = locations;
      _status = locations.isEmpty ? SearchStatus.empty : SearchStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _results = const [];
      _status = SearchStatus.error;
    } catch (e) {
      _errorMessage = 'Gagal mencari lokasi: $e';
      _results = const [];
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  /// Mengosongkan input pencarian dan kembali ke mode riwayat/favorit.
  void clearSearch() {
    _query = '';
    _results = const [];
    _errorMessage = null;
    _status = SearchStatus.idle;
    notifyListeners();
  }

  /// Menambahkan lokasi terpilih ke riwayat pencarian lokal.
  Future<void> addToHistory(LocationModel location) async {
    _searchHistory = await _storageService.addSearchHistory(location);
    notifyListeners();
  }

  /// Menghapus satu item dari riwayat pencarian lokal.
  Future<void> removeHistoryItem(LocationModel location) async {
    _searchHistory = await _storageService.removeSearchHistoryItem(location);
    notifyListeners();
  }

  /// Menghapus seluruh riwayat pencarian lokal.
  Future<void> clearHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = const [];
    notifyListeners();
  }
}
