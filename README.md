# Responsi Cuaca — Aplikasi Prakiraan Cuaca Flutter

Aplikasi prakiraan cuaca berbasis **Flutter** dan **Dart** menggunakan pola arsitektur **Model-View-ViewModel (MVVM)** serta **Open-Meteo REST API**.

## Fitur Utama

1. **Home / Weather Screen**
   - Menampilkan nama kota yang sedang dipilih beserta sub-wilayahnya.
   - Menampilkan kondisi cuaca terkini (`current.weather_code`), suhu saat ini (`current.temperature_2m`), dan suhu yang dirasakan (`current.apparent_temperature`).
   - Menampilkan metrik tambahan: kelembapan udara (`current.relative_humidity_2m`), kecepatan angin (`current.wind_speed_10m`), curah hujan (`current.precipitation`), dan peluang hujan maksimum (`daily.precipitation_probability_max`).
   - Menampilkan prakiraan cuaca 7 hari ke depan (`daily.temperature_2m_min`, `daily.temperature_2m_max`, `daily.precipitation_probability_max`, `daily.weather_code`).
   - Akses cepat lokasi favorit melalui chip bar dan fitur *pull-to-refresh*.
   - Penanganan state *loading*, data kosong, dan *error* dengan tombol coba lagi.

2. **Search / Location Screen**
   - Input pencarian kota yang melakukan HTTP `GET` langsung ke **Open-Meteo Geocoding API**.
   - Menampilkan daftar hasil pencarian lokasi dan memungkinkan pengguna memilih kota untuk melihat cuacanya.
   - Menyimpan/menghapus lokasi favorit serta menyimpan riwayat pencarian ke **Local Storage (`SharedPreferences`)** agar tetap tersedia saat aplikasi dibuka kembali.

---

## Struktur Aplikasi (MVVM)

```text
lib/
├── main.dart                              # Entry point & MultiProvider setup
├── core/
│   ├── theme/
│   │   └── app_theme.dart                 # Material 3 Theme, ColorScheme & Typography
│   └── utils/
│       └── weather_code_helper.dart       # Mapping WMO weather_code ke label, ikon, warna
├── models/                                # [Model] Representasi data JSON -> Dart
│   ├── location_model.dart
│   └── weather_model.dart
├── services/                              # Layer akses data eksternal & lokal
│   ├── local_storage_service.dart         # SharedPreferences (favorit, riwayat, lokasi aktif)
│   └── weather_api_service.dart           # HTTP GET ke Open-Meteo API
├── viewmodels/                            # [ViewModel] State management (ChangeNotifier + Provider)
│   ├── search_viewmodel.dart
│   └── weather_viewmodel.dart
└── views/                                 # [View] Antarmuka pengguna (Material Widgets)
    ├── home_screen.dart
    ├── search_screen.dart
    └── widgets/
        ├── daily_forecast_tile.dart
        └── weather_metric_card.dart
```

---

## Implementasi API

Aplikasi menggunakan metode HTTP `GET` melalui package `http` ke dua endpoint resmi Open-Meteo:

1. **Weather Forecast API**
   - URL: `https://api.open-meteo.com/v1/forecast`
   - Parameter:
     - `latitude` & `longitude`: Koordinat lokasi terpilih
     - `current`: `temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day`
     - `daily`: `weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max`
     - `timezone`: `auto`
     - `forecast_days`: `7`

2. **Geocoding API**
   - URL: `https://geocoding-api.open-meteo.com/v1/search`
   - Parameter: `name`, `count=10`, `language=id`, `format=json`

---

## Penerapan Arsitektur MVVM

- **Model** (`models/`): `WeatherModel`, `CurrentWeather`, `DailyForecast`, dan `LocationModel` memetakan JSON dari Open-Meteo menjadi objek Dart yang *type-safe*.
- **View** (`views/`): `HomeScreen` dan `SearchScreen` hanya bertugas merender UI berdasarkan state dari ViewModel dan meneruskan aksi pengguna (seperti mencari kota, memilih lokasi, atau toggle favorit).
- **ViewModel** (`viewmodels/`): `WeatherViewModel` dan `SearchViewModel` mewarisi `ChangeNotifier` dan disediakan ke pohon widget melalui `Provider`. ViewModel memanggil `WeatherApiService` dan `LocalStorageService`, mengelola state (`loading`, `loaded`, `empty`, `error`), lalu memanggil `notifyListeners()` agar UI otomatis diperbarui.

---

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Pengujian

```bash
flutter analyze
flutter test
```

## Screenshot Aplikasi

> Letakkan screenshot setiap screen aplikasi pada bagian ini sebelum pengumpulan:
> - `Home / Weather Screen`
> - `Search / Location Screen`
