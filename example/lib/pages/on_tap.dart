import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class OnTapPage extends StatefulWidget {
  static const String route = 'on_tap';

  @override
  OnTapPageState createState() {
    return OnTapPageState();
  }
}

class OnTapPageState extends State<OnTapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static LatLng london = LatLng(51.5, -0.09);
  static LatLng paris = LatLng(48.8566, 2.3522);
  static LatLng dublin = LatLng(53.3498, -6.2603);

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: london,
        builder: (ctx) => Container(
            child: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Tapped on blue FlutterLogo Marker'),
            ));
          },
          child: FlutterLogo(),
        )),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: dublin,
        builder: (ctx) => Container(
            child: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Tapped on green FlutterLogo Marker'),
            ));
          },
          child: FlutterLogo(
            textColor: Colors.green,
          ),
        )),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: paris,
        builder: (ctx) => Container(
            child: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Tapped on purple FlutterLogo Marker'),
            ));
          },
          child: FlutterLogo(
            textColor: Colors.purple,
          ),
        )),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text('OnTap')),
      drawer: buildDrawer(context, OnTapPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('Try tapping on the markers'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                  maxZoom: 5.0,
                  minZoom: 3.0,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
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
