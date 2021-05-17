import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

import '../widgets/drawer.dart';

class TileBuilderPage extends StatefulWidget {
  static const String route = '/tile_builder_example';

  @override
  _TileBuilderPageState createState() => _TileBuilderPageState();
}

class _TileBuilderPageState extends State<TileBuilderPage> {
  var darkMode = false;
  var loadingTime = false;
  var showCoords = false;
  var grid = false;

  // mix of [coordinateDebugTileBuilder] and [loadingTimeDebugTileBuilder] from tile_builder.dart
  Widget tileBuilder(BuildContext context, Widget tileWidget, Tile tile) {
    final coords = tile.coords;

    return Container(
      decoration: BoxDecoration(
        border: grid ? Border.all() : null,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          tileWidget,
          if (loadingTime || showCoords)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCoords)
                  Text(
                    '${coords.x.floor()} : ${coords.y.floor()} : ${coords.z.floor()}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                if (loadingTime)
                  Text(
                    tile.loaded == null
                        ? 'Loading'
                        // sometimes result is negative which shouldn't happen, abs() corrects it
                        : '${(tile.loaded.millisecond - tile.loadStarted.millisecond).abs()} ms',
                    style: Theme.of(context).textTheme.headline5,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tile builder')),
      drawer: buildDrawer(context, TileBuilderPage.route),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'grid',
            label: Text(
              grid ? 'Hide grid' : 'Show grid',
              textAlign: TextAlign.center,
            ),
            icon: Icon(grid ? Icons.grid_off : Icons.grid_on),
            onPressed: () => setState(() => grid = !grid),
          ),
          SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'coords',
            label: Text(
              showCoords ? 'Hide coords' : 'Show coords',
              textAlign: TextAlign.center,
            ),
            icon: Icon(showCoords ? Icons.unarchive : Icons.bug_report),
            onPressed: () => setState(() => showCoords = !showCoords),
          ),
          SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'ms',
            label: Text(
              loadingTime ? 'Hide loading time' : 'Show loading time',
              textAlign: TextAlign.center,
            ),
            icon: Icon(loadingTime ? Icons.timer_off : Icons.timer),
            onPressed: () => setState(() => loadingTime = !loadingTime),
          ),
          SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'dark-light',
            label: Text(
              darkMode ? 'Light mode' : 'Dark mode',
              textAlign: TextAlign.center,
            ),
            icon: Icon(darkMode ? Icons.brightness_high : Icons.brightness_2),
            onPressed: () => setState(() => darkMode = !darkMode),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(51.5, -0.09),
            zoom: 5.0,
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              tileProvider: NonCachingNetworkTileProvider(),
              tileBuilder: tileBuilder,
              tilesContainerBuilder:
                  darkMode ? darkModeTilesContainerBuilder : null,
            ),
            MarkerLayerOptions(
              markers: <Marker>[
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(51.5, -0.09),
                  builder: (ctx) => Container(
                    child: FlutterLogo(
                      key: ObjectKey(Colors.blue),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
