import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/center_zoom.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:latlong2/latlong.dart';

class MapControllerImpl implements MapController {
  final Completer<Null> _readyCompleter = Completer<Null>();
  final StreamController<MapEvent> _mapEventSink = StreamController.broadcast();
  StreamSink<MapEvent> get mapEventSink => _mapEventSink.sink;
  late final MapState _state;

  @override
  Future<Null> get onReady => _readyCompleter.future;

  void dispose() {
    _mapEventSink.close();
  }

  set state(MapState state) {
    _state = state;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  @override
  MoveAndRotateResult moveAndRotate(LatLng center, double zoom, double degree,
      {String? id}) {
    return _state.moveAndRotate(center, zoom, degree,
        source: MapEventSource.mapController, id: id!);
  }

  @override
  bool move(LatLng center, double zoom, {String? id}) {
    return _state.move(center, zoom,
        id: id, source: MapEventSource.mapController);
  }

  @override
  void fitBounds(
    LatLngBounds bounds, {
    FitBoundsOptions? options =
        const FitBoundsOptions(padding: EdgeInsets.all(12.0)),
  }) {
    _state.fitBounds(bounds, options!);
  }

  @override
  CenterZoom getBoundsCenterZoom(LatLngBounds bounds,
      {FitBoundsOptions? options}) {
    return _state.getBoundsCenterZoom(bounds, options!);
  }

  @override
  LatLng get center => _state.center;

  @override
  LatLngBounds? get bounds => _state.bounds;

  @override
  double get zoom => _state.zoom;

  @override
  double get rotation => _state.rotation;

  @override
  bool rotate(double degree, {String? id}) {
    return _state.rotate(degree, id: id, source: MapEventSource.mapController);
  }

  @override
  Stream<MapEvent> get mapEventStream => _mapEventSink.stream;
}

class MapState {
  MapOptions options;
  final ValueChanged<double> onRotationChanged;
  final StreamController<Null> _onMoveSink;
  final StreamSink<MapEvent> _mapEventSink;

  double _zoom;
  double _rotation;
  double _rotationRad;

  double get zoom => _zoom;
  double get rotation => _rotation;

  set rotation(double rotation) {
    _rotation = rotation;
    _rotationRad = degToRadian(rotation);
  }

  double get rotationRad => _rotationRad;

  LatLng? _lastCenter;
  LatLngBounds? _lastBounds;
  Bounds? _lastPixelBounds;
  late CustomPoint _pixelOrigin;
  bool _initialized = false;

  MapState(this.options, this.onRotationChanged, this._mapEventSink)
      : _rotation = options.rotation,
        _rotationRad = degToRadian(options.rotation),
        _zoom = options.zoom,
        _onMoveSink = StreamController.broadcast();

  Stream<Null> get onMoved => _onMoveSink.stream;

  // Original size of the map where rotation isn't calculated
  CustomPoint? _originalSize;

  CustomPoint? get originalSize => _originalSize;

  void setOriginalSize(double width, double height) {
    final isCurrSizeNull = _originalSize == null;
    if (isCurrSizeNull ||
        _originalSize!.x != width ||
        _originalSize!.y != height) {
      _originalSize = CustomPoint<double>(width, height);

      _updateSizeByOriginalSizeAndRotation();

      // rebuild layers if screen size has been changed
      if (!isCurrSizeNull) {
        _onMoveSink.add(null);
      }
    }
  }

  // Extended size of the map where rotation is calculated
  CustomPoint? _size;

  CustomPoint get size => _size ?? CustomPoint(0.0, 0.0);

  void _updateSizeByOriginalSizeAndRotation() {
    final originalWidth = _originalSize!.x;
    final originalHeight = _originalSize!.y;

    if (_rotation != 0.0) {
      final cosAngle = math.cos(_rotationRad).abs();
      final sinAngle = math.sin(_rotationRad).abs();
      final num width =
          (originalWidth * cosAngle) + (originalHeight * sinAngle);
      final num height =
          (originalHeight * cosAngle) + (originalWidth * sinAngle);

      _size = CustomPoint<double>(width, height);
    } else {
      _size = CustomPoint<double>(originalWidth, originalHeight);
    }

    if (!_initialized) {
      _init();
      _initialized = true;
    }

    _pixelOrigin = getNewPixelOrigin(_lastCenter!);
  }

  LatLng get center => getCenter();

  LatLngBounds get bounds => getBounds();

  Bounds get pixelBounds => getLastPixelBounds();

  void _init() {
    if (options.bounds != null) {
      fitBounds(options.bounds!, options.boundsOptions);
    } else {
      move(options.center, zoom, source: MapEventSource.initialization);
    }
  }

  void _handleMoveEmit(LatLng targetCenter, double targetZoom, hasGesture,
      MapEventSource source, String? id) {
    if (source == MapEventSource.flingAnimationController) {
      emitMapEvent(
        MapEventFlingAnimation(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.doubleTapZoomAnimationController) {
      emitMapEvent(
        MapEventDoubleTapZoom(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.onDrag ||
        source == MapEventSource.onMultiFinger) {
      emitMapEvent(
        MapEventMove(
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    } else if (source == MapEventSource.mapController) {
      emitMapEvent(
        MapEventMove(
          id: id,
          center: _lastCenter!,
          zoom: _zoom,
          targetCenter: targetCenter,
          targetZoom: targetZoom,
          source: source,
        ),
      );
    }
  }

  void emitMapEvent(MapEvent event) {
    _mapEventSink.add(event);
  }

  void dispose() {
    _onMoveSink.close();
    _mapEventSink.close();
  }

  void rebuildLayers() {
    _onMoveSink.add(null);
  }

  bool rotate(
    double degree, {
    hasGesture = false,
    callOnMoveSink = true,
    required MapEventSource source,
    String? id,
  }) {
    if (degree != _rotation) {
      var oldRotation = _rotation;
      rotation = degree;
      _updateSizeByOriginalSizeAndRotation();

      onRotationChanged(_rotation);

      emitMapEvent(
        MapEventRotate(
          id: id,
          currentRotation: oldRotation,
          targetRotation: _rotation,
          center: _lastCenter!,
          zoom: _zoom,
          source: source,
        ),
      );

      if (callOnMoveSink) {
        _onMoveSink.add(null);
      }

      return true;
    }

    return false;
  }

  MoveAndRotateResult moveAndRotate(LatLng center, double zoom, double degree,
      {required MapEventSource source, required String id}) {
    final moveSucc =
        move(center, zoom, id: id, source: source, callOnMoveSink: false);
    final rotateSucc =
        rotate(degree, id: id, source: source, callOnMoveSink: false);

    if (moveSucc || rotateSucc) {
      _onMoveSink.add(null);
    }

    return MoveAndRotateResult(moveSucc, rotateSucc);
  }

  bool move(LatLng center, double zoom,
      {hasGesture = false,
      callOnMoveSink = true,
      required MapEventSource source,
      String? id}) {
    zoom = fitZoomToBounds(zoom);
    final mapMoved = center != _lastCenter || zoom != _zoom;

    if (_lastCenter != null && (!mapMoved || !bounds.isValid)) {
      return false;
    }

    if (options.isOutOfBounds(center)) {
      if (!options.slideOnBoundaries) {
        return false;
      }
      center = options.containPoint(center, _lastCenter ?? center);
    }

    _handleMoveEmit(center, zoom, hasGesture, source, id);

    _zoom = zoom;
    _lastCenter = center;
    _lastPixelBounds = getPixelBounds(_zoom);
    _lastBounds = _calculateBounds();
    _pixelOrigin = getNewPixelOrigin(center);
    if (callOnMoveSink) {
      _onMoveSink.add(null);
    }

    if (options.onPositionChanged != null) {
      var mapPosition = MapPosition(
          center: center, bounds: bounds, zoom: zoom, hasGesture: hasGesture);

      options.onPositionChanged!(mapPosition, hasGesture);
    }

    return true;
  }

  double fitZoomToBounds(double? zoom) {
    zoom ??= _zoom;
    // Abide to min/max zoom
    if (options.maxZoom != null) {
      zoom = (zoom > options.maxZoom!) ? options.maxZoom! : zoom;
    }
    if (options.minZoom != null) {
      zoom = (zoom < options.minZoom!) ? options.minZoom! : zoom;
    }
    return zoom;
  }

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    if (!bounds.isValid) {
      throw Exception('Bounds are not valid.');
    }
    var target = getBoundsCenterZoom(bounds, options);
    move(target.center, target.zoom, source: MapEventSource.fitBounds);
  }

  LatLng getCenter() {
    if (_lastCenter != null) {
      return _lastCenter!;
    }
    return layerPointToLatLng(_centerLayerPoint);
  }

  LatLngBounds getBounds() {
    if (_lastBounds != null) {
      return _lastBounds!;
    }

    return _calculateBounds();
  }

  Bounds getLastPixelBounds() {
    if (_lastPixelBounds != null) {
      return _lastPixelBounds!;
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
    var swPoint = project(bounds.southWest!, zoom);
    var nePoint = project(bounds.northEast!, zoom);
    var center = unproject((swPoint + nePoint) / 2 + paddingOffset, zoom);
    return CenterZoom(
      center: center,
      zoom: zoom,
    );
  }

  double getBoundsZoom(LatLngBounds bounds, CustomPoint<double> padding,
      {bool inside = false}) {
    var zoom = this.zoom;
    var min = options.minZoom ?? 0.0;
    var max = options.maxZoom ?? double.infinity;
    var nw = bounds.northWest;
    var se = bounds.southEast;
    var size = this.size - padding;
    // Prevent negative size which results in NaN zoom value later on in the calculation
    size = CustomPoint(math.max(0, size.x), math.max(0, size.y));
    var boundsSize = Bounds(project(se, zoom), project(nw, zoom)).size;
    var scaleX = size.x / boundsSize.x;
    var scaleY = size.y / boundsSize.y;
    var scale = inside ? math.max(scaleX, scaleY) : math.min(scaleX, scaleY);

    zoom = getScaleZoom(scale, zoom);

    return math.max(min, math.min(max, zoom));
  }

  CustomPoint project(LatLng latlng, [double? zoom]) {
    zoom ??= _zoom;
    return options.crs.latLngToPoint(latlng, zoom);
  }

  LatLng unproject(CustomPoint point, [double? zoom]) {
    zoom ??= _zoom;
    return options.crs.pointToLatLng(point, zoom)!;
  }

  LatLng layerPointToLatLng(CustomPoint point) {
    return unproject(point);
  }

  CustomPoint get _centerLayerPoint {
    return size / 2;
  }

  double getZoomScale(double toZoom, double? fromZoom) {
    var crs = options.crs;
    fromZoom = fromZoom ?? _zoom;
    return crs.scale(toZoom) / crs.scale(fromZoom);
  }

  double getScaleZoom(double scale, double? fromZoom) {
    var crs = options.crs;
    fromZoom = fromZoom ?? _zoom;
    return crs.zoom(scale * crs.scale(fromZoom)) as double;
  }

  Bounds? getPixelWorldBounds(double? zoom) {
    return options.crs.getProjectedBounds(zoom ?? _zoom);
  }

  CustomPoint getPixelOrigin() {
    return _pixelOrigin;
  }

  CustomPoint getNewPixelOrigin(LatLng center, [double? zoom]) {
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

  static MapState? maybeOf(BuildContext context, {bool nullOk = false}) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<MapStateInheritedWidget>();
    if (nullOk || widget != null) {
      return widget?.mapState;
    }
    throw FlutterError(
        'MapState.of() called with a context that does not contain a FlutterMap.');
  }
}
