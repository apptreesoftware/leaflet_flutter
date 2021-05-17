import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import '../widgets/drawer.dart';

class MarkerRotatePage extends StatefulWidget {
  static const String route = '/marker_rotate';
  @override
  MarkerRotatePageState createState() {
    return MarkerRotatePageState();
  }
}

class MarkerRotatePageState extends State<MarkerRotatePage> {
  bool rotateMarkerLondon;
  bool rotateMarkerDublin;
  bool rotateMarkerParis;
  bool rotateMarkerLayerOptions = false;

  @override
  void initState() {
    super.initState();
  }

  void _setRotateMarkerLayerOptions() {
    setState(() {
      rotateMarkerLayerOptions = !rotateMarkerLayerOptions;
    });
  }

  void _setRotateMarkerLondon() {
    setState(() {
      if (rotateMarkerLondon == null) {
        rotateMarkerLondon = true;
      } else if (rotateMarkerLondon) {
        rotateMarkerLondon = false;
      } else {
        rotateMarkerLondon = null;
      }
    });
  }

  void _setRotateMarkerDublin() {
    setState(() {
      if (rotateMarkerDublin == null) {
        rotateMarkerDublin = true;
      } else if (rotateMarkerDublin) {
        rotateMarkerDublin = false;
      } else {
        rotateMarkerDublin = null;
      }
    });
  }

  void _setRotateMarkerParis() {
    setState(() {
      if (rotateMarkerParis == null) {
        rotateMarkerParis = true;
      } else if (rotateMarkerParis) {
        rotateMarkerParis = false;
      } else {
        rotateMarkerParis = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(51.5, -0.09),
        rotate: rotateMarkerLondon,
        builder: (ctx) => Container(
          child: FlutterLogo(),
        ),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(53.3498, -6.2603),
        rotate: rotateMarkerDublin,
        builder: (ctx) => Container(
          child: FlutterLogo(
            textColor: Colors.green,
          ),
        ),
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(48.8566, 2.3522),
        rotate: rotateMarkerParis,
        builder: (ctx) => Container(
          child: FlutterLogo(textColor: Colors.purple),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Marker rotate by Map')),
      drawer: buildDrawer(context, MarkerRotatePage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child:
                  Text('Markers can be counter rotated to the map rotation.'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                children: <Widget>[
                  MaterialButton(
                    onPressed: _setRotateMarkerLayerOptions,
                    child:
                        Text('Set by LayerOptions: $rotateMarkerLayerOptions'),
                  ),
                  MaterialButton(
                    onPressed: _setRotateMarkerLondon,
                    child: Text('Override Marker London: $rotateMarkerLondon'),
                  ),
                  MaterialButton(
                    onPressed: _setRotateMarkerDublin,
                    child: Text('Override Marker Dublin: $rotateMarkerDublin'),
                  ),
                  MaterialButton(
                    onPressed: _setRotateMarkerParis,
                    child: Text('Override Marker Paris: $rotateMarkerParis'),
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
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(
                    rotate: rotateMarkerLayerOptions,
                    markers: markers,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
