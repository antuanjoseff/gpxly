# Càlcul del desnivell acumulat

Aquest document descriu com es calcula i es mostra el desnivell positiu
(pujada) i negatiu (baixada) a l'aplicació.

## Gravació i seguiment en directe

Durant una gravació o un seguiment en directe, cada lectura nova d'altitud
passa per `IncrementalElevationGain`:

1. Es calcula la mitjana de les últimes 10 lectures d'altitud. Al principi,
   mentre encara no hi ha 10 lectures, es fa la mitjana de les que hi ha.
   Aquesta mitjana redueix les petites oscil·lacions del GPS.
2. La mitjana actual es compara amb l'última altitud suavitzada que s'ha
   acceptat.
3. Si la diferència és inferior a 4 metres, no es compta i es manté l'altitud
   de referència. Els canvis petits, doncs, poden anar-se acumulant respecte
   d'aquesta referència.
4. Quan la diferència arriba a 4 metres o més, s'afegeix a la pujada si és
   positiva, o a la baixada si és negativa. L'altitud actual es converteix en
   la nova referència.

El llindar de 4 metres s'aplica a la diferència acumulada des de l'última
referència acceptada, no a cada lectura per separat. Per exemple, si les
altituds **ja suavitzades** són 100, 101, 102, 103 i 104 metres, al darrer
valor es compten 4 metres de pujada. Si després baixen fins a 100 metres, es
compten 4 metres de baixada. En canvi, una pujada de 3 metres seguida d'una
baixada de 3 metres no arriba al llindar en cap direcció i no suma ni pujada
ni baixada.

La pujada i la baixada s'acumulen per separat: una baixada no resta metres de
la pujada. Com que s'ignoren els canvis que no arriben al llindar, els totals
no sempre seran exactament iguals, encara que el recorregut acabi a una
altitud semblant a la inicial.

Quan s'atura la gravació, es conserven els totals acumulats fins aquell
moment. Si es recupera una gravació desada temporalment, l'acumulador es
reconstrueix recorrent les altituds dels punts desats.

## Tracks importats

En importar un GPX s'utilitza un càlcul complet sobre tots els punts:

1. Les altituds es suavitzen amb una finestra de 80 metres, fent la mitjana
   dels punts que queden dins d'aquesta distància.
2. S'aplica el mateix llindar de 4 metres per sumar les pujades i les
   baixades.

Per tant, les xifres d'un track gravat en directe i les del mateix track
reimportat poden diferir lleugerament: el càlcul en directe suavitza les
últimes 10 lectures, mentre que la importació suavitza per distància.

## Altitud actual i desnivell acumulat

L'altitud actual és l'altitud de l'últim punt rebut. No és la mateixa dada que
el desnivell acumulat: aquest darrer només canvia quan la diferència amb
l'altitud de referència, després de suavitzar-la, arriba als 4 metres.

## Fitxers implicats

- [`lib/utils/calculations.dart`](lib/utils/calculations.dart): conté
  `IncrementalElevationGain`, utilitzat en directe, i `ElevationUtils`, que
  suavitza i calcula el desnivell de llistes completes d'altituds.
- [`lib/notifiers/helpers/thresholds.dart`](lib/notifiers/helpers/thresholds.dart):
  defineix els valors del càlcul d'importació, incloent la finestra de 80
  metres i el llindar de 4 metres.
- [`lib/notifiers/recording_notifier.dart`](lib/notifiers/recording_notifier.dart):
  envia cada altitud rebuda a l'acumulador durant la gravació, posa els totals
  a les estadístiques del track i reconstrueix l'acumulador quan recupera una
  gravació.
- [`lib/notifiers/live_follow_stats_notifier.dart`](lib/notifiers/live_follow_stats_notifier.dart):
  fa el mateix càlcul incremental quan se segueix un track sense gravar.
- [`lib/services/gpx_import_service.dart`](lib/services/gpx_import_service.dart):
  calcula pujada i baixada quan s'importa un GPX.
- [`lib/models/track.dart`](lib/models/track.dart): guarda les estadístiques
  del track, incloent-hi pujada i baixada.
- [`lib/screens/stats/stats_screen.dart`](lib/screens/stats/stats_screen.dart):
  tria quines estadístiques mostrar i presenta la pujada i la baixada; no les
  calcula directament.
- [`test/incremental_elevation_gain_test.dart`](test/incremental_elevation_gain_test.dart):
  comprova que l'acumulador compta pujades i baixades, ignora soroll petit i
  es reinicia correctament.
