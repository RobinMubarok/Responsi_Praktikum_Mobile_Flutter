import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status state pengambilan data cuaca.
enum WeatherStatus { initial, loading, loaded, empty, error }

/// ViewModel utama untuk Home / Weather Screen (pola MVVM).
class WeatherViewModel extends ChangeNotifier {
  static const LocationModel defaultLocation = LocationModel(
    id: 1621177,
    name: 'Yogyakarta',
    country: 'Indonesia',
    admin1: 'DI Yogyakarta',
    latitude: -7.7956,
    longitude: 110.3695,
    timezone: 'Asia/Jakarta',
  );

  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  WeatherViewModel({
    required this._apiService,
    required this._storageService,
  });

  WeatherStatus _status = WeatherStatus.initial;
  WeatherModel? _weather;
  LocationModel _selectedLocation = defaultLocation;
  List<LocationModel> _favorites = const [];
  String? _errorMessage;
  bool _initialized = false;

  WeatherStatus get status => _status;
  WeatherModel? get weather => _weather;
  LocationModel get selectedLocation => _selectedLocation;
  List<LocationModel> get favorites => _favorites;
  String? get errorMessage => _errorMessage;

  bool isFavorite(LocationModel location) => _favorites.contains(location);

  /// Memuat lokasi favorit & lokasi terakhir dari Local Storage,
  /// lalu mengambil data cuaca terkini dari Open-Meteo API.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _favorites = await _storageService.getFavorites();
    final savedLocation = await _storageService.getSelectedLocation();
    if (savedLocation != null) {
      _selectedLocation = savedLocation;
    } else if (_favorites.isNotEmpty) {
      _selectedLocation = _favorites.first;
    }
    notifyListeners();

    await fetchWeather();
  }

  /// Mengambil data cuaca dari Open-Meteo API untuk [_selectedLocation].
  Future<void> fetchWeather() async {
    _status = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      if (result.daily.isEmpty && result.current.time.isEmpty) {
        _weather = null;
        _status = WeatherStatus.empty;
      } else {
        _weather = result;
        _status = WeatherStatus.loaded;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = WeatherStatus.error;
    } catch (e) {
      _errorMessage = 'Gagal memuat data cuaca: $e';
      _status = WeatherStatus.error;
    }
    notifyListeners();
  }

  /// Memilih lokasi baru, menyimpannya ke Local Storage, dan memuat cuacanya.
  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    await _storageService.saveSelectedLocation(location);
    await fetchWeather();
  }

  /// Menambah atau menghapus lokasi dari daftar favorit di Local Storage.
  Future<bool> toggleFavorite(LocationModel location) async {
    final exists = isFavorite(location);
    if (exists) {
      _favorites = _favorites.where((item) => item != location).toList();
    } else {
      _favorites = [location, ..._favorites];
    }
    notifyListeners();
    await _storageService.saveFavorites(_favorites);
    return !exists;
  }
}
