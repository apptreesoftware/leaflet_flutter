import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class MarkerAnchorPage extends StatefulWidget {
  static const String route = '/marker_anchors';

  @override
  MarkerAnchorPageState createState() {
    return MarkerAnchorPageState();
  }
}

class MarkerAnchorPageState extends State<MarkerAnchorPage> {
  AnchorPos anchorPos;

  @override
  void initState() {
    super.initState();
    anchorPos = AnchorPos.align(AnchorAlign.center);
  }

  void _setAnchorAlignPos(AnchorAlign alignOpt) {
    setState(() {
      anchorPos = AnchorPos.align(alignOpt);
    });
  }

  void _setAnchorExactlyPos(Anchor anchor) {
    setState(() {
      anchorPos = AnchorPos.exactly(anchor);
    });
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
        anchorPos: anchorPos,
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(53.3498, -6.2603),
        builder: (ctx) => Container(
          child: FlutterLogo(
            textColor: Colors.green,
          ),
        ),
        anchorPos: anchorPos,
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(48.8566, 2.3522),
        builder: (ctx) => Container(
          child: FlutterLogo(
            textColor: Colors.purple,
          ),
        ),
        anchorPos: anchorPos,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Marker Anchor Points')),
      drawer: buildDrawer(context, MarkerAnchorPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'Markers can be anchored to the top, bottom, left or right.'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    child: Text('Left'),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.left),
                  ),
                  MaterialButton(
                    child: Text('Right'),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.right),
                  ),
                  MaterialButton(
                    child: Text('Top'),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.top),
                  ),
                  MaterialButton(
                    child: Text('Bottom'),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.bottom),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    child: Text('Center'),
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.center),
                  ),
                  MaterialButton(
                    child: Text('Custom'),
                    onPressed: () => _setAnchorExactlyPos(Anchor(80.0, 80.0)),
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
