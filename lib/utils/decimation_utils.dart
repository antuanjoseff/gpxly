List<T> decimateList<T>(List<T> list, int targetCount) {
  if (list.length <= targetCount) return list;
  final step = list.length / targetCount;
  return List.generate(targetCount, (i) => list[(i * step).round()]);
}
