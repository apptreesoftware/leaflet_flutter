[![BuildStatus](https://travis-ci.com/fleaflet/flutter_map.svg?branch=master)](https://travis-ci.org/johnpryan/flutter_map)
[![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map)<br/>
[Portugués do Brasil](README.pt-br.md) | [Inglês](README.md)

# flutter_map

Uma implementação em Dart do [Leaflet] para aplicativos em Flutter.

## Instalação

Adicione o flutter_map no seu pubspec:

```yaml
dependencies:
  flutter_map: any # or the latest version on Pub
```

### Android

Certifique que a seguitne permissão está presente no seu arquivo Android Manifest, localizado em:
`<project root>/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Uso

Configure o mapa usando `MapOptions` e as opções de camada:

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
Você também pode iniciar o mapa especificando os limites ao invés de um zoom central. 

```dart
MapOptions(
  bounds: LatLngBounds(LatLng(58.8, 6.1), LatLng(59, 6.2)),
  boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(8.0)),
),
```

### Provedor de mapas da Azure

Configure o mapa para usar os [Mapas da Azure](https://azure.com/maps) para usar o `MapOptions` e as opções de camada:

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

Para usar o Azure Maps você vai precisar de [criar uma conta e obter uma chave de acesso](https://docs.microsoft.com/en-us/azure/azure-maps/quick-demo-map-app)

### Abrindo o Stret Map Provider

Configure o map para usar [Open Street Map](https://openstreetmap.org) e então poderá usar o `MapOptions` e as opções de camadas:

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

### Camadas de Wigets

__Use a nova forma de criar camadas__ (compativel com a versão anterior)

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
    ]
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

### Customize o SRC

Por padrão flutter_map suporta somente as projeções WGS84 (EPSG:4326) e Google Marcador (EPSG:3857). Com a integração do [proj4dart](https://github.com/maRci002/proj4dart) qualquer sistema de referencia de coordenadas (SRC) pode ser definido e usado.

Definindo SRC customizados:

```dart
var resolutions = <double>[32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128];
var maxZoom = (resolutions.length - 1).toDouble();

var epsg3413CRS = Proj4Crs.fromFactory(
  code: 'EPSG:3413',
  proj4Projection:
      proj4.Projection.add('EPSG:3413', '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'),
  resolutions: resolutions
);
```

Uso de SRC Customizado em um mapa e com camadas WMS:

```dart
child: FlutterMap(
  options: MapOptions(
    // Set the map's CRS
    crs: epsg3413CRS,
    center: LatLng(65.05166470332148, -19.171744826394896),
    maxZoom: maxZoom,
  ),
  layers: [
    TileLayerOptions(
      wmsOptions: WMSTileLayerOptions(
        // Set the WMS layer's CRS too
        crs: epsg3413CRS,
        baseUrl: 'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
        layers: ['gebco_north_polar_view'],
      ),
    ),
  ],
);
```

Para mais detalhes visite [página demo de SRC Customizada](./example/lib/pages/custom_crs/Readme.md).

## Rodando o exemplo

Acesse o diretório `example/`  para um aplicativo de exemplo funcionável.

Para rodar isso, em um terminal use cd para entrar no diretório.
Então execute `unlimit -S 0n 2048` ([ref](https://github.com/trentpiercy/trace/issues/1#issuecomment-404494469)).
E então execute `flutter run` com um emulador já iniciado.

## Mapas offline

[Siga esse tutorial para pegar peças offline](https://tilemill-project.github.io/tilemill/docs/guides/osm-bright-mac-quickstart/)<br>
Se você tiver um mapa exportado para `.mbtiles`, você pode usar [mbtilesParaPng](https://github.com/alfanhui/mbtilesToPngs) desarquive dentro de `/{z}/{x}/{y}.png`.
Mova isso para o diretório Assets e adicione o asset no arquivo `pubspec.yaml`. Os requisitos mínimos para usar mapas offline são:

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

Certifique-se de que os PanBoundaries estão dentro dos limites do mapa off-line para evitar erros de ativos ausentes.<br>
Olhe o diretório `flutter_map_example/` para ver um exemplo funcionando.

Veja que aqui também é `FileTileProvider()`, você pode usar para carregar peças do filesystem (memória local).

## Plugins

- [flutter_map_marker_cluster](https://github.com/lpongetti/flutter_map_marker_cluster): Fornece a funcionalidade Beautiful Animated Marker Clustering.
- [user_location](https://github.com/igaurab/user_location_plugin): Um plugin para manusear o localização atual do usuário no FlutterMap.
- [flutter_map_tappable_polyline](https://github.com/OwnWeb/flutter_map_tappable_polyline): Um plugion para adicionar a callback do `onTap` no `Polyline`
- [lat_lon_grid_plugin](https://github.com/mat8854/lat_lon_grid_plugin): Adiciona uma grade de latitude e longitude como plugin do FlutterMap.
- [flutter_map_marker_popup](https://github.com/rorystephenson/flutter_map_marker_popup): Um plugin para mostrar popus customizáveis para os markers.
- [map_elevation](https://github.com/OwnWeb/map_elevation): Um widget que mostra a elevação de uma pista (polilinha) como o Leaflet.Elevation.

## Roteiro

Para os últimos roteiros, por favor veja o [Issue Tracker]

[Leaflet]: http://leafletjs.com/
[Mapbox]: https://www.mapbox.com/
[Issue Tracker]: https://github.com/johnpryan/flutter_map/issues
