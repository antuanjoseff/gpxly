// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Aufzeichnen';

  @override
  String get stopRecording => 'Aufzeichnung stoppen';

  @override
  String get gpsDisabled => 'GPS ist deaktiviert';

  @override
  String get locationPermissionRequired => 'Standortberechtigung erforderlich';

  @override
  String get exitWarning => 'Drücke erneut Zurück, um die App zu verlassen';

  @override
  String get exitWhileRecording => 'Beende zuerst die Aufzeichnung, bevor du die App verlässt';

  @override
  String get exitWhileFollowing => 'Beende zuerst die Navigation, bevor du die App verlässt';

  @override
  String get exitWhileRecordingAndFollowing => 'Beende zuerst die Aufzeichnung und die Navigation, bevor du die App verlässt';

  @override
  String get longPressToFinish => 'Gedrückt halten, um die Aufzeichnung zu beenden';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get close => 'SCHLIESSEN';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Einstellungen';

  @override
  String get recoverTrackTitle => 'Ausstehende Route';

  @override
  String get recoverTrackMessage => 'Es wurde eine Aufzeichnung erkannt, die nicht ordnungsgemäß beendet wurde. Möchtest du sie fortsetzen oder eine neue starten?';

  @override
  String get discard => 'VERWERFEN';

  @override
  String get recover => 'WIEDERHERSTELLEN';

  @override
  String get exportTitle => 'GPX exportieren';

  @override
  String get exportMessage => 'Möchtest du den Track jetzt exportieren?';

  @override
  String get export => 'EXPORTIEREN';

  @override
  String get importGpxTitle => 'GPX importieren';

  @override
  String get importGpxMessage => 'Du hast bereits eine aktive Route oder geladene Daten. Möchtest du sie durch die GPX-Datei ersetzen?';

  @override
  String get import => 'IMPORTIEREN';

  @override
  String get viewModeTitle => 'Anzeigemodus';

  @override
  String get viewModeMessage => 'Möchtest du in den Anzeigemodus wechseln? Es werden keine neuen Punkte hinzugefügt und die Aufzeichnung wird deaktiviert.';

  @override
  String get no => 'NEIN';

  @override
  String get activate => 'AKTIVIEREN';

  @override
  String get permissionNeededTitle => 'Berechtigung erforderlich';

  @override
  String get continueLabel => 'WEITER';

  @override
  String get locationPermissionTitle => 'Standortberechtigung';

  @override
  String get locationPermissionMessage => 'Die App hat keine Berechtigung, auf deinen Standort zuzugreifen. Möchtest du die Einstellungen öffnen, um die Berechtigung zu erteilen?';

  @override
  String get offTrack => 'Du entfernst dich von der Route';

  @override
  String get backOnTrack => 'Du bist wieder auf dem Track';

  @override
  String get elevationFixing => 'Höhen werden korrigiert';

  @override
  String get error => 'Fehler';

  @override
  String get gpsRecordByTime => 'Aufzeichnung nach Zeit';

  @override
  String get gpsRecordByDistance => 'Aufzeichnung nach Entfernung';

  @override
  String get gpsMaxAccuracy => 'Maximale Genauigkeit';

  @override
  String get gpsRecordingMethod => 'Aufzeichnungsmethode';

  @override
  String get gpsSignalQuality => 'Signalqualität';

  @override
  String get gpsDiagnosticMode => 'GPS-Diagnosemodus';

  @override
  String get gpsDiagnosticDescription => 'Zeichnet detaillierte Telemetriedaten auf. Dies kann den Akkuverbrauch erhöhen.';

  @override
  String get gpxIncludeExtraData => 'Zusätzliche Daten in die GPX-Datei aufnehmen';

  @override
  String get gpxAccuracyPerPoint => 'Genauigkeit pro Punkt';

  @override
  String get gpxSpeed => 'Geschwindigkeit';

  @override
  String get gpxHeading => 'Kurs';

  @override
  String get gpxSatellites => 'Satelliten';

  @override
  String get gpxVerticalAccuracy => 'Vertikale Genauigkeit';

  @override
  String get gpxSelectAll => 'Alles auswählen';

  @override
  String get gpxDeselectAll => 'Alles abwählen';

  @override
  String get gpxSaveTrack => 'Track jetzt speichern';

  @override
  String get gpxTrackSaved => 'Track gespeichert';

  @override
  String get switchOn => 'EIN';

  @override
  String get switchOff => 'AUS';

  @override
  String get trackColor => 'Track-Farbe';

  @override
  String get changeTrackColor => 'TRACK-FARBE ÄNDERN';

  @override
  String get trackWidth => 'Track-Breite';

  @override
  String get trackPreview => 'Vorschau des Tracks:';

  @override
  String get pickColor => 'Farbe auswählen';

  @override
  String get trackStatsTitle => 'Routendaten';

  @override
  String get statTime => 'Gesamtzeit';

  @override
  String get statDistance => 'Gesamtentfernung';

  @override
  String get statSpeed => 'Aktuelle Geschwindigkeit';

  @override
  String get statMaxElevation => 'Maximale Höhe';

  @override
  String get statMinElevation => 'Minimale Höhe';

  @override
  String get statAscent => 'Höhengewinn +';

  @override
  String get statDescent => 'Höhenverlust -';

  @override
  String get mapStatDistance => 'ENTF.';

  @override
  String get mapStatRemaining => 'REST';

  @override
  String get mapStatTime => 'ZEIT';

  @override
  String get mapStatMoving => 'BEW.';

  @override
  String get mapStatStopped => 'STOPP';

  @override
  String get mapStatWaypoint => 'PUNKT';

  @override
  String get mapStatSpeed => 'GES.';

  @override
  String get mapStatSpeedAvg => 'Ø';

  @override
  String get mapStatSpeedTotal => 'GESAMT';

  @override
  String get mapStatSpeedMax => 'MAX.';

  @override
  String get mapStatPace => 'TEMPO';

  @override
  String get mapStatPaceAvg => 'Ø TEMPO';

  @override
  String get mapStatAltitude => 'HÖHE';

  @override
  String get mapStatAltMax => 'MAX. HÖHE';

  @override
  String get mapStatAltMin => 'MIN. HÖHE';

  @override
  String get mapStatAscent => 'AUFSTIEG';

  @override
  String get mapStatDescent => 'ABSTIEG';

  @override
  String get mapStatPosition => 'POS.';

  @override
  String get mapStatPositionDms => 'POS. DMS';

  @override
  String get mapStatPressure => 'DRUCK';

  @override
  String get mapStatGps => 'GPS';

  @override
  String get mapStatGpsAccuracy => 'GPS-GENAUIGKEIT';

  @override
  String get statRemaining => 'Verbleibend';

  @override
  String get elevationProfile => 'Höhenprofil';

  @override
  String get noData => 'Keine Daten';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Route';

  @override
  String get resume => 'FORTSETZEN';

  @override
  String get stopFollowing => 'STOPP';

  @override
  String get follow => 'ROUTE FOLGEN';

  @override
  String get pause => 'PAUSE';

  @override
  String get apply => 'ANWENDEN';

  @override
  String get pendingChangesTitle => 'Ausstehende Änderungen';

  @override
  String get pendingChangesMessage => 'Du hast Änderungen vorgenommen, die noch nicht angewendet wurden. Möchtest du sie anwenden, bevor du zur Karte zurückkehrst?';

  @override
  String get settingsApplied => 'Einstellungen angewendet!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'ANWENDEN';

  @override
  String get endOfTrack => 'Du hast das Ende des Tracks erreicht';

  @override
  String get reverseTrackTitle => 'Umgekehrte Richtung';

  @override
  String get reverseTrackMessage => 'Es scheint, dass du dem Track in umgekehrter Richtung folgst. Möchtest du ihn umkehren, um die Navigation zu verbessern?';

  @override
  String get reverseTrackConfirm => 'Ja, umkehren';

  @override
  String get ignoreTrackReverse => 'Fortfahren';

  @override
  String get gpxFilenameTitle => 'Name der GPX-Datei';

  @override
  String get gpxFilenameLabel => 'Dateiname';

  @override
  String get gpxFilenameHint => 'Dateinamen eingeben';

  @override
  String get recording => 'Aufzeichnung...';

  @override
  String get paused => 'PAUSIERT';

  @override
  String get following => 'FOLGEN';

  @override
  String get followPaused => 'ROUTE PAUSIERT';

  @override
  String get track => 'Route';

  @override
  String get followShort => 'Folgen';

  @override
  String get followingTitle => 'NAVIGATION';

  @override
  String get recordingTitle => 'AUFZEICHNUNG';

  @override
  String get pauseShort => 'Pause';

  @override
  String get stopShort => 'Stopp';

  @override
  String get stopFollowingTitle => 'Navigation stoppen';

  @override
  String get stopFollowingMessage => 'Möchtest du die Navigation stoppen? Die Route wird von der Karte entfernt.';

  @override
  String get stopFollowingConfirm => 'ROUTE STOPPEN';

  @override
  String get waypointNameTitle => 'Name des Wegpunkts';

  @override
  String get waypointNameHint => 'Namen eingeben';

  @override
  String get finishRecordingTitle => 'Aufzeichnung beenden';

  @override
  String get finishRecordingMessage => 'Was möchtest du mit der aktuellen Aufzeichnung machen?';

  @override
  String get finishRecordingConfirm => 'BEENDEN';

  @override
  String get shareTrack => 'TEILEN';

  @override
  String get continueRecording => 'Aufzeichnung fortsetzen';

  @override
  String get deleteTrackTitle => 'Track löschen';

  @override
  String get deleteTrackMessage => 'Möchtest du diese Route wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteTrackConfirm => 'LÖSCHEN';

  @override
  String get waypointDetailsTitle => 'Wegpunktdetails';

  @override
  String get waypointName => 'Name';

  @override
  String get waypointAltitude => 'Höhe';

  @override
  String get waypointTrackPoint => 'Routenpunkt';

  @override
  String get waypointDistance => 'Zurückgelegte Entfernung';

  @override
  String get waypointTime => 'Durchgangszeit';

  @override
  String get gpsOptimizationTitle => 'GPS-Optimierung';

  @override
  String get gpsOptimizationMessage => 'Für eine präzise Navigation muss der Hochpräzisionsmodus aktiviert sein. Dies kann den Akkuverbrauch erhöhen.';

  @override
  String get confirm => 'BESTÄTIGEN';

  @override
  String get notificationPermissionTitle => 'Navigationsbenachrichtigungen';

  @override
  String get understood => 'VERSTANDEN';

  @override
  String get permissionNeededMessage => 'Diese App benötigt die Berechtigung „Immer erlauben“, um während der Ausführung der App Standortdaten erfassen zu können. Dadurch können deine Routen in Echtzeit aufgezeichnet und verfolgt werden, auch wenn die App minimiert ist oder im Hintergrund ausgeführt wird.';

  @override
  String get notificationPermissionMessage => 'Diese App verwendet einen Vordergrunddienst, um eine kontinuierliche GPS-Navigation während der Aufzeichnung deiner Route zu gewährleisten. Es wird eine dauerhafte Benachrichtigung angezeigt, die dich darüber informiert, dass die App aktiv Standortdaten erfasst und verhindert, dass das System deine Tour unterbricht.';

  @override
  String get gpxErrorInvalidExtension => 'Die ausgewählte Datei ist keine GPX-Datei';

  @override
  String get gpxErrorRead => 'Die GPX-Datei konnte nicht gelesen werden';

  @override
  String get gpxErrorInvalidXml => 'Die Datei scheint kein gültiges GPX-XML zu sein';

  @override
  String get gpxErrorNoGpxTag => 'Die Datei enthält keine GPX-Daten';

  @override
  String get alarms => 'Alarme';

  @override
  String get alarmsDistanceTitle => 'Entfernung';

  @override
  String get alarmsDistanceLabel => 'Zurückgelegte Meter';

  @override
  String get alarmsAltitudeTitle => 'Höhe';

  @override
  String get alarmsAltitudeLabel => 'Höhenmeter (+/-)';

  @override
  String get alarmsTimeTitle => 'Zeit';

  @override
  String get alarmsTimeLabel => 'Sekunden';

  @override
  String get alarmsAccSegmentLabel => 'Höhenunterschied';

  @override
  String get alarmsCotaSegmentLabel => 'Höhen';

  @override
  String alarmsCotaValue(int meters) {
    return 'Höhe $meters m';
  }

  @override
  String get alarmsVolume => 'Alarmlautstärke';

  @override
  String get gpsAutoConfigInfo => 'Wenn du einem Track folgst oder den Entfernungsalarm aktivierst, wird das GPS automatisch konfiguriert, um die Genauigkeit zu verbessern.';

  @override
  String get gpsLockedMessage => 'Einstellungen gesperrt: Navigation oder Alarm aktiv';

  @override
  String get reasonAlarm => 'Alarm aktiv';

  @override
  String get reasonTrack => 'Navigation läuft';

  @override
  String get barometerTitle => 'Barometer';

  @override
  String get fusedAltitude => 'Korrigierte Höhe';

  @override
  String get manualCalibration => 'Manuelle Kalibrierung';

  @override
  String get recalibrateGpsDem => 'Mit GPS/DEM neu kalibrieren';

  @override
  String get currentGpsAccuracy => 'Aktuelle GPS-Genauigkeit';

  @override
  String get insufficientCoverage => 'Unzureichende Abdeckung für eine genaue Kalibrierung.';

  @override
  String get waitingValidAltitude => 'Warte auf ein gültiges Höhensignal...';

  @override
  String get barometerCalibratedSuccess => 'Barometer erfolgreich kalibriert';

  @override
  String get autoCalibrationInterval => 'Intervall für automatische Kalibrierung';

  @override
  String get howOften => 'Wie oft?';

  @override
  String get barometerExplanation => 'Das Barometer wird automatisch nach Ablauf dieser Zeit neu kalibriert, sofern die GPS-Abdeckung gut ist.';

  @override
  String get statDetailRecordingData => 'Aufzeichnungsdaten';

  @override
  String get statDetailRealTrackSubtitle => 'Track in Echtzeit';

  @override
  String get statDetailReferenceData => 'Referenzdaten';

  @override
  String get statDetailImportedTrackSubtitle => 'Route';

  @override
  String get statDetailBackButton => 'ZURÜCK ZU DEN STATISTIKEN';

  @override
  String statDetailChartTitle(Object label) {
    return 'PROFIL VON $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PROFIL VON $label';
  }

  @override
  String get waypointsRecorded => 'Wegpunkte des Tracks';

  @override
  String get waypointsImported => 'Wegpunkte der Route';

  @override
  String get noRecordedTrack => 'Kein Track verfügbar';

  @override
  String get usingImportedTrack => 'Importierte Route wird angezeigt';

  @override
  String get statTimeTotal => 'Gesamtzeit';

  @override
  String get statTimeMoving => 'Bewegungszeit';

  @override
  String get statTimeStopped => 'Stillstandszeit';

  @override
  String get statTimeToWaypoint => 'Zeit bis zum Wegpunkt';

  @override
  String get statSpeedCurrent => 'Aktuelle Geschwindigkeit';

  @override
  String get statSpeedAverage => 'Durchschnittsgeschwindigkeit';

  @override
  String get statSpeedTotal => 'Durchschnittliche Gesamtgeschwindigkeit';

  @override
  String get statElevation => 'Höhe';

  @override
  String get statElevationCurrent => 'Aktuelle Höhe';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Kurs';

  @override
  String get statSatellites => 'Satelliten';

  @override
  String get statAccuracy => 'Genauigkeit';

  @override
  String get satelliteSkyplotTitle => 'Himmelskarte';

  @override
  String get satelliteFlagsMode => 'Signale';

  @override
  String get satelliteGeometryMode => 'Geometrien';

  @override
  String get satelliteSearching => 'Suche nach Satelliten... Stelle sicher, dass GPS im Freien aktiviert ist.';

  @override
  String get satelliteNoVisible => 'Keine sichtbaren Satelliten';

  @override
  String get satelliteUtcTime => 'UTC-Zeit';

  @override
  String get satelliteFixType => 'Fix-Typ';

  @override
  String get satelliteFix3dRtk => '3D/RTK-Fix';

  @override
  String get satelliteNoFix => 'Kein Fix';

  @override
  String get satelliteSatellitesInView => 'Satelliten in Sicht';

  @override
  String get satelliteSatellitesInUse => 'Verwendete Satelliten';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Wegpunkt löschen';

  @override
  String get deleteWaypointTitle => 'Wegpunkt löschen?';

  @override
  String get deleteWaypointMessage => 'Möchtest du diesen Interessenpunkt wirklich endgültig löschen?';

  @override
  String get deleteConfirm => 'LÖSCHEN';

  @override
  String get waypointDeletedSuccess => 'Wegpunkt erfolgreich gelöscht';

  @override
  String get statSpeedMax => 'Maximale Geschwindigkeit';

  @override
  String get statPaceAverage => 'Durchschnittliches Tempo';

  @override
  String get statPace => 'Tempo';

  @override
  String get statBarometerPressure => 'Atmosphärischer Druck';

  @override
  String get statRangeSelectedTitle => 'Ausgewählter Bereich';

  @override
  String get statRangeDistance => 'Entfernung';

  @override
  String get statRangeAscent => 'Höhengewinn +';

  @override
  String get statRangeDescent => 'Höhenverlust -';

  @override
  String get statRangeTime => 'Zeit des Abschnitts';

  @override
  String get statPositionDecimal => 'Position Dezimal';

  @override
  String get statPositionDMS => 'Position DMS';

  @override
  String get demManagerTitle => 'DEM-Kachelverwaltung';

  @override
  String get demManagerDesc => 'Strack Rec lädt die Höhe automatisch herunter, wenn eine Internetverbindung verfügbar ist. Zoome auf der Karte hinein, um manuell bis zu 8 Bereiche mit 0,2° zu speichern und offline zu verwenden.';

  @override
  String get demCellDownloaded => 'Kachel lokal heruntergeladen';

  @override
  String get demCellAvailable => 'Kachel zum Herunterladen verfügbar';

  @override
  String get demDeleteConfirm => 'Möchtest du diese Kachel vom Gerät löschen?';

  @override
  String get demLimitReached => 'Limit erreicht. Lösche eine alte Kachel, um eine neue herunterzuladen.';

  @override
  String get offlineTab => 'Offline';

  @override
  String get offlineTapRegion => 'Tap inside the rectangle to download the map of Catalonia for offline use.';

  @override
  String get offlineDownloadTitle => 'Offline map';

  @override
  String get offlineDownloadConfirm => 'Download the map of Catalonia (~200 MB)? We recommend using Wi-Fi.';

  @override
  String get offlineDownloadDone => 'Map downloaded successfully';

  @override
  String get offlineDownloadError => 'Download failed. Please try again.';

  @override
  String get offlineDownloaded => 'Map of Catalonia downloaded';

  @override
  String get offlineUseOffline => 'Use the offline map';

  @override
  String get offlineDelete => 'Delete the downloaded map';

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading...';

  @override
  String get record => 'Aufzeichnen';

  @override
  String get recordPaused => 'Pausiert';

  @override
  String get recordStart => 'Aufzeichnung starten';

  @override
  String get recordPause => 'Pausieren';

  @override
  String get recordResume => 'Fortsetzen';

  @override
  String get recordStop => 'Beenden';

  @override
  String get navigationLoadTrack => 'Track laden';

  @override
  String get navigationFollow => 'Folgen';

  @override
  String get navigationFollowing => 'Folge...';

  @override
  String get navigationPaused => 'Pausiert';

  @override
  String get navigationStart => 'Starten';

  @override
  String get navigationCancel => 'Abbrechen';

  @override
  String get navigationStop => 'Beenden';

  @override
  String get menuProfile => 'Profil';

  @override
  String get menuSettings => 'Einstellungen';

  @override
  String get submenuImportGpx => 'GPX importieren';

  @override
  String get submenuCancel => 'Abbrechen';

  @override
  String get submenuStop => 'Beenden';

  @override
  String get submenuPause => 'Pausieren';

  @override
  String get submenuResume => 'Fortsetzen';

  @override
  String get submenuFollowingPause => 'Pausieren';

  @override
  String get submenuFollowingResume => 'Fortsetzen';

  @override
  String get submenuFollowingStop => 'Beenden';

  @override
  String get gpsDisabledAppBar => 'KEIN GPS';

  @override
  String get recoverTrackDialogBody => 'Es wurden Daten einer zuvor nicht gespeicherten Route gefunden. Möchtest du sie wiederherstellen oder lieber ganz von vorne beginnen?';

  @override
  String get waypointNoGps => 'Warte auf GPS-Signal...';

  @override
  String get waypointDefaultPrefix => 'P';

  @override
  String get gpsSearching => 'Suche...';

  @override
  String get fixStart => 'Startpunkt';

  @override
  String get fixEnd => 'Endpunkt';

  @override
  String get deleteCurrentTrackTitle => 'Daten löschen?';

  @override
  String get deleteCurrentTrackMessage => 'Möchtest du die aktuellen Track-Daten löschen?';

  @override
  String get deleteCurrentTrackKeep => 'BEIBEHALTEN';
}
