class TrackThresholds {
  static const double nearThreshold = 10;
  static const double farThreshold = 35;
  static const int trendWindow = 6;
  static const Duration offTrackDelay = Duration(seconds: 20);

  // GPS hardware
  static const int navGpsSeconds = 2;
  static const double navGpsMeters = 2.0;
  static const double navGpsAccuracy = 20.0;

  // Reverse detection
  static const double reverseMinDistance = 50;

  // Buffer de posicions
  static const int lastNPositions = 10;
  static const int mapMatchSegmentWindow = 80;

  // 🔥 Nous paràmetres
  static const int minPositionsLevel2 =
      5; // trending away, heading wrong, offtrack bàsic
  static const int minPositionsLevel3 =
      10; // reverse detection, trending robust

  // Final del track
  static const int minimumDitanceToGoal = 10;
  static const int minProgressRequired = 100;

  // Nou llindar per detectar aturades
  static const double stopSpeedThreshold = 0.5; // m/s

  // Gràfic d'elevacions
  static const double futureTrackVisibility = 0.3; // 30% of axis

  // LÍMIT MÀXIM D'ARXIUS COG PERSISTENTS A DISC
  static const int maxPersistentFiles = 10;

  // Velocitat estable
  static const int minSpeedWindowSeconds = 4; // finestra temporal mínima
  static const double minSpeedWindowMeters = 12.0; // finestra espacial mínima
}
