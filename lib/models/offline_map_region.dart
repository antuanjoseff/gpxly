/// Regió de mapa offline disponible al servidor (un fitxer .mbtiles).
///
/// Es construeix a partir d'una feature del GeoJSON retornat per
/// `api/mapes/bounds.geojson`. [id] és el nom que cal fer servir per
/// descarregar el fitxer mbtiles corresponent.
class OfflineMapRegion {
  final String id;
  final String name;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;
  final Map<String, dynamic> geometry;
  final int? fileSizeBytes;

  const OfflineMapRegion({
    required this.id,
    required this.name,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
    required this.geometry,
    this.fileSizeBytes,
  });

  factory OfflineMapRegion.fromFeature(Map<String, dynamic> feature) {
    final props =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = (feature['id'] ?? props['id']).toString();
    final boundsStr = props['bounds']?.toString();
    final parts = boundsStr!.split(',').map(double.parse).toList();
    return OfflineMapRegion(
      id: id,
      name: props['name']?.toString() ?? id,
      minLon: parts[0],
      minLat: parts[1],
      maxLon: parts[2],
      maxLat: parts[3],
      geometry: (feature['geometry'] as Map).cast<String, dynamic>(),
      fileSizeBytes: int.tryParse(props['file_size_bytes']?.toString() ?? ''),
    );
  }
}
