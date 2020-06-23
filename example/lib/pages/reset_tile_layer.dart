import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class ResetTileLayerPage extends StatefulWidget {
  static const String route = '/reset_tilelayer';
  @override
  ResetTileLayerPageState createState() {
    return ResetTileLayerPageState();
  }
}

class ResetTileLayerPageState extends State<ResetTileLayerPage> {
  StreamController<Null> resetController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
  }

  void _resetTiles() {
    resetController.add(null);
  }

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(51.5, -0.09),
        builder: (ctx) => Container(
          child: FlutterLogo(),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('TileLayer Reset')),
      drawer: buildDrawer(context, ResetTileLayerPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'TileLayers can be progromatically reset, disposing of cached files'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                children: <Widget>[
                  MaterialButton(
                    child: Text('Reset'),
                    onPressed: () => _resetTiles(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  TileLayerOptions(
                      reset: resetController.stream,
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
