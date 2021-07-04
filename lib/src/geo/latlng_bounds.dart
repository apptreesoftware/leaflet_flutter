import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class LatLngBounds {
  LatLng? _sw;
  LatLng? _ne;

  LatLngBounds([LatLng? corner1, LatLng? corner2]) {
    extend(corner1);
    extend(corner2);
  }

  LatLngBounds.fromPoints(List<LatLng> points) {
    if (points.isNotEmpty) {
      num? minX;
      num? maxX;
      num? minY;
      num? maxY;

      for (var point in points) {
        num x = point.longitudeInRad;
        num y = point.latitudeInRad;

        if (minX == null || minX > x) {
          minX = x;
        }

        if (minY == null || minY > y) {
          minY = y;
        }

        if (maxX == null || maxX < x) {
          maxX = x;
        }

        if (maxY == null || maxY < y) {
          maxY = y;
        }
      }

      _sw = LatLng(radianToDeg(minY as double), radianToDeg(minX as double));
      _ne = LatLng(radianToDeg(maxY as double), radianToDeg(maxX as double));
    }
  }

  void extend(LatLng? latlng) {
    if (latlng == null) {
      return;
    }
    _extend(latlng, latlng);
  }

  void extendBounds(LatLngBounds bounds) {
    _extend(bounds._sw, bounds._ne);
  }

  void _extend(LatLng? sw2, LatLng? ne2) {
    if (_sw == null && _ne == null) {
      _sw = LatLng(sw2!.latitude, sw2.longitude);
      _ne = LatLng(ne2!.latitude, ne2.longitude);
    } else {
      _sw!.latitude = math.min(sw2!.latitude, _sw!.latitude);
      _sw!.longitude = math.min(sw2.longitude, _sw!.longitude);
      _ne!.latitude = math.max(ne2!.latitude, _ne!.latitude);
      _ne!.longitude = math.max(ne2.longitude, _ne!.longitude);
    }
  }

  double get west => southWest!.longitude;
  double get south => southWest!.latitude;
  double get east => northEast!.longitude;
  double get north => northEast!.latitude;

  LatLng? get southWest => _sw;
  LatLng? get northEast => _ne;
  LatLng get northWest => LatLng(north, west);
  LatLng get southEast => LatLng(south, east);

  bool get isValid {
    return _sw != null && _ne != null;
  }

  bool contains(LatLng? point) {
    if (!isValid) {
      return false;
    }
    var sw2 = point;
    var ne2 = point;
    return containsBounds(LatLngBounds(sw2, ne2));
  }

  bool containsBounds(LatLngBounds bounds) {
    var sw2 = bounds._sw!;
    var ne2 = bounds._ne;
    return (sw2.latitude >= _sw!.latitude) &&
        (ne2!.latitude <= _ne!.latitude) &&
        (sw2.longitude >= _sw!.longitude) &&
        (ne2.longitude <= _ne!.longitude);
  }

  bool isOverlapping(LatLngBounds? bounds) {
    if (!isValid) {
      return false;
    }
    // check if bounding box rectangle is outside the other, if it is then it's
    // considered not overlapping
    if (_sw!.latitude > bounds!._ne!.latitude ||
        _ne!.latitude < bounds._sw!.latitude ||
        _ne!.longitude < bounds._sw!.longitude ||
        _sw!.longitude > bounds._ne!.longitude) {
      return false;
    }
    return true;
  }

  void pad(double bufferRatio) {
    var heightBuffer = (_sw!.latitude - _ne!.latitude).abs() * bufferRatio;
    var widthBuffer = (_sw!.longitude - _ne!.longitude).abs() * bufferRatio;

    _sw = LatLng(_sw!.latitude - heightBuffer, _sw!.longitude - widthBuffer);
    _ne = LatLng(_ne!.latitude + heightBuffer, _ne!.longitude + widthBuffer);
  }

  @override
  int get hashCode => _sw.hashCode + _ne.hashCode;

  @override
  bool operator ==(Object other) =>
      other is LatLngBounds && other._sw == _sw && other._ne == _ne;
}
