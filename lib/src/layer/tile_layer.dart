import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart' show MapEquality;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_map/src/core/util.dart' as util;
import 'package:flutter_map/src/geo/crs/crs.dart';
import 'package:flutter_map/src/layer/tile_provider/tile_provider.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'package:tuple/tuple.dart';

import 'layer.dart';

typedef TemplateFunction = String Function(
    String str, Map<String, dynamic> data);
typedef ErrorTileCallBack = void Function(Tile tile, dynamic error);

/// Describes the needed properties to create a tile-based layer. A tile is an
/// image bound to a specific geographical position.
class TileLayerOptions extends LayerOptions {
  /// Defines the structure to create the URLs for the tiles. `{s}` means one of
  /// the available subdomains (can be omitted) `{z}` zoom level `{x}` and `{y}`
  /// — tile coordinates `{r}` can be used to add "&commat;2x" to the URL to
  /// load retina tiles (can be omitted)
  ///
  /// Example:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// Is translated to this:
  ///
  /// https://a.tile.openstreetmap.org/12/2177/1259.png
  final String urlTemplate;

  /// If `true`, inverses Y axis numbering for tiles (turn this on for
  /// [TMS](https://en.wikipedia.org/wiki/Tile_Map_Service) services).
  final bool tms;

  /// If not `null`, then tiles will pull's WMS protocol requests
  final WMSTileLayerOptions wmsOptions;

  /// Size for the tile.
  /// Default is 256
  final double tileSize;

  // The minimum zoom level down to which this layer will be
  // displayed (inclusive).
  final double minZoom;

  /// The maximum zoom level up to which this layer will be displayed
  /// (inclusive). In most tile providers goes from 0 to 19.
  final double maxZoom;

  /// Minimum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels lower than minNativeZoom will be loaded from
  /// minNativeZoom level and auto-scaled.
  final double minNativeZoom;

  /// Maximum zoom number the tile source has available. If it is specified, the
  /// tiles on all zoom levels higher than maxNativeZoom will be loaded from
  /// maxNativeZoom level and auto-scaled.
  final double maxNativeZoom;

  /// If set to true, the zoom number used in tile URLs will be reversed
  /// (`maxZoom - zoom` instead of `zoom`)
  final bool zoomReverse;

  /// The zoom number used in tile URLs will be offset with this value.
  final double zoomOffset;

  /// List of subdomains for the URL.
  ///
  /// Example:
  ///
  /// Subdomains = {a,b,c}
  ///
  /// and the URL is as follows:
  ///
  /// https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  ///
  /// then:
  ///
  /// https://a.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://b.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// https://c.tile.openstreetmap.org/{z}/{x}/{y}.png
  final List<String> subdomains;

  /// Color shown behind the tiles.
  final Color backgroundColor;

  /// Opacity of the rendered tile
  final double opacity;

  /// Provider to load the tiles. The default is CachedNetworkTileProvider,
  /// which loads tile images from network and caches them offline.
  ///
  /// If you don't want to cache the tiles, use NetworkTileProvider instead.
  ///
  /// In order to use images from the asset folder set this option to
  /// AssetTileProvider() Note that it requires the urlTemplate to target
  /// assets, for example:
  ///
  /// ```dart
  /// urlTemplate: "assets/map/anholt_osmbright/{z}/{x}/{y}.png",
  /// ```
  ///
  /// In order to use images from the filesystem set this option to
  /// FileTileProvider() Note that it requires the urlTemplate to target the
  /// file system, for example:
  ///
  /// ```dart
  /// urlTemplate: "/storage/emulated/0/tiles/some_place/{z}/{x}/{y}.png",
  /// ```
  ///
  /// Furthermore you create your custom implementation by subclassing
  /// TileProvider
  ///
  final TileProvider tileProvider;

  /// When panning the map, keep this many rows and columns of tiles before
  /// unloading them.
  final int keepBuffer;

  /// Placeholder to show until tile images are fetched by the provider.
  final ImageProvider placeholderImage;

  /// Tile image to show in place of the tile that failed to load.
  final ImageProvider errorImage;

  /// Static informations that should replace placeholders in the [urlTemplate].
  /// Applying API keys is a good example on how to use this parameter.
  ///
  /// Example:
  ///
  /// ```dart
  ///
  /// TileLayerOptions(
  ///     urlTemplate: "https://api.tiles.mapbox.com/v4/"
  ///                  "{id}/{z}/{x}/{y}{r}.png?access_token={accessToken}",
  ///     additionalOptions: {
  ///         'accessToken': '<PUT_ACCESS_TOKEN_HERE>',
  ///          'id': 'mapbox.streets',
  ///     },
  /// ),
  /// ```
  ///
  final Map<String, dynamic> additionalOptions;

  /// Tiles will not update more than once every `updateInterval` (default 200
  /// milliseconds) when panning. It can be null (but it will calculating for
  /// loading tiles every frame when panning / zooming, flutter is fast) This
  /// can save some fps and even bandwidth (ie. when fast panning / animating
  /// between long distances in short time)
  final Duration updateInterval;

  /// Tiles fade in duration in milliseconds (default 100). This can be null to
  /// avoid fade in.
  final Duration tileFadeInDuration;

  /// Opacity start value when Tile starts fade in (0.0 - 1.0) Takes effect if
  /// `tileFadeInDuration` is not null
  final double tileFadeInStart;

  /// Opacity start value when an exists Tile starts fade in with different Url
  /// (0.0 - 1.0) Takes effect when `tileFadeInDuration` is not null and if
  /// `overrideTilesWhenUrlChanges` if true
  final double tileFadeInStartWhenOverride;

  /// `false`: current Tiles will be first dropped and then reload via new url
  /// (default) `true`: current Tiles will be visible until new ones aren't
  /// loaded (new Tiles are loaded independently) @see
  /// https://github.com/johnpryan/flutter_map/issues/583
  final bool overrideTilesWhenUrlChanges;

  /// If `true`, it will request four tiles of half the specified size and a
  /// bigger zoom level in place of one to utilize the high resolution.
  ///
  /// If `true` then MapOptions's `maxZoom` should be `maxZoom - 1` since
  /// retinaMode just simulates retina display by playing with `zoomOffset`. If
  /// geoserver supports retina `@2` tiles then it it advised to use them
  /// instead of simulating it (use {r} in the [urlTemplate])
  ///
  /// It is advised to use retinaMode if display supports it, write code like
  /// this:
  ///
  /// ```dart
  /// TileLayerOptions(
  ///     retinaMode: true && MediaQuery.of(context).devicePixelRatio > 1.0,
  /// ),
  /// ```
  final bool retinaMode;

  /// This callback will be execute if some errors occur when fetching tiles.
  final ErrorTileCallBack errorTileCallback;

  final TemplateFunction templateFunction;

  TileLayerOptions({
    Key key,
    this.urlTemplate,
    double tileSize = 256.0,
    double minZoom = 0.0,
    double maxZoom = 18.0,
    this.minNativeZoom,
    this.maxNativeZoom,
    this.zoomReverse = false,
    double zoomOffset = 0.0,
    Map<String, dynamic> additionalOptions,
    this.subdomains = const <String>[],
    this.keepBuffer = 2,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.placeholderImage,
    this.errorImage,
    this.tileProvider = const NonCachingNetworkTileProvider(),
    this.tms = false,
    // ignore: avoid_init_to_null
    this.wmsOptions = null,
    this.opacity = 1.0,
    // Tiles will not update more than once every `updateInterval` milliseconds
    // (default 200) when panning. It can be 0 (but it will calculating for
    // loading tiles every frame when panning / zooming, flutter is fast) This
    // can save some fps and even bandwidth (ie. when fast panning / animating
    // between long distances in short time)
    // TODO: change to Duration
    int updateInterval = 200,
    // Tiles fade in duration in milliseconds (default 100).  This can be set to
    // 0 to avoid fade in
    // TODO: change to Duration
    int tileFadeInDuration = 100,
    this.tileFadeInStart = 0.0,
    this.tileFadeInStartWhenOverride = 0.0,
    this.overrideTilesWhenUrlChanges = false,
    this.retinaMode = false,
    this.errorTileCallback,
    Stream<Null> rebuild,
    this.templateFunction = util.template,
  })  : updateInterval =
            updateInterval <= 0 ? null : Duration(milliseconds: updateInterval),
        tileFadeInDuration = tileFadeInDuration <= 0
            ? null
            : Duration(milliseconds: tileFadeInDuration),
        assert(tileFadeInStart >= 0.0 && tileFadeInStart <= 1.0),
        assert(tileFadeInStartWhenOverride >= 0.0 &&
            tileFadeInStartWhenOverride <= 1.0),
        maxZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && !zoomReverse
                ? maxZoom - 1.0
                : maxZoom,
        minZoom =
            wmsOptions == null && retinaMode && maxZoom > 0.0 && zoomReverse
                ? math.max(minZoom + 1.0, 0.0)
                : minZoom,
        zoomOffset = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (zoomReverse ? zoomOffset - 1.0 : zoomOffset + 1.0)
            : zoomOffset,
        tileSize = wmsOptions == null && retinaMode && maxZoom > 0.0
            ? (tileSize / 2.0).floorToDouble()
            : tileSize,
        // copy additionalOptions Map if not null, so we can safely compare old
        // and new Map inside didUpdateWidget with MapEquality.
        additionalOptions = additionalOptions == null
            ? const <String, dynamic>{}
            : Map.from(additionalOptions),
        super(key: key, rebuild: rebuild);
}

class WMSTileLayerOptions {
  final service = 'WMS';
  final request = 'GetMap';

  /// url of WMS service.
  /// Ex.: 'http://ows.mundialis.de/services/service?'
  final String baseUrl;

  /// list of WMS layers to show
  final List<String> layers;

  /// list of WMS styles
  final List<String> styles;

  /// WMS image format (use 'image/png' for layers with transparency)
  final String format;

  /// Version of the WMS service to use
  final String version;

  /// tile transperency flag
  final bool transparent;

  // TODO find a way to implicit pass of current map [Crs]
  final Crs crs;

  /// other request parameters
  final Map<String, String> otherParameters;

  String _encodedBaseUrl;

  double _versionNumber;

  WMSTileLayerOptions({
    @required this.baseUrl,
    this.layers = const [],
    this.styles = const [],
    this.format = 'image/png',
    this.version = '1.1.1',
    this.transparent = true,
    this.crs = const Epsg3857(),
    this.otherParameters = const {},
  }) {
    _versionNumber = double.tryParse(version.split('.').take(2).join('.')) ?? 0;
    _encodedBaseUrl = _buildEncodedBaseUrl();
  }

  String _buildEncodedBaseUrl() {
    final projectionKey = _versionNumber >= 1.3 ? 'crs' : 'srs';
    final buffer = StringBuffer(baseUrl)
      ..write('&service=$service')
      ..write('&request=$request')
      ..write('&layers=${layers.map(Uri.encodeComponent).join(',')}')
      ..write('&styles=${styles.map(Uri.encodeComponent).join(',')}')
      ..write('&format=${Uri.encodeComponent(format)}')
      ..write('&$projectionKey=${Uri.encodeComponent(crs.code)}')
      ..write('&version=${Uri.encodeComponent(version)}')
      ..write('&transparent=$transparent');
    otherParameters
        .forEach((k, v) => buffer.write('&$k=${Uri.encodeComponent(v)}'));
    return buffer.toString();
  }

  String getUrl(Coords coords, int tileSize, bool retinaMode) {
    final tileSizePoint = CustomPoint(tileSize, tileSize);
    final nvPoint = coords.scaleBy(tileSizePoint);
    final sePoint = nvPoint + tileSizePoint;
    final nvCoords = crs.pointToLatLng(nvPoint, coords.z);
    final seCoords = crs.pointToLatLng(sePoint, coords.z);
    final nv = crs.projection.project(nvCoords);
    final se = crs.projection.project(seCoords);
    final bounds = Bounds(nv, se);
    final bbox = (_versionNumber >= 1.3 && crs is Epsg4326)
        ? [bounds.min.y, bounds.min.x, bounds.max.y, bounds.max.x]
        : [bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y];

    final buffer = StringBuffer(_encodedBaseUrl);
    buffer.write('&width=${retinaMode ? tileSize * 2 : tileSize}');
    buffer.write('&height=${retinaMode ? tileSize * 2 : tileSize}');
    buffer.write('&bbox=${bbox.join(',')}');
    return buffer.toString();
  }
}

class TileLayerWidget extends StatelessWidget {
  final TileLayerOptions options;

  TileLayerWidget({Key key, @required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.of(context);

    return TileLayer(
      mapState: mapState,
      stream: mapState.onMoved,
      options: options,
    );
  }
}

class TileLayer extends StatefulWidget {
  final TileLayerOptions options;
  final MapState mapState;
  final Stream<Null> stream;

  TileLayer({
    this.options,
    this.mapState,
    this.stream,
  }) : super(key: options.key);

  @override
  State<StatefulWidget> createState() {
    return _TileLayerState();
  }
}

class _TileLayerState extends State<TileLayer> with TickerProviderStateMixin {
  MapState get map => widget.mapState;

  TileLayerOptions get options => widget.options;
  Bounds _globalTileRange;
  Tuple2<double, double> _wrapX;
  Tuple2<double, double> _wrapY;
  double _tileZoom;

  //ignore: unused_field
  Level _level;
  StreamSubscription _moveSub;
  StreamController<LatLng> _throttleUpdate;
  CustomPoint _tileSize;

  final Map<String, Tile> _tiles = {};
  final Map<double, Level> _levels = {};

  @override
  void initState() {
    super.initState();
    _tileSize = CustomPoint(options.tileSize, options.tileSize);
    _resetView();
    _update(null);
    _moveSub = widget.stream.listen((_) => _handleMove());

    _initThrottleUpdate();
  }

  @override
  void didUpdateWidget(TileLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reloadTiles = false;

    if (oldWidget.options.tileSize != options.tileSize) {
      _tileSize = CustomPoint(options.tileSize, options.tileSize);
      reloadTiles = true;
    }

    if (oldWidget.options.retinaMode != options.retinaMode) {
      reloadTiles = true;
    }

    if (oldWidget.options.updateInterval != options.updateInterval) {
      _throttleUpdate?.close();
      _initThrottleUpdate();
    }

    if (!reloadTiles) {
      final oldUrl = oldWidget.options.wmsOptions?._encodedBaseUrl ??
          oldWidget.options.urlTemplate;
      final newUrl = options.wmsOptions?._encodedBaseUrl ?? options.urlTemplate;

      final oldOptions = oldWidget.options.additionalOptions;
      final newOptions = options.additionalOptions;

      if (oldUrl != newUrl ||
          !(const MapEquality()).equals(oldOptions, newOptions)) {
        if (options.overrideTilesWhenUrlChanges) {
          for (var tile in _tiles.values) {
            tile.imageProvider = options.tileProvider
                .getImage(_wrapCoords(tile.coords), options);
            tile.loadTileImage();
          }
        } else {
          reloadTiles = true;
        }
      }
    }

    if (reloadTiles) {
      _removeAllTiles();
      _resetView();
      _update(null);
    }
  }

  void _initThrottleUpdate() {
    if (options.updateInterval == null) {
      _throttleUpdate = null;
    } else {
      _throttleUpdate = StreamController<LatLng>(sync: true);
      _throttleUpdate.stream.transform(
        util.throttleStreamTransformerWithTrailingCall<LatLng>(
          options.updateInterval,
        ),
      )..listen(_update);
    }
  }

  @override
  void dispose() {
    _removeAllTiles();
    _moveSub?.cancel();
    options.tileProvider.dispose();
    _throttleUpdate?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tilesToRender = _tiles.values.toList()..sort();

    var tileWidgets = <Widget>[
      for (var tile in tilesToRender) _createTileWidget(tile)
    ];

    return Opacity(
      opacity: options.opacity,
      child: Container(
        color: options.backgroundColor,
        child: Stack(
          children: tileWidgets,
        ),
      ),
    );
  }

  Widget _createTileWidget(Tile tile) {
    var tilePos = tile.tilePos;
    var level = tile.level;
    var tileSize = getTileSize();
    var pos = (tilePos).multiplyBy(level.scale) + level.translatePoint;
    var width = tileSize.x * level.scale;
    var height = tileSize.y * level.scale;

    final Widget content = AnimatedTile(
      tile: tile,
      errorImage: options.errorImage,
    );

    return Positioned(
      key: ValueKey(tile.coordsKey),
      left: pos.x.toDouble(),
      top: pos.y.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
      child: content,
    );
  }

  void _abortLoading() {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.coords.z != _tileZoom) {
        if (tile.loaded == null) {
          toRemove.add(entry.key);
        }
      }
    }

    for (var key in toRemove) {
      var tile = _tiles[key];

      tile.tileReady = null;
      tile.dispose();
      _tiles.remove(key);
    }
  }

  CustomPoint getTileSize() {
    return _tileSize;
  }

  bool _hasLevelChildren(double lvl) {
    for (var tile in _tiles.values) {
      if (tile.coords.z == lvl) {
        return true;
      }
    }

    return false;
  }

  Level _updateLevels() {
    var zoom = _tileZoom;
    var maxZoom = options.maxZoom;

    if (zoom == null) return null;

    var toRemove = <double>[];
    for (var entry in _levels.entries) {
      var z = entry.key;
      var lvl = entry.value;

      if (z == zoom || _hasLevelChildren(z)) {
        lvl.zIndex = maxZoom - (zoom - z).abs();
      } else {
        toRemove.add(z);
      }
    }

    for (var z in toRemove) {
      _removeTilesAtZoom(z);
      _levels.remove(z);
    }

    var level = _levels[zoom];
    var map = this.map;

    if (level == null) {
      level = _levels[zoom] = Level();
      level.zIndex = maxZoom;
      level.origin = map.project(map.unproject(map.getPixelOrigin()), zoom) ??
          CustomPoint(0.0, 0.0);
      level.zoom = zoom;

      _setZoomTransform(level, map.center, map.zoom);
    }

    return _level = level;
  }

  void _pruneTiles() {
    if (map == null) {
      return;
    }

    var zoom = _tileZoom;
    if (zoom == null) {
      _removeAllTiles();
      return;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      tile.retain = tile.current;
    }

    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (tile.current && !tile.active) {
        var coords = tile.coords;
        if (!_retainParent(coords.x, coords.y, coords.z, coords.z - 5)) {
          _retainChildren(coords.x, coords.y, coords.z, coords.z + 2);
        }
      }
    }

    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      var tile = entry.value;

      if (!tile.retain) {
        toRemove.add(entry.key);
      }
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeTilesAtZoom(double zoom) {
    var toRemove = <String>[];
    for (var entry in _tiles.entries) {
      if (entry.value.coords.z != zoom) {
        continue;
      }
      toRemove.add(entry.key);
    }

    for (var key in toRemove) {
      _removeTile(key);
    }
  }

  void _removeAllTiles() {
    var toRemove = Map<String, Tile>.from(_tiles);

    for (var key in toRemove.keys) {
      _removeTile(key);
    }
  }

  bool _retainParent(double x, double y, double z, double minZoom) {
    var x2 = (x / 2).floorToDouble();
    var y2 = (y / 2).floorToDouble();
    var z2 = z - 1;
    var coords2 = Coords(x2, y2);
    coords2.z = z2;

    var key = _tileCoordsToKey(coords2);

    var tile = _tiles[key];
    if (tile != null) {
      if (tile.active) {
        tile.retain = true;
        return true;
      } else if (tile.loaded != null) {
        tile.retain = true;
      }
    }

    if (z2 > minZoom) {
      return _retainParent(x2, y2, z2, minZoom);
    }

    return false;
  }

  void _retainChildren(double x, double y, double z, double maxZoom) {
    for (var i = 2 * x; i < 2 * x + 2; i++) {
      for (var j = 2 * y; j < 2 * y + 2; j++) {
        var coords = Coords(i, j);
        coords.z = z + 1;

        var key = _tileCoordsToKey(coords);

        var tile = _tiles[key];
        if (tile != null) {
          if (tile.active) {
            tile.retain = true;
            continue;
          } else if (tile.loaded != null) {
            tile.retain = true;
          }
        }

        if (z + 1 < maxZoom) {
          _retainChildren(i, j, z + 1, maxZoom);
        }
      }
    }
  }

  void _resetView() {
    _setView(map.center, map.zoom);
  }

  double _clampZoom(double zoom) {
    if (null != options.minNativeZoom && zoom < options.minNativeZoom) {
      return options.minNativeZoom;
    }

    if (null != options.maxNativeZoom && options.maxNativeZoom < zoom) {
      return options.maxNativeZoom;
    }

    return zoom;
  }

  void _setView(LatLng center, double zoom) {
    var tileZoom = _clampZoom(zoom.roundToDouble());
    if ((options.maxZoom != null && tileZoom > options.maxZoom) ||
        (options.minZoom != null && tileZoom < options.minZoom)) {
      tileZoom = null;
    }

    _tileZoom = tileZoom;

    _abortLoading();

    _updateLevels();
    _resetGrid();

    if (_tileZoom != null) {
      _update(center);
    }

    _pruneTiles();
  }

  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i], center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = map.getZoomScale(zoom, level.zoom);
    var pixelOrigin = map.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var translate = level.origin.multiplyBy(scale) - pixelOrigin;
    level.translatePoint = translate;
    level.scale = scale;
  }

  void _resetGrid() {
    var map = this.map;
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    var bounds = map.getPixelWorldBounds(_tileZoom);
    if (bounds != null) {
      _globalTileRange = _pxBoundsToTileRange(bounds);
    }

    // wrapping
    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first =
          (map.project(LatLng(0.0, crs.wrapLng.item1), tileZoom).x / tileSize.x)
              .floorToDouble();
      var second =
          (map.project(LatLng(0.0, crs.wrapLng.item2), tileZoom).x / tileSize.y)
              .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first =
          (map.project(LatLng(crs.wrapLat.item1, 0.0), tileZoom).y / tileSize.x)
              .floorToDouble();
      var second =
          (map.project(LatLng(crs.wrapLat.item2, 0.0), tileZoom).y / tileSize.y)
              .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }

  void _handleMove() {
    var tileZoom = _clampZoom(map.zoom.roundToDouble());

    if (_tileZoom == null) {
      // if there is no _tileZoom available it means we are out within zoom level
      // we will restore fully via _setView call if we are back on trail
      if ((options.maxZoom != null && tileZoom <= options.maxZoom) &&
          (options.minZoom != null && tileZoom >= options.minZoom)) {
        _tileZoom = tileZoom;
        setState(() {
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        });
      }
    } else {
      setState(() {
        if ((tileZoom - _tileZoom).abs() >= 1) {
          // It was a zoom lvl change
          _setView(map.center, tileZoom);

          _setZoomTransforms(map.center, map.zoom);
        } else {
          if (null == _throttleUpdate) {
            _update(null);
          } else {
            _throttleUpdate.add(null);
          }

          _setZoomTransforms(map.center, map.zoom);
        }
      });
    }
  }

  Bounds _getTiledPixelBounds(LatLng center) {
    var scale = map.getZoomScale(map.zoom, _tileZoom);
    var pixelCenter = map.project(center, _tileZoom).floor();
    var halfSize = map.size / (scale * 2);

    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  // Private method to load tiles in the grid's active zoom level according to
  // map bounds
  void _update(LatLng center) {
    if (map == null || _tileZoom == null) {
      return;
    }

    var zoom = _clampZoom(map.zoom);
    center ??= map.center;

    var pixelBounds = _getTiledPixelBounds(center);
    var tileRange = _pxBoundsToTileRange(pixelBounds);
    var tileCenter = tileRange.getCenter();
    var queue = <Coords<num>>[];
    var margin = options.keepBuffer;
    var noPruneRange = Bounds(
      tileRange.bottomLeft - CustomPoint(margin, -margin),
      tileRange.topRight + CustomPoint(margin, -margin),
    );

    for (var entry in _tiles.entries) {
      var tile = entry.value;
      var c = tile.coords;

      if (tile.current == true &&
          (c.z != _tileZoom || !noPruneRange.contains(CustomPoint(c.x, c.y)))) {
        tile.current = false;
      }
    }

    // _update just loads more tiles. If the tile zoom level differs too much
    // from the map's, let _setView reset levels and prune old tiles.
    if ((zoom - _tileZoom).abs() > 1) {
      _setView(center, zoom);
      return;
    }

    // create a queue of coordinates to load tiles from
    for (var j = tileRange.min.y; j <= tileRange.max.y; j++) {
      for (var i = tileRange.min.x; i <= tileRange.max.x; i++) {
        var coords = Coords(i.toDouble(), j.toDouble());
        coords.z = _tileZoom;

        if (!_isValidTile(coords)) {
          continue;
        }

        var tile = _tiles[_tileCoordsToKey(coords)];
        if (tile != null) {
          tile.current = true;
        } else {
          queue.add(coords);
        }
      }
    }

    // sort tile queue to load tiles in order of their distance to center
    queue.sort((a, b) =>
        (a.distanceTo(tileCenter) - b.distanceTo(tileCenter)).toInt());

    for (var i = 0; i < queue.length; i++) {
      _addTile(queue[i]);
    }
  }

  bool _isValidTile(Coords coords) {
    var crs = map.options.crs;

    if (!crs.infinite) {
      // don't load tile if it's out of bounds and not wrapped
      var bounds = _globalTileRange;
      if ((crs.wrapLng == null &&
              (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
          (crs.wrapLat == null &&
              (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
        return false;
      }
    }

    return true;
  }

  String _tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  //ignore: unused_element
  Coords _keyToTileCoords(String key) {
    var k = key.split(':');
    var coords = Coords(double.parse(k[0]), double.parse(k[1]));
    coords.z = double.parse(k[2]);

    return coords;
  }

  void _removeTile(String key) {
    var tile = _tiles[key];
    if (tile == null) {
      return;
    }

    tile.dispose();
    _tiles.remove(key);
  }

  void _addTile(Coords<double> coords) {
    var tileCoordsToKey = _tileCoordsToKey(coords);
    var tile = _tiles[tileCoordsToKey] = Tile(
      coords: coords,
      coordsKey: tileCoordsToKey,
      tilePos: _getTilePos(coords),
      current: true,
      level: _levels[coords.z],
      imageProvider:
          options.tileProvider.getImage(_wrapCoords(coords), options),
      tileReady: _tileReady,
    );

    tile.loadTileImage();
  }

  void _tileReady(Coords<double> coords, dynamic error, Tile tile) {
    if (null != error) {
      print(error);

      tile.loadError = true;

      if (options.errorTileCallback != null) {
        options.errorTileCallback(tile, error);
      }
    } else {
      tile.loadError = false;
    }

    var key = _tileCoordsToKey(coords);
    tile = _tiles[key];
    if (null == tile) {
      return;
    }

    var fadeInStart = tile.loaded == null
        ? options.tileFadeInStart
        : options.tileFadeInStartWhenOverride;
    tile.loaded = DateTime.now();
    if (options.tileFadeInDuration == null ||
        fadeInStart == 1.0 ||
        (tile.loadError && null == options.errorImage)) {
      tile.active = true;
    } else {
      tile.startFadeInAnimation(
        options.tileFadeInDuration,
        this,
        from: fadeInStart,
      );
    }

    if (mounted) {
      setState(() {});
    }

    if (_noTilesToLoad()) {
      // Wait a bit more than tileFadeInDuration (the duration of the tile
      // fade-in) to trigger a pruning.
      Future.delayed(
        options.tileFadeInDuration != null
            ? options.tileFadeInDuration + const Duration(milliseconds: 50)
            : const Duration(milliseconds: 50),
        () {
          if (mounted) {
            setState(_pruneTiles);
          }
        },
      );
    }
  }

  CustomPoint _getTilePos(Coords coords) {
    var level = _levels[coords.z];
    return coords.scaleBy(getTileSize()) - level.origin;
  }

  Coords _wrapCoords(Coords coords) {
    var newCoords = Coords(
      _wrapX != null
          ? util.wrapNum(coords.x.toDouble(), _wrapX)
          : coords.x.toDouble(),
      _wrapY != null
          ? util.wrapNum(coords.y.toDouble(), _wrapY)
          : coords.y.toDouble(),
    );
    newCoords.z = coords.z.toDouble();
    return newCoords;
  }

  Bounds _pxBoundsToTileRange(Bounds bounds) {
    var tileSize = getTileSize();
    return Bounds(
      bounds.min.unscaleBy(tileSize).floor(),
      bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
    );
  }

  bool _noTilesToLoad() {
    for (var entry in _tiles.entries) {
      if (entry.value.loaded == null) {
        return false;
      }
    }
    return true;
  }
}

typedef TileReady = void Function(
    Coords<double> coords, dynamic error, Tile tile);

class Tile implements Comparable<Tile> {
  final String coordsKey;
  final Coords<double> coords;
  final CustomPoint<num> tilePos;
  ImageProvider imageProvider;
  final Level level;

  bool current;
  bool retain;
  bool active;
  bool loadError;
  DateTime loaded;

  AnimationController animationController;

  double get opacity => animationController == null
      ? (active ? 1.0 : 0.0)
      : animationController.value;

  // callback when tile is ready / error occurred
  // it maybe be null forinstance when download aborted
  TileReady tileReady;
  ImageInfo imageInfo;
  ImageStream _imageStream;
  ImageStreamListener _listener;

  Tile({
    this.coordsKey,
    this.coords,
    this.tilePos,
    this.imageProvider,
    this.tileReady,
    this.level,
    this.current = false,
    this.active = false,
    this.retain = false,
    this.loadError = false,
  });

  void loadTileImage() {
    try {
      final oldImageStream = _imageStream;
      _imageStream = imageProvider.resolve(ImageConfiguration());

      if (_imageStream.key != oldImageStream?.key) {
        oldImageStream?.removeListener(_listener);

        _listener = ImageStreamListener(_tileOnLoad, onError: _tileOnError);
        _imageStream.addListener(_listener);
      }
    } catch (e, s) {
      // make sure all exception is handled - #444 / #536
      _tileOnError(e, s);
    }
  }

  // call this before GC!
  void dispose([bool evict = false]) {
    if (evict && imageProvider != null) {
      imageProvider
          .evict()
          .then((bool succ) => print('evict tile: $coords -> $succ'))
          .catchError((error) => print('evict tile: $coords -> $error'));
    }

    animationController?.removeStatusListener(_onAnimateEnd);
    animationController?.dispose();
    _imageStream?.removeListener(_listener);
  }

  void startFadeInAnimation(Duration duration, TickerProvider vsync,
      {double from}) {
    animationController?.removeStatusListener(_onAnimateEnd);

    animationController = AnimationController(duration: duration, vsync: vsync)
      ..addStatusListener(_onAnimateEnd);

    animationController.forward(from: from);
  }

  void _onAnimateEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      active = true;
    }
  }

  void _tileOnLoad(ImageInfo imageInfo, bool synchronousCall) {
    if (null != tileReady) {
      this.imageInfo = imageInfo;
      tileReady(coords, null, this);
    }
  }

  void _tileOnError(dynamic exception, StackTrace stackTrace) {
    if (null != tileReady) {
      tileReady(
          coords, exception ?? 'Unknown exception during loadTileImage', this);
    }
  }

  @override
  int compareTo(Tile other) {
    var zIndexA = level.zIndex;
    var zIndexB = other.level.zIndex;

    if (zIndexA == zIndexB) {
      return 0;
    } else {
      return zIndexB.compareTo(zIndexA);
    }
  }

  @override
  int get hashCode => coords.hashCode;

  @override
  bool operator ==(other) {
    return other is Tile && coords == other.coords;
  }
}

class AnimatedTile extends StatefulWidget {
  final Tile tile;
  final ImageProvider errorImage;

  AnimatedTile({Key key, @required this.tile, this.errorImage})
      : assert(null != tile),
        super(key: key);

  @override
  _AnimatedTileState createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile> {
  bool listenerAttached = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.tile.opacity,
      child: (widget.tile.loadError && widget.errorImage != null)
          ? Image(
              image: widget.errorImage,
              fit: BoxFit.fill,
            )
          : RawImage(
              image: widget.tile.imageInfo?.image,
              fit: BoxFit.fill,
            ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (null != widget.tile.animationController) {
      widget.tile.animationController.addListener(_handleChange);
      listenerAttached = true;
    }
  }

  @override
  void dispose() {
    if (listenerAttached) {
      widget.tile.animationController?.removeListener(_handleChange);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listenerAttached && null != widget.tile.animationController) {
      widget.tile.animationController.addListener(_handleChange);
      listenerAttached = true;
    }
  }

  void _handleChange() {
    if (mounted) {
      setState(() {});
    }
  }
}

class Level {
  double zIndex;
  CustomPoint origin;
  double zoom;
  CustomPoint translatePoint;
  double scale;
}

class Coords<T extends num> extends CustomPoint<T> {
  T z;

  Coords(T x, T y) : super(x, y);

  @override
  String toString() => 'Coords($x, $y, $z)';

  @override
  bool operator ==(dynamic other) {
    if (other is Coords) {
      return x == other.x && y == other.y && z == other.z;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(x.hashCode, y.hashCode, z.hashCode);
}
