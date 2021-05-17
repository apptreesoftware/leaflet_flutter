import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

import '../../widgets/drawer.dart';

class CustomCrsPage extends StatefulWidget {
  static const String route = 'custom_crs';

  @override
  _CustomCrsPageState createState() => _CustomCrsPageState();
}

class _CustomCrsPageState extends State<CustomCrsPage> {
  Proj4Crs epsg3413CRS;

  double maxZoom;

  // Define start center
  proj4.Point point = proj4.Point(x: 65.05166470332148, y: -19.171744826394896);

  String initText = 'Map centered to';

  proj4.Projection epsg4326;

  proj4.Projection epsg3413;

  @override
  void initState() {
    super.initState();

    // EPSG:4326 is a predefined projection ships with proj4dart
    epsg4326 = proj4.Projection('EPSG:4326');

    // EPSG:3413 is a user-defined projection from a valid Proj4 definition string
    // From: http://epsg.io/3413, proj definition: http://epsg.io/3413.proj4
    // Find Projection by name or define it if not exists
    epsg3413 = proj4.Projection('EPSG:3413') ??
        proj4.Projection.add('EPSG:3413',
            '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs');

    // 9 example zoom level resolutions
    final resolutions = <double>[
      32768,
      16384,
      8192,
      4096,
      2048,
      1024,
      512,
      256,
      128,
    ];

    final epsg3413Bounds = Bounds<double>(
      CustomPoint<double>(-4511619.0, -4511336.0),
      CustomPoint<double>(4510883.0, 4510996.0),
    );

    maxZoom = (resolutions.length - 1).toDouble();

    // Define CRS
    epsg3413CRS = Proj4Crs.fromFactory(
      // CRS code
      code: 'EPSG:3413',
      // your proj4 delegate
      proj4Projection: epsg3413,
      // Resolution factors (projection units per pixel, for example meters/pixel)
      // for zoom levels; specify either scales or resolutions, not both
      resolutions: resolutions,
      // Bounds of the CRS, in projected coordinates
      // (if not specified, the layer's which uses this CRS will be infinite)
      bounds: epsg3413Bounds,
      // Tile origin, in projected coordinates, if set, this overrides the transformation option
      // Some goeserver changes origin based on zoom level
      // and some are not at all (use explicit/implicit null or use [CustomPoint(0, 0)])
      // @see https://github.com/kartena/Proj4Leaflet/pull/171
      origins: [CustomPoint(0, 0)],
      // Scale factors (pixels per projection unit, for example pixels/meter) for zoom levels;
      // specify either scales or resolutions, not both
      scales: null,
      // The transformation to use when transforming projected coordinates into pixel coordinates
      transformation: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom CRS')),
      drawer: buildDrawer(context, CustomCrsPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 2.0),
              child: Text(
                'This map is in EPSG:3413',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16.0,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 2.0),
              child: Text(
                '$initText (${point.x.toStringAsFixed(5)}, ${point.y.toStringAsFixed(5)}) in EPSG:4326.',
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 2.0, bottom: 2.0),
              child: Text(
                'Which is (${epsg4326.transform(epsg3413, point).x.toStringAsFixed(2)}, ${epsg4326.transform(epsg3413, point).y.toStringAsFixed(2)}) in EPSG:3413.',
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 2.0, bottom: 8.0),
              child: Text('Tap on map to get more coordinates!'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  // Set the default CRS
                  crs: epsg3413CRS,
                  center: LatLng(point.x, point.y),
                  zoom: 3.0,
                  // Set maxZoom usually scales.length - 1 OR resolutions.length - 1
                  // but not greater
                  maxZoom: maxZoom,
                  onTap: (p) => setState(() {
                    initText = 'You clicked at';
                    point = proj4.Point(x: p.latitude, y: p.longitude);
                  }),
                ),
                layers: [
                  TileLayerOptions(
                    opacity: 1.0,
                    backgroundColor: Colors.transparent,
                    wmsOptions: WMSTileLayerOptions(
                      // Set the WMS layer's CRS
                      crs: epsg3413CRS,
                      transparent: true,
                      format: 'image/jpeg',
                      baseUrl:
                          'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
                      layers: ['gebco_north_polar_view'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
