import '../track_follow_notifier.dart';
import 'thresholds.dart';

class OffTrackLogic {
  bool canSendOffTrackAlert(
    int offTrackAlertsSent,
    int maxOffTrackAlerts,
    DateTime? lastOffTrackAlert,
    Duration cooldown,
  ) {
    if (offTrackAlertsSent >= maxOffTrackAlerts) return false;

    final now = DateTime.now();
    return lastOffTrackAlert == null ||
        now.difference(lastOffTrackAlert) > cooldown;
  }

  bool isTrendingAway(List<double> d) {
    final n = d.length;

    // Necessitem almenys el nivell 2
    if (n < TrackThresholds.minPositionsLevel2) return false;

    // 1. Increment total
    final totalIncrease = d.last - d.first;

    // Si no hi ha increment real → no trending
    if (totalIncrease < 3) return false; // 3m de marge contra soroll

    // 2. Comptem quants punts empitjoren
    int worse = 0;
    for (int i = 1; i < n; i++) {
      if (d[i] > d[i - 1]) worse++;
    }

    // 3. Percentatge de punts que empitjoren
    final ratio = worse / (n - 1);

    // 4. Condició final
    return ratio >= 0.6; // 60% dels punts empitjoren
  }
}
