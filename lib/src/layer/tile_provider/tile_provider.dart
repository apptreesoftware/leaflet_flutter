import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_image/network.dart';
import 'package:flutter_map/flutter_map.dart';

abstract class TileProvider {
  const TileProvider();

  ImageProvider getImage(Coords coords, TileLayerOptions options);

  void dispose() {}

  String getTileUrl(Coords coords, TileLayerOptions options) {
    var urlTemplate = (options.wmsOptions != null)
        ? options.wmsOptions
            .getUrl(coords, options.tileSize.toInt(), options.retinaMode)
        : options.urlTemplate;

    final x = coords.x.round();
    final y = coords.y.round();
    final z = _getZoomForUrl(coords, options).round();

    var data = <String, dynamic>{
      'x': x,
      'y': options.tms ? invertY(y, z) : y,
      'z': z,
      's': getSubdomain(coords, options),
      'r': '@2x',
    };
    var allOpts = Map<String, dynamic>.from(data)
      ..addAll(options.additionalOptions);
    return options.templateFunction(urlTemplate, allOpts);
  }

  double _getZoomForUrl(Coords coords, TileLayerOptions options) {
    var zoom = coords.z;

    if (options.zoomReverse) {
      zoom = options.maxZoom - zoom;
    }

    return zoom += options.zoomOffset;
  }

  int invertY(int y, int z) {
    return ((1 << z) - 1) - y;
  }

  String getSubdomain(Coords coords, TileLayerOptions options) {
    if (options.subdomains.isEmpty) {
      return '';
    }
    var index = (coords.x + coords.y).round() % options.subdomains.length;
    return options.subdomains[index];
  }
}

class NetworkTileProvider extends TileProvider {
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImageWithRetry(getTileUrl(coords, options));
  }
}

class NonCachingNetworkTileProvider extends TileProvider {
  const NonCachingNetworkTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return NetworkImage(getTileUrl(coords, options));
  }
}

class AssetTileProvider extends TileProvider {
  const AssetTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return AssetImage(getTileUrl(coords, options));
  }
}

class FileTileProvider extends TileProvider {
  const FileTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return FileImage(File(getTileUrl(coords, options)));
  }
}

class CustomTileProvider extends TileProvider {
  final String Function(Coords coors, TileLayerOptions options) customTileUrl;

  const CustomTileProvider({@required this.customTileUrl});

  @override
  String getTileUrl(Coords coords, TileLayerOptions options) {
    return customTileUrl(coords, options);
  }

  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return AssetImage(getTileUrl(coords, options));
  }
}
