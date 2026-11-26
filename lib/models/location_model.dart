/// Model data lokasi/kota dari Open-Meteo Geocoding API & Local Storage.
class LocationModel {
  final int id;
  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final String? timezone;

  const LocationModel({
    required this.id,
    required this.name,
    required this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
    this.timezone,
  });

  /// Nama tampilan lengkap, misalnya "Yogyakarta, DI Yogyakarta, Indonesia".
  String get displayName {
    final parts = <String>[name];
    if (admin1 != null && admin1!.trim().isNotEmpty && admin1 != name) {
      parts.add(admin1!.trim());
    }
    if (country.trim().isNotEmpty) {
      parts.add(country.trim());
    }
    return parts.join(', ');
  }

  /// Sub-label untuk daftar hasil pencarian/favorit.
  String get subtitle {
    final parts = <String>[];
    if (admin1 != null && admin1!.trim().isNotEmpty && admin1 != name) {
      parts.add(admin1!.trim());
    }
    if (country.trim().isNotEmpty) {
      parts.add(country.trim());
    }
    return parts.join(', ');
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      admin1: json['admin1'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'admin1': admin1,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.name == name &&
        (other.latitude - latitude).abs() < 0.001 &&
        (other.longitude - longitude).abs() < 0.001;
  }

  @override
  int get hashCode => Object.hash(
        name,
        latitude.toStringAsFixed(3),
        longitude.toStringAsFixed(3),
      );
}
