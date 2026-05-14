import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationFailure {
  final LocationFailureReason reason;
  final String message;
  LocationFailure(this.reason, this.message);
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationFailure(
          LocationFailureReason.serviceDisabled, '裝置未開啟定位服務');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationFailure(
            LocationFailureReason.permissionDenied, '需要定位權限才能取得位置');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(LocationFailureReason.permissionDeniedForever,
          '定位權限已永久拒絕，請至系統設定開啟');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final address =
          await _reverseGeocode(position.latitude, position.longitude);
      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } on TimeoutException catch (e) {
      throw LocationFailure(
          LocationFailureReason.timeout, '定位逾時：${e.message ?? ''}');
    } catch (e) {
      debugPrint('location error: $e');
      throw LocationFailure(LocationFailureReason.unknown, '取得位置失敗：$e');
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '$lat, $lng';
      final p = placemarks.first;
      final parts = [
        p.country,
        p.administrativeArea,
        p.locality,
        p.subLocality,
        p.street,
      ].where((s) => s != null && s.isNotEmpty).toList();
      return parts.join(' ');
    } catch (_) {
      return '$lat, $lng';
    }
  }
}

class TimeoutException implements Exception {
  final String? message;
  TimeoutException(this.message);
}
