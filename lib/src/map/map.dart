import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/center_zoom.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:latlong/latlong.dart';

class MapControllerImpl implements MapController {
  final Completer<void> _readyCompleter = Completer<void>();
  MapState _state;

  @override
  Future<void> get onReady => _readyCompleter.future;

  set state(MapState state) {
    _state = state;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  @override
  void move(LatLng center, double zoom,
      {bool hasGesture = false, isUserGesture = false}) {
    _state.move(center, zoom,
        hasGesture: hasGesture, isUserGesture: isUserGesture);
  }

  @override
  void fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions options =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
  }) {
    _state.fitBounds(bounds, options);
  }

  @override
  bool get ready => _state != null;

  @override
  LatLng get center => _state.center;

  @override
  LatLngBounds get bounds => _state.bounds;

  @override
  double get zoom => _state.zoom;
}

class MapState {
  final MapOptions options;
  final StreamController<void> _onMoveSink;

  double _zoom;

  double get zoom => _zoom;

  LatLng _lastCenter;
  LatLngBounds _lastBounds;
  Bounds _lastPixelBounds;
  CustomPoint _pixelOrigin;
  bool _initialized = false;

  MapState(this.options) : _onMoveSink = StreamController.broadcast();

  CustomPoint _size;

  Stream<void> get onMoved => _onMoveSink.stream;

  CustomPoint get size => _size;

  set size(CustomPoint s) {
    _size = s;
    _pixelOrigin = getNewPixelOrigin(_lastCenter);
    if (!_initialized) {
      _init();
      _initialized = true;
    }
  }

  LatLng get center => getCenter() ?? options.center;

  LatLngBounds get bounds => getBounds();

  Bounds get pixelBounds => getLastPixelBounds();

  void _init() {
    _zoom = options.zoom;
    move(options.center, zoom);
  }

  void dispose() {
    _onMoveSink.close();
  }

  double _calculateScreenWidthInDegrees(double zoom) {
    final degreesPerPixel = 360 / pow(2, zoom + 8);
    return options.screenSize.width * degreesPerPixel;
  }

  double _calculateScreenHeightInDegrees(double zoom) =>
      options.screenSize.height / pow(2, zoom + 8) * 180 * 4 / 3;

  void move(LatLng center, double zoom,
      {hasGesture = false, isUserGesture = false}) {
    zoom = _fitZoomToBounds(zoom);
    final mapMoved = center != _lastCenter || zoom != _zoom;

    if (!mapMoved || !bounds.isValid) {
      return;
    }

    if (options.isOutOfBounds(center)) {
      final halfScreenWidth = _calculateScreenWidthInDegrees(zoom) / 2;
      final halfScreenHeight = _calculateScreenHeightInDegrees(zoom) / 2;
      var southernBoundary = options.swPanBoundary.latitude + halfScreenHeight;
      var northernBoundary = options.nePanBoundary.latitude - halfScreenHeight;
      var westernBoundary = options.swPanBoundary.longitude + halfScreenWidth;
      var easternBoundary = options.nePanBoundary.longitude - halfScreenWidth;
      if (southernBoundary > northernBoundary ||
          westernBoundary > easternBoundary) {
        return;
      }
      final clampedLatitude =
          center.latitude.clamp(southernBoundary, northernBoundary);
      final clampedLongitude =
          center.longitude.clamp(westernBoundary, easternBoundary);
      center = LatLng(clampedLatitude, clampedLongitude);
    }

    _zoom = zoom;
    _lastCenter = center;
    _lastPixelBounds = getPixelBounds(_zoom);
    _lastBounds = _calculateBounds();
    _pixelOrigin = getNewPixelOrigin(center);
    _onMoveSink.add(null);

    if (options.onPositionChanged != null) {
      options.onPositionChanged(
          MapPosition(
            center: center,
            bounds: bounds,
            zoom: zoom,
          ),
          hasGesture,
          isUserGesture);
    }
  }

  double _fitZoomToBounds(double zoom) {
    zoom ??= _zoom;
    // Abide to min/max zoom
    if (options.maxZoom != null) {
      zoom = (zoom > options.maxZoom) ? options.maxZoom : zoom;
    }
    if (options.minZoom != null) {
      zoom = (zoom < options.minZoom) ? options.minZoom : zoom;
    }
    return zoom;
  }

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    if (!bounds.isValid) {
      throw Exception('Bounds are not valid.');
    }
    var target = getBoundsCenterZoom(bounds, options);
    move(target.center, target.zoom);
  }

  LatLng getCenter() {
    if (_lastCenter != null) {
      return _lastCenter;
    }
    return layerPointToLatLng(_centerLayerPoint);
  }

  LatLngBounds getBounds() {
    if (_lastBounds != null) {
      return _lastBounds;
    }

    return _calculateBounds();
  }

  Bounds getLastPixelBounds() {
    if (_lastPixelBounds != null) {
      return _lastPixelBounds;
    }

    return getPixelBounds(zoom);
  }

  LatLngBounds _calculateBounds() {
    var bounds = getLastPixelBounds();
    return LatLngBounds(
      unproject(bounds.bottomLeft),
      unproject(bounds.topRight),
    );
  }

  CenterZoom getBoundsCenterZoom(
      LatLngBounds bounds, FitBoundsOptions options) {
    var paddingTL =
        CustomPoint<double>(options.padding.left, options.padding.top);
    var paddingBR =
        CustomPoint<double>(options.padding.right, options.padding.bottom);

    var paddingTotalXY = paddingTL + paddingBR;

    var zoom = getBoundsZoom(bounds, paddingTotalXY, inside: false);
    zoom = math.min(options.maxZoom, zoom);

    var paddingOffset = (paddingBR - paddingTL) / 2;
    var swPoint = project(bounds.southWest, zoom);
    var nePoint = project(bounds.northEast, zoom);
    var center = unproject((swPoint + nePoint) / 2 + paddingOffset, zoom);
    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(LatLngBounds bounds, CustomPoint<double> padding,
      {bool inside = false}) {
    var zoom = this.zoom ?? 0.0;
    var min = options.minZoom ?? 0.0;
    var max = options.maxZoom ?? double.infinity;
    var nw = bounds.northWest;
    var se = bounds.southEast;
    var size = this.size - padding;
    var boundsSize = Bounds(project(se, zoom), project(nw, zoom)).size;
    var scaleX = size.x / boundsSize.x;
    var scaleY = size.y / boundsSize.y;
    var scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    zoom = getScaleZoom(scale, zoom);

    return math.max(min, math.min(max, zoom));
  }

  CustomPoint project(LatLng latlng, [double zoom]) {
    zoom ??= _zoom;
    return options.crs.latLngToPoint(latlng, zoom);
  }

  LatLng unproject(CustomPoint point, [double zoom]) {
    zoom ??= _zoom;
    return options.crs.pointToLatLng(point, zoom);
  }

  LatLng layerPointToLatLng(CustomPoint point) {
    return unproject(point);
  }

  CustomPoint get _centerLayerPoint {
    return size / 2;
  }

  double getZoomScale(double toZoom, double fromZoom) {
    var crs = options.crs;
    fromZoom = fromZoom == null ? _zoom : fromZoom;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  double getScaleZoom(double scale, double fromZoom) {
    var crs = options.crs;
    fromZoom = fromZoom == null ? _zoom : fromZoom;
    return crs.zoom(scale * crs.scale(fromZoom));
  }

  Bounds getPixelWorldBounds(double zoom) {
    return options.crs.getProjectedBounds(zoom == null ? _zoom : zoom);
  }

  CustomPoint getPixelOrigin() {
    return _pixelOrigin;
  }

  CustomPoint getNewPixelOrigin(LatLng center, [double zoom]) {
    var viewHalf = size / 2.0;
    return (project(center, zoom) - viewHalf).round();
  }

  Bounds getPixelBounds(double zoom) {
    var mapZoom = zoom;
    var scale = getZoomScale(mapZoom, zoom);
    var pixelCenter = project(center, zoom).floor();
    var halfSize = size / (scale * 2);
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }
}
