import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

import '../widgets/drawer.dart';

class WMSLayerPage extends StatelessWidget {
  static const String route = 'WMS layer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WMS Layer')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('This is a map that is showing (42.58, 12.43).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(42.58, 12.43),
                  zoom: 6.0,
                ),
                layers: [
                  TileLayerOptions(
                    wmsOptions: WMSTileLayerOptions(
                      baseUrl: 'https://{s}.s2maps-tiles.eu/wms/?',
                      layers: ['s2cloudless-2018_3857'],
                    ),
                    subdomains: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
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
