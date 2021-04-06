import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

import '../pages/zoombuttons_plugin_option.dart';
import '../widgets/drawer.dart';

class MapInsideListViewPage extends StatelessWidget {
  static const String route = 'map_inside_listview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map inside ListView')),
      drawer: buildDrawer(context, MapInsideListViewPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            Container(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                  plugins: [
                    ZoomButtonsPlugin(),
                  ],
                ),
                layers: [
                  ZoomButtonsPluginOption(
                    minZoom: 4,
                    maxZoom: 19,
                    mini: true,
                    padding: 10,
                    alignment: Alignment.bottomLeft,
                  )
                ],
                children: <Widget>[
                  TileLayerWidget(
                    options: TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                  ),
                  MovingWithoutRefreshAllMapMarkers(),
                ],
              ),
            ),
            Card(
              child: ListTile(
                  title: Text(
                      'Scrolling inside the map does not scroll the ListView')),
            ),
            SizedBox(height: 500),
            Card(child: ListTile(title: Text('look at that scrolling')))
          ],
        ),
      ),
    );
  }
}

class MovingWithoutRefreshAllMapMarkers extends StatefulWidget {
  @override
  State<StatefulWidget> createState() =>
      _MovingWithoutRefreshAllMapMarkersState();
}

class _MovingWithoutRefreshAllMapMarkersState
    extends State<MovingWithoutRefreshAllMapMarkers> {
  Marker _marker;
  Timer _timer;
  int _markerIndex = 0;

  @override
  void initState() {
    super.initState();
    _marker = _markers[_markerIndex];
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _marker = _markers[_markerIndex];
        _markerIndex = (_markerIndex + 1) % _markers.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayerWidget(
      options: MarkerLayerOptions(markers: <Marker>[_marker]),
    );
  }
}

List<Marker> _markers = [
  Marker(
    width: 80.0,
    height: 80.0,
    point: LatLng(51.5, -0.09),
    builder: (ctx) => Container(
      child: FlutterLogo(),
    ),
  ),
  Marker(
    width: 80.0,
    height: 80.0,
    point: LatLng(53.3498, -6.2603),
    builder: (ctx) => Container(
      child: FlutterLogo(),
    ),
  ),
  Marker(
    width: 80.0,
    height: 80.0,
    point: LatLng(48.8566, 2.3522),
    builder: (ctx) => Container(
      child: FlutterLogo(),
    ),
  ),
];
