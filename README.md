[![CI](https://github.com/fleaflet/flutter_map/workflows/Tests/badge.svg)](https://github.com/fleaflet/flutter_map/actions?query=branch%3Amaster)
[![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map)

# flutter_map

A Dart implementation of [Leaflet] for Flutter apps.

## Installation

Add flutter_map to your pubspec:

```yaml
dependencies:
  flutter_map: any # or the latest version on Pub
```

### Android

Configure your app to use the `INTERNET` permission in the manifest file located
in `<project root>/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Usage

Configure the map using `MapOptions` and layer options:

```dart
Widget build(BuildContext context) {
  return FlutterMap(
    options: MapOptions(
      center: LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      TileLayerOptions(
        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        subdomains: ['a', 'b', 'c']
      ),
      MarkerLayerOptions(
        markers: [
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(51.5, -0.09),
            builder: (ctx) =>
            Container(
              child: FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
  );
}
```

Alternatively, initialize the map by specifying `bounds` instead of `center` and
`zoom`.

```dart
MapOptions(
  bounds: LatLngBounds(LatLng(58.8, 6.1), LatLng(59, 6.2)),
  boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
),
```

### Azure Maps provider

To configure [Azure Maps](https://azure.com/maps),  use the following
`MapOptions` and layer options:

```dart
Widget build(BuildContext context) {
  return new FlutterMap(
    options: new MapOptions(
      center: new LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      new TileLayerOptions(
        urlTemplate: "https://atlas.microsoft.com/map/tile/png?api-version=1&layer=basic&style=main&tileSize=256&view=Auto&zoom={z}&x={x}&y={y}&subscription-key={subscriptionKey}",
        additionalOptions: {
          'subscriptionKey': '<YOUR_AZURE_MAPS_SUBSCRIPTON_KEY>'
        },
      ),
      new MarkerLayerOptions(
        markers: [
          new Marker(
            width: 80.0,
            height: 80.0,
            point: new LatLng(51.5, -0.09),
            builder: (ctx) =>
            new Container(
              child: new FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
  );
}
```

To use Azure Maps, [set up an account and get a subscription
key][azure-maps-instructions]

### Open Street Map provider

Configure the map to use [Open Street Map][open-street-map] by using
the following `MapOptions` and layer options:

```dart
Widget build(BuildContext context) {
  return new FlutterMap(
    options: new MapOptions(
      center: new LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      new TileLayerOptions(
        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        subdomains: ['a', 'b', 'c']
      ),
      new MarkerLayerOptions(
        markers: [
          new Marker(
            width: 80.0,
            height: 80.0,
            point: new LatLng(51.5, -0.09),
            builder: (ctx) =>
            new Container(
              child: new FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
  );
}
```

### Widget Layers

__Use the new way to create layers__ (compatible with previous version)

```dart
Widget build(BuildContext context) {
  return FlutterMap(
    options: MapOptions(
      center: LatLng(51.5, -0.09),
      zoom: 13.0,
    ),
    layers: [
      MarkerLayerOptions(
        markers: [
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(51.5, -0.09),
            builder: (ctx) =>
            Container(
              child: FlutterLogo(),
            ),
          ),
        ],
      ),
    ],
    children: <Widget>[
      TileLayerWidget(options: TileLayerOptions(
        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        subdomains: ['a', 'b', 'c']
      )),
      MarkerLayerWidget(options: MarkerLayerOptions(
        markers: [
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(51.5, -0.09),
            builder: (ctx) =>
            Container(
              child: FlutterLogo(),
            ),
          ),
        ],
      )),
    ],
  );
}
```

### Custom CRS

By default flutter_map supports only WGS84 (EPSG:4326) and Google Mercator
(EPSG:3857) projections. The [proj4dart][proj4dart] package provides additional 
reference systems (CRS).

To use proj4dart, first define a custom CRS:

```dart
var resolutions = <double>[32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128];
var maxZoom = (resolutions.length - 1).toDouble();

var epsg3413CRS = Proj4Crs.fromFactory(
  code: 'EPSG:3413',
  proj4Projection:
      proj4.Projection.add('EPSG:3413', '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'),
  resolutions: resolutions,
);
```

Then use the custom CRS in the map layer and in WMS layers:

```dart
child: FlutterMap(
  options: MapOptions(
    // Set the map's CRS
    crs: epsg3413CRS,
    center: LatLng(65.05166470332148, -19.171744826394896),
    maxZoom: maxZoom,
  ),
  layers: [
    TileLayerOptions(
      wmsOptions: WMSTileLayerOptions(
        // Set the WMS layer's CRS too
        crs: epsg3413CRS,
        baseUrl: 'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
        layers: ['gebco_north_polar_view'],
      ),
    ),
  ],
);
```

For more details, see the  [custom CRS README][custom-crs-readme].

## Run the example

See the `example/` folder for a working example app.

To run it, in a terminal cd into the folder. Then execute `ulimit -S -n 2048`
([ref][ulimit-comment]). Then execute `flutter run` with a running emulator.

## Downloading and caching offline maps

This section provides an overview of the available caching tile providers. If
you would like to provide preconfigured and prepackaged map tiles to your app
users, see the 'Preconfigured Offline Maps' section below.

The two available options included in flutter_map

### 1. Use `NetworkImage`  by using `NonCachingNetworkTileProvider`

Whilst the name might make you think differently, it is designed to prevent you
from using it and expecting it to cache; because it doesn't.

The `FlutterMap` `NonCachingNetworkTileProvider` implementaion uses
`NetworkImage` which should cache images in memory until the app restart
(through `Image.network`). See the [Image.network][Image.network] docs and
[NetworkImage][NetworkImage-caching] docs for more details.

### 2. Using the `cached_network_image` dependency

This dependency has an `ImageProvider` that caches images to disk, which means
the cache persists through an app restart. You'll need to [include the
package](https://pub.dev/packages/cached_network_image/install) in your
`pubspec.yaml`.

Create your own provider using the code below:
```dart
import 'package:cached_network_image/cached_network_image.dart';
class CachedTileProvider extends TileProvider {
  const CachedTileProvider();
  @override
  ImageProvider getImage(Coords<num> coords, TileLayerOptions options) {
    return CachedNetworkImageProvider(
      getTileUrl(coords, options),
      //Now you can set options that determine how the image gets cached via whichever plugin you use.
    );
  }
}
```
Then, add the `CachedTileProvider` `TileProvider` to the appropriate
`TileLayerOptions`:

```dart
TileLayerOptions(
  urlTemplate: 'https://example.com/{x}/{y}/{z}',
  tileProvider: const CachedTileProvider()
)
```

## Offline Maps using TileMill

This section provides instructions for  preconfigured and prepackaged offline
maps. To see how to setup caching and downloading, see the 'Dynamically
Downloading & Caching Offline Maps' section above.

This guide uses an open source program called [TileMill][tilemill-homepage].

First, [install TileMill][install-tilemill] on your machine. Then, follow [these
instructions][tilemill].

Once you have your map exported to `.mbtiles`, you can use
[mbtilesToPng][mbTilesToPngs] to unpack into `/{z}/{x}/{y}.png`.

Move this to assets folder and add the appropriate asset directories to
`pubspec.yaml`. Minimum required fields for this solution are:

```dart
Widget build(ctx) {
  return FlutterMap(
    options: MapOptions(
      center: LatLng(56.704173, 11.543808),
      zoom: 13.0,
      swPanBoundary: LatLng(56.6877, 11.5089),
      nePanBoundary: LatLng(56.7378, 11.6644),
    ),
    layers: [
      TileLayerOptions(
        tileProvider: AssetTileProvider(),
        urlTemplate: "assets/offlineMap/{z}/{x}/{y}.png",
      ),
    ],
  );
}
```

A missing asset error will be thrown if the PanBoundaries are outside the
offline map boundary.

See the `flutter_map_example/` folder for a working example.

See also `FileTileProvider()`, which loads tiles from the filesystem.

## Plugins

- [flutter_map_tile_caching](https://github.com/JaffaKetchup/flutter_map_tile_caching): Provides ability to properly cache tiles for offline use & easily download a region of a map for later offline use
- [flutter_map_marker_cluster](https://github.com/lpongetti/flutter_map_marker_cluster): Provides Beautiful Animated Marker Clustering functionality
- [user_location](https://github.com/igaurab/user_location_plugin): A plugin to handle and plot the current user location in FlutterMap
- [flutter_map_location](https://github.com/Xennis/flutter_map_location): A plugin to request and display the users location and heading on the map
- [flutter_map_location_marker](https://github.com/tlserver/flutter_map_location_marker): A simple and powerful plugin display the users location and heading
- [flutter_map_tappable_polyline](https://github.com/OwnWeb/flutter_map_tappable_polyline): A plugin to add `onTap` callback to `Polyline`
- [lat_lon_grid_plugin](https://github.com/mat8854/lat_lon_grid_plugin): Adds a latitude / longitude grid as plugin to the FlutterMap
- [flutter_map_marker_popup](https://github.com/rorystephenson/flutter_map_marker_popup): A plugin to show customisable popups for markers.
- [map_elevation](https://github.com/OwnWeb/map_elevation): A widget to display elevation of a track (polyline) like Leaflet.Elevation
- [flutter_map_floating_marker_titles](https://github.com/androidseb/flutter_map_floating_marker_titles): Displaying floating marker titles on the map view
- [vector_map_tiles](https://pub.dev/packages/vector_map_tiles): A plugin that enables the use of vector tiles.

## Roadmap

For the latest roadmap, please see the [Issue Tracker]

[Issue Tracker]: https://github.com/johnpryan/flutter_map/issues
[Leaflet]: https://leafletjs.com/
[Mapbox]: https://www.mapbox.com/
[azure-maps-instructions]: https://docs.microsoft.com/en-us/azure/azure-maps/quick-demo-map-app
[custom-crs-readme]: ./example/lib/pages/custom_crs/Readme.md
[flutter_map_tile_caching]: https://github.com/JaffaKetchup/flutter_map_tile_caching
[mbTilesToPng]: https://github.com/alfanhui/mbtilesToPngs
[open-street-map]: https://openstreetmap.org 
[proj4dart]: https://github.com/maRci002/proj4dart
[tilemill]: https://tilemill-project.github.io/tilemill/docs/guides/osm-bright-mac-quickstart/
[install-tilemill]: https://tilemill-project.github.io/tilemill/docs/install/
[ulimit-comment]: https://github.com/trentpiercy/trace/issues/1#issuecomment-404494469
[Image.network]: https://api.flutter.dev/flutter/widgets/Image/Image.network.html
[NetworkImage-caching]: https://flutter.dev/docs/cookbook/images/network-image#placeholders-and-caching
[tilemill-homepage]: https://tilemill-project.github.io/tilemill/
