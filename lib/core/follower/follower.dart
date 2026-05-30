import 'package:flutter_riverpod/flutter_riverpod.dart';

class FollowerState {
  final bool isFollowing;
  final int currentIndex;
  final double deviation;
  final double remainingDistance;

  const FollowerState({
    this.isFollowing = false,
    this.currentIndex = 0,
    this.deviation = 0.0,
    this.remainingDistance = 0.0,
  });

  FollowerState copyWith({
    bool? isFollowing,
    int? currentIndex,
    double? deviation,
    double? remainingDistance,
  }) {
    return FollowerState(
      isFollowing: isFollowing ?? this.isFollowing,
      currentIndex: currentIndex ?? this.currentIndex,
      deviation: deviation ?? this.deviation,
      remainingDistance: remainingDistance ?? this.remainingDistance,
    );
  }
}

final followerProvider = NotifierProvider<Follower, FollowerState>(
  Follower.new,
);

class Follower extends Notifier<FollowerState> {
  @override
  FollowerState build() => const FollowerState();

  void start() {
    state = state.copyWith(isFollowing: true);
  }

  void stop() {
    state = state.copyWith(isFollowing: false);
  }

  void updateIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void updateDeviation(double value) {
    state = state.copyWith(deviation: value);
  }

  void updateRemainingDistance(double value) {
    state = state.copyWith(remainingDistance: value);
  }

  void reset() {
    state = const FollowerState();
  }
}
