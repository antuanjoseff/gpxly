class BarometerService {
  // Stream buit perquè encara no tenim plugin funcional
  Stream<double> get pressureStream => const Stream.empty();

  // Mètodes buits perquè el provider els crida
  Future<void> start() async {}

  void dispose() {}
}
