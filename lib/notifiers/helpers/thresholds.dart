class TrackThresholds {
  static const double nearThreshold = 10;
  static const double farThreshold = 35;
  static const int trendWindow = 6;
  static const Duration offTrackDelay = Duration(seconds: 20);

  // Parámetros de configuración de Hardware (GPS) para navegación
  static const int navGpsSeconds = 2; // Frecuencia rápida
  static const double navGpsMeters = 2.0; // Distancia mínima
  static const double navGpsAccuracy = 20.0; // Filtro de precisión

  static const double reverseMinDistance = 30;
}
