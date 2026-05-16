# senda

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

CONTINUACIÓ DEL PROJECTE SENDA — DEBUG TEMPS EN PAUSA

Estem arreglant el problema on, en pausar la gravació, stats_screen.dart mostra 00:00:00 encara que el track porta temps gravant.

Ja hem revisat:

    stats_screen.dart → correcte

    Track → correcte

    TrackNotifier → necessita integrar-se amb el nou TimerNotifier

    TimerNotifier → ja tenim la versió nova amb base + elapsed

Pendent per revisar demà:

    Verificar que TrackNotifier.startRecording(), .pauseRecording(), .resumeRecording() i .stopRecording() criden correctament el nou TimerNotifier.

    Confirmar que Track.duration s’actualitza en pausa i no només en stop.

    Reproduir el bug i traçar quin valor arriba a real.duration en pausa.

Objectiu: aconseguir que stats_screen mostri el temps acumulat real quan la gravació està en pausa.
