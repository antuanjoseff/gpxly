// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Registra';

  @override
  String get stopRecording => 'Ferma registrazione';

  @override
  String get gpsDisabled => 'Il GPS è disattivato';

  @override
  String get locationPermissionRequired => 'È necessario concedere l\'autorizzazione alla posizione';

  @override
  String get exitWarning => 'Premi di nuovo indietro per uscire';

  @override
  String get longPressToFinish => 'Tieni premuto per terminare la registrazione';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get close => 'CHIUDI';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Impostazioni';

  @override
  String get recoverTrackTitle => 'Percorso in sospeso';

  @override
  String get recoverTrackMessage => 'È stata rilevata una registrazione che non è stata chiusa correttamente. Vuoi riprenderla o iniziarne una nuova?';

  @override
  String get discard => 'ELIMINA';

  @override
  String get recover => 'RECUPERA';

  @override
  String get exportTitle => 'Esporta GPX';

  @override
  String get exportMessage => 'Vuoi esportare la traccia adesso?';

  @override
  String get export => 'ESPORTA';

  @override
  String get importGpxTitle => 'Importa GPX';

  @override
  String get importGpxMessage => 'È già presente un percorso attivo o ci sono dati caricati. Vuoi sostituirli con il file GPX?';

  @override
  String get import => 'IMPORTA';

  @override
  String get viewModeTitle => 'Modalità visualizzazione';

  @override
  String get viewModeMessage => 'Vuoi entrare in modalità visualizzazione? Non verranno aggiunti nuovi punti e la registrazione verrà disattivata.';

  @override
  String get no => 'NO';

  @override
  String get activate => 'ATTIVA';

  @override
  String get permissionNeededTitle => 'Autorizzazione necessaria';

  @override
  String get permissionNeededMessage => 'Per registrare correttamente il percorso a schermo spento, devi selezionare: 👉 \"Consenti sempre\".';

  @override
  String get continueLabel => 'CONTINUA';

  @override
  String get locationPermissionTitle => 'Autorizzazione alla posizione';

  @override
  String get locationPermissionMessage => 'L\'app non dispone dell\'autorizzazione per accedere alla tua posizione. Vuoi aprire le impostazioni per concederla?';

  @override
  String get offTrack => 'Ti stai allontanando dal percorso';

  @override
  String get backOnTrack => 'Sei sulla traccia';

  @override
  String get elevationFixing => 'Correzione delle altitudini';

  @override
  String get error => 'Errore';

  @override
  String get gpsRecordByTime => 'Registrazione per tempo';

  @override
  String get gpsRecordByDistance => 'Registrazione per distanza';

  @override
  String get gpsMaxAccuracy => 'Precisione massima';

  @override
  String get gpsRecordingMethod => 'Metodo di registrazione';

  @override
  String get gpsSignalQuality => 'Qualità del segnale';

  @override
  String get gpsDiagnosticMode => 'Modalità diagnostica GPS';

  @override
  String get gpsDiagnosticDescription => 'Registra telemetria dettagliata. Può aumentare il consumo della batteria.';

  @override
  String get gpxIncludeExtraData => 'Includi dati aggiuntivi nel file GPX';

  @override
  String get gpxAccuracyPerPoint => 'Precisione per punto';

  @override
  String get gpxSpeed => 'Velocità';

  @override
  String get gpxHeading => 'Direzione';

  @override
  String get gpxSatellites => 'Satelliti';

  @override
  String get gpxVerticalAccuracy => 'Precisione verticale';

  @override
  String get gpxSelectAll => 'Seleziona tutto';

  @override
  String get gpxDeselectAll => 'Deseleziona tutto';

  @override
  String get switchOn => 'ATTIVO';

  @override
  String get switchOff => 'DISATTIVO';

  @override
  String get trackColor => 'Colore della traccia';

  @override
  String get changeTrackColor => 'CAMBIA COLORE DELLA TRACCIA';

  @override
  String get trackWidth => 'Spessore della traccia';

  @override
  String get trackPreview => 'Anteprima della traccia:';

  @override
  String get pickColor => 'Scegli un colore';

  @override
  String get trackStatsTitle => 'Dati del percorso';

  @override
  String get statTime => 'Tempo totale';

  @override
  String get statDistance => 'Distanza totale';

  @override
  String get statSpeed => 'Velocità attuale';

  @override
  String get statMaxElevation => 'Altitudine massima';

  @override
  String get statMinElevation => 'Altitudine minima';

  @override
  String get statAscent => 'Dislivello positivo cumulato';

  @override
  String get statDescent => 'Dislivello negativo cumulato';

  @override
  String get elevationProfile => 'Profilo altimetrico';

  @override
  String get noData => 'Nessun dato';

  @override
  String get recordingTrack => 'Traccia';

  @override
  String get importedTrack => 'Percorso';

  @override
  String get resume => 'RIPRENDI';

  @override
  String get stopFollowing => 'FERMA';

  @override
  String get follow => 'SEGUI PERCORSO';

  @override
  String get pause => 'PAUSA';

  @override
  String get apply => 'APPLICA';

  @override
  String get pendingChangesTitle => 'Modifiche in sospeso';

  @override
  String get pendingChangesMessage => 'Hai apportato modifiche che non sono state applicate. Vuoi applicarle prima di tornare alla mappa?';

  @override
  String get settingsApplied => 'Impostazioni applicate!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Traccia';

  @override
  String get applyUpper => 'APPLICA';

  @override
  String get endOfTrack => 'Hai raggiunto la fine della traccia';

  @override
  String get reverseTrackTitle => 'Direzione inversa';

  @override
  String get reverseTrackMessage => 'Sembra che tu stia seguendo la traccia nella direzione opposta. Vuoi invertirla per migliorare la navigazione?';

  @override
  String get reverseTrackConfirm => 'Sì, inverti';

  @override
  String get ignoreTrackReverse => 'Continua';

  @override
  String get gpxFilenameTitle => 'Nome del file GPX';

  @override
  String get gpxFilenameLabel => 'Nome del file';

  @override
  String get gpxFilenameHint => 'Inserisci il nome del file';

  @override
  String get recording => 'Registrazione...';

  @override
  String get paused => 'IN PAUSA';

  @override
  String get following => 'SEGUIMENTO';

  @override
  String get followPaused => 'PERCORSO IN PAUSA';

  @override
  String get track => 'Percorso';

  @override
  String get followShort => 'Segui';

  @override
  String get followingTitle => 'SEGUIMENTO';

  @override
  String get recordingTitle => 'REGISTRAZIONE';

  @override
  String get pauseShort => 'Pausa';

  @override
  String get stopShort => 'Ferma';

  @override
  String get stopFollowingTitle => 'Ferma il seguimento';

  @override
  String get stopFollowingMessage => 'Vuoi fermare il seguimento? Il percorso verrà rimosso dalla mappa.';

  @override
  String get stopFollowingConfirm => 'FERMA SEGUIMENTO';

  @override
  String get waypointNameTitle => 'Nome del waypoint';

  @override
  String get waypointNameHint => 'Inserisci un nome';

  @override
  String get finishRecordingTitle => 'Termina registrazione';

  @override
  String get finishRecordingMessage => 'Cosa vuoi fare con la registrazione attuale?';

  @override
  String get finishRecordingConfirm => 'TERMINA';

  @override
  String get shareTrack => 'CONDIVIDI';

  @override
  String get continueRecording => 'Continua a registrare';

  @override
  String get deleteTrackTitle => 'Elimina traccia';

  @override
  String get deleteTrackMessage => 'Sei sicuro di voler eliminare questo percorso? Questa azione non può essere annullata.';

  @override
  String get deleteTrackConfirm => 'ELIMINA';

  @override
  String get waypointDetailsTitle => 'Dettagli del waypoint';

  @override
  String get waypointName => 'Nome';

  @override
  String get waypointAltitude => 'Altitudine';

  @override
  String get waypointTrackPoint => 'Punto del percorso';

  @override
  String get waypointDistance => 'Distanza cumulativa';

  @override
  String get waypointTime => 'Tempo di passaggio';

  @override
  String get gpsOptimizationTitle => 'Ottimizzazione GPS';

  @override
  String get gpsOptimizationMessage => 'Per un seguimento preciso, è necessario attivare la modalità ad alta precisione. Ciò può aumentare il consumo della batteria.';

  @override
  String get batteryOptimizationTitle => 'Evita che Android interrompa il GPS';

  @override
  String get batteryOptimizationMessage => 'Per registrare senza interruzioni, soprattutto nelle soste lunghe, Senda deve essere esclusa dall\'ottimizzazione della batteria. Altrimenti Android potrebbe fermare il GPS quando lo schermo è spento per un po\'.';

  @override
  String get confirm => 'CONFERMA';

  @override
  String get notificationPermissionTitle => 'Notifiche del seguimento';

  @override
  String get notificationPermissionMessage => 'Senda deve mostrare una notifica durante la registrazione del percorso. Questo impedisce al sistema di arrestare l\'app per risparmiare batteria e garantisce che la tua traccia non venga persa.';

  @override
  String get understood => 'HO CAPITO';

  @override
  String get gpxErrorInvalidExtension => 'Il file selezionato non è un file GPX';

  @override
  String get gpxErrorRead => 'Impossibile leggere il file GPX';

  @override
  String get gpxErrorInvalidXml => 'Il file non sembra essere un file XML GPX valido';

  @override
  String get gpxErrorNoGpxTag => 'Il file non contiene dati GPX';

  @override
  String get alarms => 'Allarmi';

  @override
  String get alarmsDistanceTitle => 'Distanza';

  @override
  String get alarmsDistanceLabel => 'Metri percorsi';

  @override
  String get alarmsAltitudeTitle => 'Altitudine';

  @override
  String get alarmsAltitudeLabel => 'Metri di dislivello (+/-)';

  @override
  String get alarmsTimeTitle => 'Tempo';

  @override
  String get alarmsTimeLabel => 'Secondi';

  @override
  String get alarmsAccSegmentLabel => 'Dislivello';

  @override
  String get alarmsCotaSegmentLabel => 'Quote';

  @override
  String alarmsCotaValue(int meters) {
    return 'Quota $meters m';
  }

  @override
  String get gpsAutoConfigInfo => 'Quando segui una traccia o attivi l\'allarme di distanza, il GPS si configura automaticamente per migliorare la precisione.';

  @override
  String get gpsLockedMessage => 'Configurazione bloccata: seguimento o allarme attivo';

  @override
  String get reasonAlarm => 'Allarme attivo';

  @override
  String get reasonTrack => 'Seguimento in corso';

  @override
  String get barometerTitle => 'Barometro';

  @override
  String get fusedAltitude => 'Altitudine corretta';

  @override
  String get manualCalibration => 'Calibrazione manuale';

  @override
  String get recalibrateGpsDem => 'Ricalibra con GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Precisione GPS attuale';

  @override
  String get insufficientCoverage => 'Copertura insufficiente per una calibrazione corretta.';

  @override
  String get waitingValidAltitude => 'In attesa di un segnale di altitudine valido...';

  @override
  String get barometerCalibratedSuccess => 'Barometro calibrato con successo';

  @override
  String get autoCalibrationInterval => 'Intervallo di calibrazione automatica';

  @override
  String get howOften => 'Ogni quanto?';

  @override
  String get barometerExplanation => 'Il barometro verrà ricalibrato automaticamente ogni volta che trascorrerà questo intervallo, purché la copertura GPS sia buona.';

  @override
  String get statDetailRecordingData => 'Dati della registrazione';

  @override
  String get statDetailRealTrackSubtitle => 'Traccia in tempo reale';

  @override
  String get statDetailReferenceData => 'Dati di riferimento';

  @override
  String get statDetailImportedTrackSubtitle => 'Percorso';

  @override
  String get statDetailBackButton => 'TORNA ALLE STATISTICHE';

  @override
  String statDetailChartTitle(Object label) {
    return 'PROFILO DI $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PROFILO DI $label';
  }

  @override
  String get waypointsRecorded => 'Waypoint della traccia';

  @override
  String get waypointsImported => 'Waypoint del percorso';

  @override
  String get noRecordedTrack => 'Nessuna traccia disponibile';

  @override
  String get usingImportedTrack => 'Visualizzazione del percorso importato';

  @override
  String get statTimeTotal => 'Tempo totale';

  @override
  String get statTimeMoving => 'Tempo in movimento';

  @override
  String get statTimeStopped => 'Tempo da fermo';

  @override
  String get statTimeToWaypoint => 'Tempo al prossimo waypoint';

  @override
  String get statSpeedCurrent => 'Velocità attuale';

  @override
  String get statSpeedAverage => 'Velocità media';

  @override
  String get statSpeedTotal => 'Velocità media totale';

  @override
  String get statElevation => 'Altitudine';

  @override
  String get statElevationCurrent => 'Altitudine attuale';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Direzione';

  @override
  String get statSatellites => 'Satelliti';

  @override
  String get statAccuracy => 'Precisione';

  @override
  String get satelliteSkyplotTitle => 'Mappa del cielo';

  @override
  String get satelliteFlagsMode => 'Indicatori';

  @override
  String get satelliteGeometryMode => 'Geometrie';

  @override
  String get satelliteSearching => 'Ricerca satelliti... Assicurati che il GPS sia attivo e di trovarti all\'aperto.';

  @override
  String get satelliteNoVisible => 'Nessun satellite visibile';

  @override
  String get satelliteUtcTime => 'Ora UTC';

  @override
  String get satelliteFixType => 'Tipo di fix';

  @override
  String get satelliteFix3dRtk => 'Fix 3D/RTK';

  @override
  String get satelliteNoFix => 'Nessun fix';

  @override
  String get satelliteSatellitesInView => 'Satelliti visibili';

  @override
  String get satelliteSatellitesInUse => 'Satelliti utilizzati';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Elimina waypoint';

  @override
  String get deleteWaypointTitle => 'Eliminare il waypoint?';

  @override
  String get deleteWaypointMessage => 'Sei sicuro di voler eliminare definitivamente questo punto di interesse?';

  @override
  String get deleteConfirm => 'ELIMINA';

  @override
  String get waypointDeletedSuccess => 'Waypoint eliminato correttamente';

  @override
  String get statSpeedMax => 'Velocità massima';

  @override
  String get statPaceAverage => 'Passo medio';

  @override
  String get statPace => 'Passo';

  @override
  String get statBarometerPressure => 'Pressione atmosferica';

  @override
  String get statRangeSelectedTitle => 'Intervallo selezionato';

  @override
  String get statRangeDistance => 'Distanza';

  @override
  String get statRangeAscent => 'Dislivello +';

  @override
  String get statRangeDescent => 'Dislivello -';

  @override
  String get statRangeTime => 'Tempo del tratto';

  @override
  String get statPositionDecimal => 'Posizione decimale';

  @override
  String get statPositionDMS => 'Posizione DMS';

  @override
  String get demManagerTitle => 'Gestore delle celle DEM';

  @override
  String get demManagerDesc => 'Strack Rec scarica automaticamente l\'altitudine quando è disponibile la copertura. Avvicinati alla mappa per salvare manualmente fino a 8 zone da 0,2° da utilizzare offline.';

  @override
  String get demCellDownloaded => 'Cella scaricata localmente';

  @override
  String get demCellAvailable => 'Cella disponibile per il download';

  @override
  String get demDeleteConfirm => 'Vuoi eliminare questa cella dal disco?';

  @override
  String get demLimitReached => 'Limite raggiunto. Elimina una vecchia cella per scaricarne una nuova.';

  @override
  String get record => 'Registra';

  @override
  String get recordPaused => 'In pausa';

  @override
  String get recordStart => 'Avvia registrazione';

  @override
  String get recordPause => 'Metti in pausa';

  @override
  String get recordResume => 'Riprendi';

  @override
  String get recordStop => 'Termina';

  @override
  String get navigationLoadTrack => 'Carica traccia';

  @override
  String get navigationFollow => 'Segui';

  @override
  String get navigationFollowing => 'Seguimento...';

  @override
  String get navigationPaused => 'In pausa';

  @override
  String get navigationStart => 'Avvia';

  @override
  String get navigationCancel => 'Annulla';

  @override
  String get navigationStop => 'Termina';

  @override
  String get menuProfile => 'Profilo';

  @override
  String get menuSettings => 'Impostazioni';

  @override
  String get submenuImportGpx => 'Importa GPX';

  @override
  String get submenuCancel => 'Annulla';

  @override
  String get submenuStop => 'Termina';

  @override
  String get submenuPause => 'Metti in pausa';

  @override
  String get submenuResume => 'Riprendi';

  @override
  String get submenuFollowingPause => 'Metti in pausa';

  @override
  String get submenuFollowingResume => 'Riprendi';

  @override
  String get submenuFollowingStop => 'Termina';

  @override
  String get gpsDisabledAppBar => 'SENZA GPS';

  @override
  String get recoverTrackDialogBody => 'Sono stati rilevati dati di un percorso precedente non salvato. Vuoi recuperarli o preferisci iniziare da zero con un nuovo percorso?';

  @override
  String get waypointNoGps => 'In attesa del segnale GPS...';

  @override
  String get gpsSearching => 'Ricerca...';

  @override
  String get fixStart => 'Punto di partenza';

  @override
  String get fixEnd => 'Punto di arrivo';

  @override
  String get deleteCurrentTrackTitle => 'Eliminare i dati?';

  @override
  String get deleteCurrentTrackMessage => 'Vuoi eliminare i dati attuali della traccia?';

  @override
  String get deleteCurrentTrackKeep => 'MANTIENI';
}
