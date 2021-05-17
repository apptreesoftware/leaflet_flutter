import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

import '../widgets/drawer.dart';

class StatefulMarkersPage extends StatefulWidget {
  static const String route = '/stateful_markers';

  @override
  _StatefulMarkersPageState createState() => _StatefulMarkersPageState();
}

class _StatefulMarkersPageState extends State<StatefulMarkersPage> {
  List<Marker> _markers;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _markers = [];
    _addMarker('key1');
    _addMarker('key2');
    _addMarker('key3');
    _addMarker('key4');
    _addMarker('key5');
    _addMarker('key6');
    _addMarker('key7');
    _addMarker('key8');
    _addMarker('key9');
    _addMarker('key10');
  }

  void _addMarker(String key) {
    _markers.add(Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(
            _random.nextDouble() * 10 + 48, _random.nextDouble() * 10 - 6),
        builder: (ctx) => _ColorMarker(),
        key: ValueKey(key)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stateful Markers')),
      drawer: buildDrawer(context, StatefulMarkersPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    // For example purposes. It is recommended to use
                    // TileProvider with a caching and retry strategy, like
                    // NetworkTileProvider or CachedNetworkTileProvider
                    tileProvider: NonCachingNetworkTileProvider(),
                  ),
                  MarkerLayerOptions(markers: _markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorMarker extends StatefulWidget {
  _ColorMarker({Key key}) : super(key: key);

  @override
  _ColorMarkerState createState() => _ColorMarkerState();
}

class _ColorMarkerState extends State<_ColorMarker> {
  Color color;

  @override
  void initState() {
    super.initState();
    color = _ColorGenerator.getColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: color);
  }
}

class _ColorGenerator {
  static List colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.indigo,
    Colors.amber,
    Colors.black,
    Colors.white,
    Colors.brown,
    Colors.pink,
    Colors.cyan
  ];

  static final Random _random = Random();

  static Color getColor() {
    return colorOptions[_random.nextInt(colorOptions.length)];
  }
}
