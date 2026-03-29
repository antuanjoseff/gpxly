import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

final stepCountProvider = NotifierProvider<StepCounterNotifier, int>(
  StepCounterNotifier.new,
);

class StepCounterNotifier extends Notifier<int> {
  @override
  int build() {
    _initPedometer();
    return 0;
  }

  void _initPedometer() {
    Pedometer.stepCountStream.listen(
      (event) {
        state = event.steps;
      },
      onError: (error) {
        print("Error pedometer: $error");
      },
    );
  }
}
