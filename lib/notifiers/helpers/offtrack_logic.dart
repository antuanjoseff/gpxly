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

  bool isTrendingAway(List<double> lastDistances) {
    if (lastDistances.length < TrackThresholds.trendWindow) return false;

    int increases = 0;

    for (int i = 1; i < lastDistances.length; i++) {
      if (lastDistances[i] > lastDistances[i - 1]) {
        increases++;
      }
    }

    return increases >= TrackThresholds.trendWindow - 2;
  }
}
