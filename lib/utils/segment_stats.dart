Map<String, double> segmentStats(
  List<double> distances,
  List<double> altitudes,
  int start,
  int end,
) {
  if (distances.isEmpty || altitudes.isEmpty) {
    return {"distance": 0, "minAlt": 0, "maxAlt": 0, "ascent": 0, "descent": 0};
  }

  final segmentDistance = distances[end] - distances[start];
  final segmentAlts = altitudes.sublist(start, end + 1);

  final minAlt = segmentAlts.reduce((a, b) => a < b ? a : b);
  final maxAlt = segmentAlts.reduce((a, b) => a > b ? a : b);

  double ascent = 0;
  double descent = 0;
  for (int i = 1; i < segmentAlts.length; i++) {
    final diff = segmentAlts[i] - segmentAlts[i - 1];
    if (diff > 0) ascent += diff;
    if (diff < 0) descent -= diff;
  }

  return {
    "distance": segmentDistance,
    "minAlt": minAlt,
    "maxAlt": maxAlt,
    "ascent": ascent,
    "descent": descent,
  };
}
