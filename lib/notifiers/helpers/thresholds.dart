class TrackThresholds {
  static const double nearThreshold = 10;
  static const double nearReverseThreshold = 20;
  static const double farThreshold = 35;
  static const int trendWindow = 6;
  static const Duration offTrackDelay = Duration(seconds: 20);

  // GPS hardware
  static const int navGpsSeconds = 2;
  static const double navGpsMeters = 2.0;
  static const double navGpsAccuracy = 20.0;

  // Reverse detection
  static const double reverseBackwardTriggerMeters = 40;
  static const double reverseDeltaEpsilonMeters = 1.5;
  static const double reverseMaxAlongTrackJumpBaseMeters = 30;
  static const double reverseMaxAlongTrackJumpPerGpsMeter = 2.5;
  static const int reverseMaxSegmentJumpWhenSlow = 60;
  static const double reverseSlowStepMeters = 8;
  static const double reverseMinDistance = 50;
  static const double reverseRecentMovementDistance = 20;
  static const int reverseSegmentWindow = 20;
  static const int reverseMinNegativeSteps = 6;
  static const int reverseMinDeltaSum = 4;

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
  static const double waypointAlarmDistanceMeters = 30.0;

  // Nou llindar per detectar aturades
  static const double stopSpeedThreshold = 0.5; // m/s

  // Gràfic d'elevacions
  static const double futureTrackVisibility = 0.3; // 30% of axis

  // Submenús del menú inferior
  static const Duration submenuAutoHideDelay = Duration(seconds: 4);

  // LÍMIT MÀXIM D'ARXIUS COG PERSISTENTS A DISC
  static const int maxPersistentFiles = 10;

  // Velocitat estable
  static const int sustainedSpeedWindowSeconds =
      8; // finestra temporal de velocitat sostinguda
  static const int minSpeedWindowSeconds =
      sustainedSpeedWindowSeconds; // compatibilitat amb codi existent
  static const double minSpeedWindowMeters = 12.0; // finestra espacial mínima

  // Velocitat corregida per punt: mitjana mòbil de 5 punts vàlids
  static const int speedSmoothingWindow = 5;
  static const double speedMinAccuracyMeters = 5.0;
  static const double speedEstablishedMinAccuracyMeters = 10.0;

  // Rebuig de salts GPS puntuals: acceleració física màxima plausible (km/h per segon)
  static const double speedMaxAccelerationKmhPerSecond = 10.8;
}
