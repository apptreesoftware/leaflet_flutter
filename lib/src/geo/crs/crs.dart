import 'dart:math' as math;

import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:meta/meta.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:tuple/tuple.dart';

/// An abstract representation of a
/// [Coordinate Reference System](https://bit.ly/3iVKpja).
///
/// The main objective of a CRS is to handle the conversion between surface
/// points of objects of different dimensions. In our case 3D and 2D objects.
abstract class Crs {
  String get code;

  Projection get projection;

  Transformation get transformation;

  const Crs();

  /// Converts a point on the sphere surface (with a certain zoom) in a
  /// map point.
  CustomPoint latLngToPoint(LatLng latlng, double zoom) {
    try {
      var projectedPoint = projection.project(latlng);
      var scale = this.scale(zoom);
      return transformation.transform(projectedPoint, scale.toDouble());
    } catch (e) {
      return CustomPoint(0.0, 0.0);
    }
  }

  /// Converts a map point to the sphere coordinate (at a certain zoom).
  LatLng pointToLatLng(CustomPoint point, double zoom) {
    var scale = this.scale(zoom);
    var untransformedPoint =
        transformation.untransform(point, scale.toDouble());
    try {
      return projection.unproject(untransformedPoint);
    } catch (e) {
      return null;
    }
  }

  /// Zoom to Scale function.
  num scale(double zoom) {
    return 256 * math.pow(2, zoom);
  }

  /// Scale to Zoom function.
  num zoom(double scale) {
    return math.log(scale / 256) / math.ln2;
  }

  /// Rescales the bounds to a given zoom value.
  Bounds getProjectedBounds(double zoom) {
    if (infinite) return null;

    var b = projection.bounds;
    var s = scale(zoom);
    var min = transformation.transform(b.min, s.toDouble());
    var max = transformation.transform(b.max, s.toDouble());
    return Bounds(min, max);
  }

  bool get infinite;

  Tuple2<double, double> get wrapLng;

  Tuple2<double, double> get wrapLat;
}

// Custom CRS for non geographical maps
class CrsSimple extends Crs {
  @override
  final String code = 'CRS.SIMPLE';

  @override
  final Projection projection;

  @override
  final Transformation transformation;

  CrsSimple()
      : projection = const _LonLat(),
        transformation = Transformation(1, 0, -1, 0),
        super();

  @override
  bool get infinite => false;

  @override
  Tuple2<double, double> get wrapLat => null;

  @override
  Tuple2<double, double> get wrapLng => null;
}

abstract class Earth extends Crs {
  @override
  bool get infinite => false;

  @override
  final Tuple2<double, double> wrapLng = const Tuple2(-180.0, 180.0);

  @override
  final Tuple2<double, double> wrapLat = null;

  const Earth() : super();
}

/// The most common CRS used for rendering maps.
class Epsg3857 extends Earth {
  @override
  final String code = 'EPSG:3857';

  @override
  final Projection projection;

  @override
  final Transformation transformation;

  static const num _scale = 0.5 / (math.pi * SphericalMercator.r);

  const Epsg3857()
      : projection = const SphericalMercator(),
        transformation = const Transformation(_scale, 0.5, -_scale, 0.5),
        super();

// TODO Epsg3857 seems to have latitude limits. https://epsg.io/3857
//@override
//Tuple2<double, double> get wrapLat => const Tuple2(-85.06, 85.06);
}

/// A common CRS among GIS enthusiasts. Uses simple Equirectangular projection.
class Epsg4326 extends Earth {
  @override
  final String code = 'EPSG:4326';

  @override
  final Projection projection;

  @override
  final Transformation transformation;

  const Epsg4326()
      : projection = const _LonLat(),
        transformation = const Transformation(1 / 180, 0.5, -1 / 180, 0.5),
        super();
}

/// Custom CRS
class Proj4Crs extends Crs {
  @override
  final String code;

  @override
  final Projection projection;

  @override
  final Transformation transformation;

  @override
  final bool infinite;

  @override
  final Tuple2<double, double> wrapLat = null;

  @override
  final Tuple2<double, double> wrapLng = null;

  final List<Transformation> _transformations;

  final List<double> _scales;

  Proj4Crs._({
    @required this.code,
    @required this.projection,
    @required this.transformation,
    @required this.infinite,
    @required List<Transformation> transformations,
    @required List<double> scales,
  })  : assert(null != code),
        assert(null != projection),
        assert(null != transformation || null != transformations),
        assert(null != infinite),
        assert(null != scales),
        _transformations = transformations,
        _scales = scales;

  factory Proj4Crs.fromFactory({
    @required String code,
    @required proj4.Projection proj4Projection,
    Transformation transformation,
    List<CustomPoint> origins,
    Bounds<double> bounds,
    List<double> scales,
    List<double> resolutions,
  }) {
    final projection =
        _Proj4Projection(proj4Projection: proj4Projection, bounds: bounds);
    List<Transformation> transformations;
    var infinite = null == bounds;
    List<double> finalScales;

    if (null != scales && scales.isNotEmpty) {
      finalScales = scales;
    } else if (null != resolutions && resolutions.isNotEmpty) {
      finalScales = resolutions.map((r) => 1 / r).toList(growable: false);
    } else {
      throw Exception(
          'Please provide scales or resolutions to determine scales');
    }

    if (null == origins || origins.isEmpty) {
      transformation ??= Transformation(1, 0, -1, 0);
    } else {
      if (origins.length == 1) {
        var origin = origins[0];
        transformation = Transformation(1, -origin.x, -1, origin.y);
      } else {
        transformations =
            origins.map((p) => Transformation(1, -p.x, -1, p.y)).toList();
        transformation = null;
      }
    }

    return Proj4Crs._(
      code: code,
      projection: projection,
      transformation: transformation,
      infinite: infinite,
      transformations: transformations,
      scales: finalScales,
    );
  }

  /// Converts a point on the sphere surface (with a certain zoom) in a
  /// map point.
  @override
  CustomPoint latLngToPoint(LatLng latlng, double zoom) {
    try {
      var projectedPoint = projection.project(latlng);
      var scale = this.scale(zoom);
      var transformation = _getTransformationByZoom(zoom);

      return transformation.transform(projectedPoint, scale.toDouble());
    } catch (e) {
      return CustomPoint(0.0, 0.0);
    }
  }

  /// Converts a map point to the sphere coordinate (at a certain zoom).
  @override
  LatLng pointToLatLng(CustomPoint point, double zoom) {
    var scale = this.scale(zoom);
    var transformation = _getTransformationByZoom(zoom);

    var untransformedPoint =
        transformation.untransform(point, scale.toDouble());
    try {
      return projection.unproject(untransformedPoint);
    } catch (e) {
      return null;
    }
  }

  /// Rescales the bounds to a given zoom value.
  @override
  Bounds getProjectedBounds(double zoom) {
    if (infinite) return null;

    var b = projection.bounds;
    var s = scale(zoom);

    var transformation = _getTransformationByZoom(zoom);

    var min = transformation.transform(b.min, s.toDouble());
    var max = transformation.transform(b.max, s.toDouble());
    return Bounds(min, max);
  }

  /// Zoom to Scale function.
  @override
  num scale(double zoom) {
    var iZoom = zoom.floor();
    if (zoom == iZoom) {
      return _scales[iZoom];
    } else {
      // Non-integer zoom, interpolate
      var baseScale = _scales[iZoom];
      var nextScale = _scales[iZoom + 1];
      var scaleDiff = nextScale - baseScale;
      var zDiff = (zoom - iZoom);
      return baseScale + scaleDiff * zDiff;
    }
  }

  /// Scale to Zoom function.
  @override
  num zoom(double scale) {
    // Find closest number in _scales, down
    var downScale = _closestElement(_scales, scale);
    var downZoom = _scales.indexOf(downScale);
    // Check if scale is downScale => return array index
    if (scale == downScale) {
      return downZoom;
    }
    if (downScale == null) {
      return double.negativeInfinity;
    }
    // Interpolate
    var nextZoom = downZoom + 1;
    var nextScale = _scales[nextZoom];
    if (nextScale == null) {
      return double.infinity;
    }
    var scaleDiff = nextScale - downScale;
    return (scale - downScale) / scaleDiff + downZoom;
  }

  /// Get the closest lowest element in an array
  double _closestElement(List<double> array, double element) {
    double low;
    for (var i = array.length - 1; i >= 0; i--) {
      var curr = array[i];

      if (curr <= element && (null == low || low < curr)) {
        low = curr;
      }
    }
    return low;
  }

  /// returns Transformation object based on zoom
  Transformation _getTransformationByZoom(double zoom) {
    if (null == _transformations) {
      return transformation;
    }

    var iZoom = zoom.round();
    var lastIdx = _transformations.length - 1;

    return _transformations[iZoom > lastIdx ? lastIdx : iZoom];
  }
}

abstract class Projection {
  const Projection();

  Bounds<double> get bounds;

  CustomPoint project(LatLng latlng);

  LatLng unproject(CustomPoint point);

  double _inclusive(Comparable start, Comparable end, double value) {
    if (value.compareTo(start) < 0) return start;
    if (value.compareTo(end) > 0) return end;

    return value;
  }

  @protected
  double inclusiveLat(double value) {
    return _inclusive(-90.0, 90.0, value);
  }

  @protected
  double inclusiveLng(double value) {
    return _inclusive(-180.0, 180.0, value);
  }
}

class _LonLat extends Projection {
  static final Bounds<double> _bounds = Bounds<double>(
      CustomPoint<double>(-180.0, -90.0), CustomPoint<double>(180.0, 90.0));

  const _LonLat() : super();

  @override
  Bounds<double> get bounds => _bounds;

  @override
  CustomPoint project(LatLng latlng) {
    return CustomPoint(latlng.longitude, latlng.latitude);
  }

  @override
  LatLng unproject(CustomPoint point) {
    return LatLng(inclusiveLat(point.y), inclusiveLng(point.x));
  }
}

class SphericalMercator extends Projection {
  static const int r = 6378137;
  static const double maxLatitude = 85.0511287798;
  static const double _boundsD = r * math.pi;
  static final Bounds<double> _bounds = Bounds<double>(
    CustomPoint<double>(-_boundsD, -_boundsD),
    CustomPoint<double>(_boundsD, _boundsD),
  );

  const SphericalMercator() : super();

  @override
  Bounds<double> get bounds => _bounds;

  @override
  CustomPoint project(LatLng latlng) {
    var d = math.pi / 180;
    var max = maxLatitude;
    var lat = math.max(math.min(max, latlng.latitude), -max);
    var sin = math.sin(lat * d);

    return CustomPoint(
        r * latlng.longitude * d, r * math.log((1 + sin) / (1 - sin)) / 2);
  }

  @override
  LatLng unproject(CustomPoint point) {
    var d = 180 / math.pi;
    return LatLng(
        inclusiveLat(
            (2 * math.atan(math.exp(point.y / r)) - (math.pi / 2)) * d),
        inclusiveLng(point.x * d / r));
  }
}

class _Proj4Projection extends Projection {
  final proj4.Projection epsg4326;

  final proj4.Projection proj4Projection;

  @override
  final Bounds<double> bounds;

  _Proj4Projection({
    @required this.proj4Projection,
    @required this.bounds,
  })  : assert(null != proj4Projection),
        epsg4326 = proj4.Projection.WGS84;

  @override
  CustomPoint project(LatLng latlng) {
    var point = epsg4326.transform(
        proj4Projection, proj4.Point(x: latlng.longitude, y: latlng.latitude));

    return CustomPoint(point.x, point.y);
  }

  @override
  LatLng unproject(CustomPoint point) {
    var point2 = proj4Projection.transform(
        epsg4326, proj4.Point(x: point.x, y: point.y));

    return LatLng(inclusiveLat(point2.y), inclusiveLng(point2.x));
  }
}

class Transformation {
  final num a;
  final num b;
  final num c;
  final num d;

  const Transformation(this.a, this.b, this.c, this.d);

  CustomPoint transform(CustomPoint<num> point, double scale) {
    scale ??= 1.0;
    var x = scale * (a * point.x + b);
    var y = scale * (c * point.y + d);
    return CustomPoint(x, y);
  }

  CustomPoint untransform(CustomPoint point, double scale) {
    scale ??= 1.0;
    var x = (point.x / scale - b) / a;
    var y = (point.y / scale - d) / c;
    return CustomPoint(x, y);
  }
}
