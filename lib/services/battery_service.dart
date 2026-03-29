import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

Future<void> requestBatteryExclusion() async {
  final intent = AndroidIntent(
    action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
  );
  await intent.launch();
}
