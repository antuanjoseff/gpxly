// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Opnemen';

  @override
  String get stopRecording => 'Opname stoppen';

  @override
  String get gpsDisabled => 'GPS is uitgeschakeld';

  @override
  String get locationPermissionRequired => 'Locatietoestemming vereist';

  @override
  String get exitWarning => 'Druk nogmaals op Terug om af te sluiten';

  @override
  String get exitWhileRecording => 'Beëindig eerst de opname voordat je de app verlaat';

  @override
  String get exitWhileFollowing => 'Beëindig eerst de navigatie voordat je de app verlaat';

  @override
  String get exitWhileRecordingAndFollowing => 'Beëindig eerst de opname en de navigatie voordat je de app verlaat';

  @override
  String get longPressToFinish => 'Houd ingedrukt om de opname te beëindigen';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'ANNULEREN';

  @override
  String get close => 'SLUITEN';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Instellingen';

  @override
  String get recoverTrackTitle => 'Openstaande route';

  @override
  String get recoverTrackMessage => 'Er is een opname gevonden die niet correct werd afgesloten. Wil je deze hervatten of een nieuwe starten?';

  @override
  String get discard => 'VERWIJDEREN';

  @override
  String get recover => 'HERSTELLEN';

  @override
  String get exportTitle => 'GPX exporteren';

  @override
  String get exportMessage => 'Wil je de track nu exporteren?';

  @override
  String get export => 'EXPORTEREN';

  @override
  String get importGpxTitle => 'GPX importeren';

  @override
  String get importGpxMessage => 'Je hebt al een actieve route of geladen gegevens. Wil je deze vervangen door het GPX-bestand?';

  @override
  String get import => 'IMPORTEREN';

  @override
  String get viewModeTitle => 'Weergavemodus';

  @override
  String get viewModeMessage => 'Wil je naar de weergavemodus gaan? Er worden geen nieuwe punten toegevoegd en de opname wordt uitgeschakeld.';

  @override
  String get no => 'NEE';

  @override
  String get activate => 'ACTIVEREN';

  @override
  String get permissionNeededTitle => 'Toestemming vereist';

  @override
  String get continueLabel => 'DOORGAAN';

  @override
  String get locationPermissionTitle => 'Locatietoestemming';

  @override
  String get locationPermissionMessage => 'De app heeft geen toestemming om toegang te krijgen tot je locatie. Wil je de instellingen openen om toestemming te geven?';

  @override
  String get offTrack => 'Je wijkt af van de route';

  @override
  String get backOnTrack => 'Je bent weer op de track';

  @override
  String get elevationFixing => 'Hoogtes corrigeren';

  @override
  String get error => 'Fout';

  @override
  String get gpsRecordByTime => 'Opnemen op tijd';

  @override
  String get gpsRecordByDistance => 'Opnemen op afstand';

  @override
  String get gpsMaxAccuracy => 'Maximale nauwkeurigheid';

  @override
  String get gpsRecordingMethod => 'Opnamemethode';

  @override
  String get gpsSignalQuality => 'Signaalkwaliteit';

  @override
  String get gpsDiagnosticMode => 'GPS-diagnosemodus';

  @override
  String get gpsDiagnosticDescription => 'Registreert gedetailleerde telemetrie. Dit kan het batterijverbruik verhogen.';

  @override
  String get gpxIncludeExtraData => 'Extra gegevens opnemen in het GPX-bestand';

  @override
  String get gpxAccuracyPerPoint => 'Nauwkeurigheid per punt';

  @override
  String get gpxSpeed => 'Snelheid';

  @override
  String get gpxHeading => 'Richting';

  @override
  String get gpxSatellites => 'Satellieten';

  @override
  String get gpxVerticalAccuracy => 'Verticale nauwkeurigheid';

  @override
  String get gpxSelectAll => 'Alles selecteren';

  @override
  String get gpxDeselectAll => 'Alles deselecteren';

  @override
  String get gpxSaveTrack => 'Track nu opslaan';

  @override
  String get gpxTrackSaved => 'Track opgeslagen';

  @override
  String get switchOn => 'AAN';

  @override
  String get switchOff => 'UIT';

  @override
  String get trackColor => 'Kleur van de track';

  @override
  String get changeTrackColor => 'KLEUR VAN DE TRACK WIJZIGEN';

  @override
  String get trackWidth => 'Dikte van de track';

  @override
  String get trackPreview => 'Voorbeeld van de track:';

  @override
  String get pickColor => 'Kies een kleur';

  @override
  String get trackStatsTitle => 'Routegegevens';

  @override
  String get statTime => 'Totale tijd';

  @override
  String get statDistance => 'Totale afstand';

  @override
  String get statSpeed => 'Huidige snelheid';

  @override
  String get statMaxElevation => 'Maximale hoogte';

  @override
  String get statMinElevation => 'Minimale hoogte';

  @override
  String get statAscent => 'Totale stijging +';

  @override
  String get statDescent => 'Totale daling -';

  @override
  String get mapStatDistance => 'AFST.';

  @override
  String get mapStatRemaining => 'REST.';

  @override
  String get mapStatTime => 'TIJD';

  @override
  String get mapStatMoving => 'BEW.';

  @override
  String get mapStatStopped => 'STOP';

  @override
  String get mapStatWaypoint => 'PUNT';

  @override
  String get mapStatSpeed => 'SNELH.';

  @override
  String get mapStatSpeedAvg => 'GEM.';

  @override
  String get mapStatSpeedTotal => 'TOTAAL';

  @override
  String get mapStatSpeedMax => 'MAX.';

  @override
  String get mapStatPace => 'TEMPO';

  @override
  String get mapStatPaceAvg => 'GEM. TEMPO';

  @override
  String get mapStatAltitude => 'HOOGTE';

  @override
  String get mapStatAltMax => 'MAX. HOOGTE';

  @override
  String get mapStatAltMin => 'MIN. HOOGTE';

  @override
  String get mapStatAscent => 'STIJGING';

  @override
  String get mapStatDescent => 'DALING';

  @override
  String get mapStatPosition => 'POS.';

  @override
  String get mapStatPositionDms => 'POS. DMS';

  @override
  String get mapStatPressure => 'DRUK';

  @override
  String get mapStatGps => 'GPS';

  @override
  String get mapStatGpsAccuracy => 'GPS-NAUWKEURIGHEID';

  @override
  String get statRemaining => 'Resterend';

  @override
  String get elevationProfile => 'Hoogteprofiel';

  @override
  String get noData => 'Geen gegevens';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Route';

  @override
  String get resume => 'HERVATTEN';

  @override
  String get stopFollowing => 'STOPPEN';

  @override
  String get follow => 'ROUTE VOLGEN';

  @override
  String get pause => 'PAUZE';

  @override
  String get apply => 'TOEPASSEN';

  @override
  String get pendingChangesTitle => 'Niet-toegepaste wijzigingen';

  @override
  String get pendingChangesMessage => 'Je hebt wijzigingen aangebracht die nog niet zijn toegepast. Wil je deze toepassen voordat je teruggaat naar de kaart?';

  @override
  String get settingsApplied => 'Instellingen toegepast!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'TOEPASSEN';

  @override
  String get endOfTrack => 'Je hebt het einde van de track bereikt';

  @override
  String get reverseTrackTitle => 'Omgekeerde richting';

  @override
  String get reverseTrackMessage => 'Het lijkt erop dat je de track in de tegenovergestelde richting volgt. Wil je deze omkeren om de navigatie te verbeteren?';

  @override
  String get reverseTrackConfirm => 'Ja, omkeren';

  @override
  String get ignoreTrackReverse => 'Doorgaan';

  @override
  String get gpxFilenameTitle => 'Naam van het GPX-bestand';

  @override
  String get gpxFilenameLabel => 'Bestandsnaam';

  @override
  String get gpxFilenameHint => 'Voer de bestandsnaam in';

  @override
  String get recording => 'Opnemen...';

  @override
  String get paused => 'GEPAUZEERD';

  @override
  String get following => 'VOLGEN';

  @override
  String get followPaused => 'ROUTE GEPAUZEERD';

  @override
  String get track => 'Route';

  @override
  String get followShort => 'Volgen';

  @override
  String get followingTitle => 'NAVIGATIE';

  @override
  String get recordingTitle => 'OPNAME';

  @override
  String get pauseShort => 'Pauze';

  @override
  String get stopShort => 'Stoppen';

  @override
  String get stopFollowingTitle => 'Navigatie stoppen';

  @override
  String get stopFollowingMessage => 'Wil je de navigatie stoppen? De route wordt van de kaart verwijderd.';

  @override
  String get stopFollowingConfirm => 'ROUTE STOPPEN';

  @override
  String get waypointNameTitle => 'Naam van het waypoint';

  @override
  String get waypointNameHint => 'Voer een naam in';

  @override
  String get finishRecordingTitle => 'Opname beëindigen';

  @override
  String get finishRecordingMessage => 'Wat wil je met de huidige opname doen?';

  @override
  String get finishRecordingConfirm => 'BEËINDIGEN';

  @override
  String get shareTrack => 'DELEN';

  @override
  String get continueRecording => 'Doorgaan met opnemen';

  @override
  String get deleteTrackTitle => 'Track verwijderen';

  @override
  String get deleteTrackMessage => 'Weet je zeker dat je deze route wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get deleteTrackConfirm => 'VERWIJDEREN';

  @override
  String get waypointDetailsTitle => 'Waypointgegevens';

  @override
  String get waypointName => 'Naam';

  @override
  String get waypointAltitude => 'Hoogte';

  @override
  String get waypointTrackPoint => 'Routepunt';

  @override
  String get waypointDistance => 'Totale afgelegde afstand';

  @override
  String get waypointTime => 'Passeertijd';

  @override
  String get gpsOptimizationTitle => 'GPS-optimalisatie';

  @override
  String get gpsOptimizationMessage => 'Voor nauwkeurige navigatie moet de modus voor hoge nauwkeurigheid worden geactiveerd. Dit kan het batterijverbruik verhogen.';

  @override
  String get confirm => 'BEVESTIGEN';

  @override
  String get notificationPermissionTitle => 'Navigatiemeldingen';

  @override
  String get understood => 'BEGREPEN';

  @override
  String get permissionNeededMessage => 'Deze app vereist dat je de optie \'Altijd toestaan\' selecteert om locatiegegevens te kunnen verzamelen terwijl de app actief is. Hierdoor kunnen je routes in realtime worden opgenomen en gevolgd, zelfs wanneer de app is geminimaliseerd of op de achtergrond draait.';

  @override
  String get notificationPermissionMessage => 'Deze app gebruikt een voorgrondservice om continue GPS-navigatie te garanderen tijdens het opnemen van je route. Er wordt een permanente melding weergegeven om je te informeren dat de app actief locatiegegevens verzamelt en om te voorkomen dat het systeem je route onderbreekt.';

  @override
  String get gpxErrorInvalidExtension => 'Het geselecteerde bestand is geen GPX-bestand';

  @override
  String get gpxErrorRead => 'Het GPX-bestand kon niet worden gelezen';

  @override
  String get gpxErrorInvalidXml => 'Het bestand lijkt geen geldige GPX-XML te zijn';

  @override
  String get gpxErrorNoGpxTag => 'Het bestand bevat geen GPX-gegevens';

  @override
  String get alarms => 'Alarmen';

  @override
  String get alarmsDistanceTitle => 'Afstand';

  @override
  String get alarmsDistanceLabel => 'Afgelegde meters';

  @override
  String get alarmsAltitudeTitle => 'Hoogte';

  @override
  String get alarmsAltitudeLabel => 'Hoogtemeters (+/-)';

  @override
  String get alarmsTimeTitle => 'Tijd';

  @override
  String get alarmsTimeLabel => 'Seconden';

  @override
  String get alarmsAccSegmentLabel => 'Hoogteverschil';

  @override
  String get alarmsCotaSegmentLabel => 'Hoogtes';

  @override
  String alarmsCotaValue(int meters) {
    return 'Hoogte $meters m';
  }

  @override
  String get alarmsVolume => 'Alarmvolume';

  @override
  String get gpsAutoConfigInfo => 'Wanneer je een track volgt of het afstandsalarm activeert, wordt de GPS automatisch geconfigureerd om de nauwkeurigheid te verbeteren.';

  @override
  String get gpsLockedMessage => 'Instellingen vergrendeld: navigatie of alarm actief';

  @override
  String get reasonAlarm => 'Alarm actief';

  @override
  String get reasonTrack => 'Navigatie actief';

  @override
  String get barometerTitle => 'Barometer';

  @override
  String get fusedAltitude => 'Gecorrigeerde hoogte';

  @override
  String get manualCalibration => 'Handmatige kalibratie';

  @override
  String get recalibrateGpsDem => 'Opnieuw kalibreren met GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Huidige GPS-nauwkeurigheid';

  @override
  String get insufficientCoverage => 'Onvoldoende dekking om goed te kalibreren.';

  @override
  String get waitingValidAltitude => 'Wachten op een geldig hoogtesignaal...';

  @override
  String get barometerCalibratedSuccess => 'Barometer succesvol gekalibreerd';

  @override
  String get autoCalibrationInterval => 'Interval voor automatische kalibratie';

  @override
  String get howOften => 'Hoe vaak?';

  @override
  String get barometerExplanation => 'De barometer wordt automatisch opnieuw gekalibreerd zodra deze tijd is verstreken, zolang de GPS-dekking goed is.';

  @override
  String get statDetailRecordingData => 'Opnamegegevens';

  @override
  String get statDetailRealTrackSubtitle => 'Track in realtime';

  @override
  String get statDetailReferenceData => 'Referentiegegevens';

  @override
  String get statDetailImportedTrackSubtitle => 'Route';

  @override
  String get statDetailBackButton => 'TERUG NAAR STATISTIEKEN';

  @override
  String statDetailChartTitle(Object label) {
    return 'PROFIEL VAN $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PROFIEL VAN $label';
  }

  @override
  String get waypointsRecorded => 'Waypoints van de track';

  @override
  String get waypointsImported => 'Waypoints van de route';

  @override
  String get noRecordedTrack => 'Geen track beschikbaar';

  @override
  String get usingImportedTrack => 'Geïmporteerde route wordt weergegeven';

  @override
  String get statTimeTotal => 'Totale tijd';

  @override
  String get statTimeMoving => 'Bewegingstijd';

  @override
  String get statTimeStopped => 'Stilstandtijd';

  @override
  String get statTimeToWaypoint => 'Tijd tot waypoint';

  @override
  String get statSpeedCurrent => 'Huidige snelheid';

  @override
  String get statSpeedAverage => 'Gemiddelde snelheid';

  @override
  String get statSpeedTotal => 'Gemiddelde totale snelheid';

  @override
  String get statElevation => 'Hoogte';

  @override
  String get statElevationCurrent => 'Huidige hoogte';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Richting';

  @override
  String get statSatellites => 'Satellieten';

  @override
  String get statAccuracy => 'Nauwkeurigheid';

  @override
  String get satelliteSkyplotTitle => 'Hemelkaart';

  @override
  String get satelliteFlagsMode => 'Signalen';

  @override
  String get satelliteGeometryMode => 'Geometrieën';

  @override
  String get satelliteSearching => 'Satellieten zoeken... Zorg ervoor dat GPS buiten is ingeschakeld.';

  @override
  String get satelliteNoVisible => 'Geen zichtbare satellieten';

  @override
  String get satelliteUtcTime => 'UTC-tijd';

  @override
  String get satelliteFixType => 'Fix-type';

  @override
  String get satelliteFix3dRtk => '3D/RTK-fix';

  @override
  String get satelliteNoFix => 'Geen fix';

  @override
  String get satelliteSatellitesInView => 'Satellieten in beeld';

  @override
  String get satelliteSatellitesInUse => 'Satellieten in gebruik';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Waypoint verwijderen';

  @override
  String get deleteWaypointTitle => 'Waypoint verwijderen?';

  @override
  String get deleteWaypointMessage => 'Weet je zeker dat je dit interessepunt definitief wilt verwijderen?';

  @override
  String get deleteConfirm => 'VERWIJDEREN';

  @override
  String get waypointDeletedSuccess => 'Waypoint succesvol verwijderd';

  @override
  String get statSpeedMax => 'Maximale snelheid';

  @override
  String get statPaceAverage => 'Gemiddeld tempo';

  @override
  String get statPace => 'Tempo';

  @override
  String get statBarometerPressure => 'Atmosferische druk';

  @override
  String get statRangeSelectedTitle => 'Geselecteerd bereik';

  @override
  String get statRangeDistance => 'Afstand';

  @override
  String get statRangeAscent => 'Stijging +';

  @override
  String get statRangeDescent => 'Daling -';

  @override
  String get statRangeTime => 'Tijd van het traject';

  @override
  String get statPositionDecimal => 'Decimale positie';

  @override
  String get statPositionDMS => 'Positie DMS';

  @override
  String get demManagerTitle => 'DEM-tegelbeheer';

  @override
  String get demManagerDesc => 'Strack Rec downloadt de hoogte automatisch wanneer er dekking beschikbaar is. Zoom in op de kaart om handmatig maximaal 8 gebieden van 0,2° op te slaan voor offline gebruik.';

  @override
  String get demCellDownloaded => 'Tegel lokaal gedownload';

  @override
  String get demCellAvailable => 'Tegel beschikbaar om te downloaden';

  @override
  String get demDeleteConfirm => 'Wil je deze tegel van de schijf verwijderen?';

  @override
  String get demLimitReached => 'Limiet bereikt. Verwijder een oude tegel om een nieuwe te downloaden.';

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
  String get record => 'Opnemen';

  @override
  String get recordPaused => 'Gepauzeerd';

  @override
  String get recordStart => 'Opname starten';

  @override
  String get recordPause => 'Pauzeren';

  @override
  String get recordResume => 'Hervatten';

  @override
  String get recordStop => 'Beëindigen';

  @override
  String get navigationLoadTrack => 'Track laden';

  @override
  String get navigationFollow => 'Volgen';

  @override
  String get navigationFollowing => 'Volgen...';

  @override
  String get navigationPaused => 'Gepauzeerd';

  @override
  String get navigationStart => 'Starten';

  @override
  String get navigationCancel => 'Annuleren';

  @override
  String get navigationStop => 'Beëindigen';

  @override
  String get menuProfile => 'Profiel';

  @override
  String get menuSettings => 'Instellingen';

  @override
  String get submenuImportGpx => 'GPX importeren';

  @override
  String get submenuCancel => 'Annuleren';

  @override
  String get submenuStop => 'Beëindigen';

  @override
  String get submenuPause => 'Pauzeren';

  @override
  String get submenuResume => 'Hervatten';

  @override
  String get submenuFollowingPause => 'Pauzeren';

  @override
  String get submenuFollowingResume => 'Hervatten';

  @override
  String get submenuFollowingStop => 'Beëindigen';

  @override
  String get gpsDisabledAppBar => 'GEEN GPS';

  @override
  String get recoverTrackDialogBody => 'Er zijn gegevens van een eerder niet-opgeslagen route gevonden. Wil je deze herstellen of liever helemaal opnieuw beginnen?';

  @override
  String get waypointNoGps => 'Wachten op GPS-signaal...';

  @override
  String get waypointDefaultPrefix => 'P';

  @override
  String get gpsSearching => 'Zoeken...';

  @override
  String get fixStart => 'Startpunt';

  @override
  String get fixEnd => 'Eindpunt';

  @override
  String get deleteCurrentTrackTitle => 'Gegevens verwijderen?';

  @override
  String get deleteCurrentTrackMessage => 'Wil je de huidige trackgegevens verwijderen?';

  @override
  String get deleteCurrentTrackKeep => 'BEWAREN';
}

/// The translations for Dutch Flemish, as used in Belgium (`nl_BE`).
class AppLocalizationsNlBe extends AppLocalizationsNl {
  AppLocalizationsNlBe(): super('nl_BE');

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Opnemen';

  @override
  String get stopRecording => 'Opname stoppen';

  @override
  String get gpsDisabled => 'GPS is uitgeschakeld';

  @override
  String get locationPermissionRequired => 'Locatietoestemming vereist';

  @override
  String get exitWarning => 'Druk nogmaals op Terug om af te sluiten';

  @override
  String get exitWhileRecording => 'Beëindig eerst de opname voordat je de app verlaat';

  @override
  String get exitWhileFollowing => 'Beëindig eerst de navigatie voordat je de app verlaat';

  @override
  String get exitWhileRecordingAndFollowing => 'Beëindig eerst de opname en de navigatie voordat je de app verlaat';

  @override
  String get longPressToFinish => 'Houd ingedrukt om de opname te beëindigen';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'ANNULEREN';

  @override
  String get close => 'SLUITEN';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Instellingen';

  @override
  String get recoverTrackTitle => 'Openstaande route';

  @override
  String get recoverTrackMessage => 'Er is een opname gevonden die niet correct werd afgesloten. Wil je deze hervatten of een nieuwe starten?';

  @override
  String get discard => 'VERWIJDEREN';

  @override
  String get recover => 'HERSTELLEN';

  @override
  String get exportTitle => 'GPX exporteren';

  @override
  String get exportMessage => 'Wil je de track nu exporteren?';

  @override
  String get export => 'EXPORTEREN';

  @override
  String get importGpxTitle => 'GPX importeren';

  @override
  String get importGpxMessage => 'Je hebt al een actieve route of geladen gegevens. Wil je deze vervangen door het GPX-bestand?';

  @override
  String get import => 'IMPORTEREN';

  @override
  String get viewModeTitle => 'Weergavemodus';

  @override
  String get viewModeMessage => 'Wil je naar de weergavemodus gaan? Er worden geen nieuwe punten toegevoegd en de opname wordt uitgeschakeld.';

  @override
  String get no => 'NEE';

  @override
  String get activate => 'ACTIVEREN';

  @override
  String get permissionNeededTitle => 'Toestemming vereist';

  @override
  String get continueLabel => 'DOORGAAN';

  @override
  String get locationPermissionTitle => 'Locatietoestemming';

  @override
  String get locationPermissionMessage => 'De app heeft geen toestemming om toegang te krijgen tot je locatie. Wil je de instellingen openen om toestemming te geven?';

  @override
  String get offTrack => 'Je wijkt af van de route';

  @override
  String get backOnTrack => 'Je bent weer op de track';

  @override
  String get elevationFixing => 'Hoogtes corrigeren';

  @override
  String get error => 'Fout';

  @override
  String get gpsRecordByTime => 'Opnemen op tijd';

  @override
  String get gpsRecordByDistance => 'Opnemen op afstand';

  @override
  String get gpsMaxAccuracy => 'Maximale nauwkeurigheid';

  @override
  String get gpsRecordingMethod => 'Opnamemethode';

  @override
  String get gpsSignalQuality => 'Signaalkwaliteit';

  @override
  String get gpsDiagnosticMode => 'GPS-diagnosemodus';

  @override
  String get gpsDiagnosticDescription => 'Registreert gedetailleerde telemetrie. Dit kan het batterijverbruik verhogen.';

  @override
  String get gpxIncludeExtraData => 'Extra gegevens opnemen in het GPX-bestand';

  @override
  String get gpxAccuracyPerPoint => 'Nauwkeurigheid per punt';

  @override
  String get gpxSpeed => 'Snelheid';

  @override
  String get gpxHeading => 'Richting';

  @override
  String get gpxSatellites => 'Satellieten';

  @override
  String get gpxVerticalAccuracy => 'Verticale nauwkeurigheid';

  @override
  String get gpxSelectAll => 'Alles selecteren';

  @override
  String get gpxDeselectAll => 'Alles deselecteren';

  @override
  String get gpxSaveTrack => 'Track nu opslaan';

  @override
  String get gpxTrackSaved => 'Track opgeslagen';

  @override
  String get switchOn => 'AAN';

  @override
  String get switchOff => 'UIT';

  @override
  String get trackColor => 'Kleur van de track';

  @override
  String get changeTrackColor => 'KLEUR VAN DE TRACK WIJZIGEN';

  @override
  String get trackWidth => 'Dikte van de track';

  @override
  String get trackPreview => 'Voorbeeld van de track:';

  @override
  String get pickColor => 'Kies een kleur';

  @override
  String get trackStatsTitle => 'Routegegevens';

  @override
  String get statTime => 'Totale tijd';

  @override
  String get statDistance => 'Totale afstand';

  @override
  String get statSpeed => 'Huidige snelheid';

  @override
  String get statMaxElevation => 'Maximale hoogte';

  @override
  String get statMinElevation => 'Minimale hoogte';

  @override
  String get statAscent => 'Totale stijging +';

  @override
  String get statDescent => 'Totale daling -';

  @override
  String get mapStatDistance => 'AFST.';

  @override
  String get mapStatRemaining => 'REST.';

  @override
  String get mapStatTime => 'TIJD';

  @override
  String get mapStatMoving => 'BEW.';

  @override
  String get mapStatStopped => 'STOP';

  @override
  String get mapStatWaypoint => 'PUNT';

  @override
  String get mapStatSpeed => 'SNELH.';

  @override
  String get mapStatSpeedAvg => 'GEM.';

  @override
  String get mapStatSpeedTotal => 'TOTAAL';

  @override
  String get mapStatSpeedMax => 'MAX.';

  @override
  String get mapStatPace => 'TEMPO';

  @override
  String get mapStatPaceAvg => 'GEM. TEMPO';

  @override
  String get mapStatAltitude => 'HOOGTE';

  @override
  String get mapStatAltMax => 'MAX. HOOGTE';

  @override
  String get mapStatAltMin => 'MIN. HOOGTE';

  @override
  String get mapStatAscent => 'STIJGING';

  @override
  String get mapStatDescent => 'DALING';

  @override
  String get mapStatPosition => 'POS.';

  @override
  String get mapStatPositionDms => 'POS. DMS';

  @override
  String get mapStatPressure => 'DRUK';

  @override
  String get mapStatGps => 'GPS';

  @override
  String get mapStatGpsAccuracy => 'GPS-NAUWKEURIGHEID';

  @override
  String get statRemaining => 'Resterend';

  @override
  String get elevationProfile => 'Hoogteprofiel';

  @override
  String get noData => 'Geen gegevens';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Route';

  @override
  String get resume => 'HERVATTEN';

  @override
  String get stopFollowing => 'STOPPEN';

  @override
  String get follow => 'ROUTE VOLGEN';

  @override
  String get pause => 'PAUZE';

  @override
  String get apply => 'TOEPASSEN';

  @override
  String get pendingChangesTitle => 'Niet-toegepaste wijzigingen';

  @override
  String get pendingChangesMessage => 'Je hebt wijzigingen aangebracht die nog niet zijn toegepast. Wil je deze toepassen voordat je teruggaat naar de kaart?';

  @override
  String get settingsApplied => 'Instellingen toegepast!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'TOEPASSEN';

  @override
  String get endOfTrack => 'Je hebt het einde van de track bereikt';

  @override
  String get reverseTrackTitle => 'Omgekeerde richting';

  @override
  String get reverseTrackMessage => 'Het lijkt erop dat je de track in de tegenovergestelde richting volgt. Wil je deze omkeren om de navigatie te verbeteren?';

  @override
  String get reverseTrackConfirm => 'Ja, omkeren';

  @override
  String get ignoreTrackReverse => 'Doorgaan';

  @override
  String get gpxFilenameTitle => 'Naam van het GPX-bestand';

  @override
  String get gpxFilenameLabel => 'Bestandsnaam';

  @override
  String get gpxFilenameHint => 'Voer de bestandsnaam in';

  @override
  String get recording => 'Opnemen...';

  @override
  String get paused => 'GEPAUZEERD';

  @override
  String get following => 'VOLGEN';

  @override
  String get followPaused => 'ROUTE GEPAUZEERD';

  @override
  String get track => 'Route';

  @override
  String get followShort => 'Volgen';

  @override
  String get followingTitle => 'NAVIGATIE';

  @override
  String get recordingTitle => 'OPNAME';

  @override
  String get pauseShort => 'Pauze';

  @override
  String get stopShort => 'Stoppen';

  @override
  String get stopFollowingTitle => 'Navigatie stoppen';

  @override
  String get stopFollowingMessage => 'Wil je de navigatie stoppen? De route wordt van de kaart verwijderd.';

  @override
  String get stopFollowingConfirm => 'ROUTE STOPPEN';

  @override
  String get waypointNameTitle => 'Naam van het waypoint';

  @override
  String get waypointNameHint => 'Voer een naam in';

  @override
  String get finishRecordingTitle => 'Opname beëindigen';

  @override
  String get finishRecordingMessage => 'Wat wil je met de huidige opname doen?';

  @override
  String get finishRecordingConfirm => 'BEËINDIGEN';

  @override
  String get shareTrack => 'DELEN';

  @override
  String get continueRecording => 'Doorgaan met opnemen';

  @override
  String get deleteTrackTitle => 'Track verwijderen';

  @override
  String get deleteTrackMessage => 'Weet je zeker dat je deze route wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get deleteTrackConfirm => 'VERWIJDEREN';

  @override
  String get waypointDetailsTitle => 'Waypointgegevens';

  @override
  String get waypointName => 'Naam';

  @override
  String get waypointAltitude => 'Hoogte';

  @override
  String get waypointTrackPoint => 'Routepunt';

  @override
  String get waypointDistance => 'Totale afgelegde afstand';

  @override
  String get waypointTime => 'Passeertijd';

  @override
  String get gpsOptimizationTitle => 'GPS-optimalisatie';

  @override
  String get gpsOptimizationMessage => 'Voor nauwkeurige navigatie moet de modus voor hoge nauwkeurigheid worden geactiveerd. Dit kan het batterijverbruik verhogen.';

  @override
  String get confirm => 'BEVESTIGEN';

  @override
  String get notificationPermissionTitle => 'Navigatiemeldingen';

  @override
  String get understood => 'BEGREPEN';

  @override
  String get permissionNeededMessage => 'Deze app vereist dat je de optie \'Altijd toestaan\' selecteert om locatiegegevens te kunnen verzamelen terwijl de app actief is. Hierdoor kunnen je routes in realtime worden opgenomen en gevolgd, zelfs wanneer de app is geminimaliseerd of op de achtergrond draait.';

  @override
  String get notificationPermissionMessage => 'Deze app gebruikt een voorgrondservice om continue GPS-navigatie te garanderen tijdens het opnemen van je route. Er wordt een permanente melding weergegeven om je te informeren dat de app actief locatiegegevens verzamelt en om te voorkomen dat het systeem je route onderbreekt.';

  @override
  String get gpxErrorInvalidExtension => 'Het geselecteerde bestand is geen GPX-bestand';

  @override
  String get gpxErrorRead => 'Het GPX-bestand kon niet worden gelezen';

  @override
  String get gpxErrorInvalidXml => 'Het bestand lijkt geen geldige GPX-XML te zijn';

  @override
  String get gpxErrorNoGpxTag => 'Het bestand bevat geen GPX-gegevens';

  @override
  String get alarms => 'Alarmen';

  @override
  String get alarmsDistanceTitle => 'Afstand';

  @override
  String get alarmsDistanceLabel => 'Afgelegde meters';

  @override
  String get alarmsAltitudeTitle => 'Hoogte';

  @override
  String get alarmsAltitudeLabel => 'Hoogtemeters (+/-)';

  @override
  String get alarmsTimeTitle => 'Tijd';

  @override
  String get alarmsTimeLabel => 'Seconden';

  @override
  String get alarmsAccSegmentLabel => 'Hoogteverschil';

  @override
  String get alarmsCotaSegmentLabel => 'Hoogtes';

  @override
  String alarmsCotaValue(int meters) {
    return 'Hoogte $meters m';
  }

  @override
  String get alarmsVolume => 'Alarmvolume';

  @override
  String get gpsAutoConfigInfo => 'Wanneer je een track volgt of het afstandsalarm activeert, wordt de GPS automatisch geconfigureerd om de nauwkeurigheid te verbeteren.';

  @override
  String get gpsLockedMessage => 'Instellingen vergrendeld: navigatie of alarm actief';

  @override
  String get reasonAlarm => 'Alarm actief';

  @override
  String get reasonTrack => 'Navigatie actief';

  @override
  String get barometerTitle => 'Barometer';

  @override
  String get fusedAltitude => 'Gecorrigeerde hoogte';

  @override
  String get manualCalibration => 'Handmatige kalibratie';

  @override
  String get recalibrateGpsDem => 'Opnieuw kalibreren met GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Huidige GPS-nauwkeurigheid';

  @override
  String get insufficientCoverage => 'Onvoldoende dekking om goed te kalibreren.';

  @override
  String get waitingValidAltitude => 'Wachten op een geldig hoogtesignaal...';

  @override
  String get barometerCalibratedSuccess => 'Barometer succesvol gekalibreerd';

  @override
  String get autoCalibrationInterval => 'Interval voor automatische kalibratie';

  @override
  String get howOften => 'Hoe vaak?';

  @override
  String get barometerExplanation => 'De barometer wordt automatisch opnieuw gekalibreerd zodra deze tijd is verstreken, zolang de GPS-dekking goed is.';

  @override
  String get statDetailRecordingData => 'Opnamegegevens';

  @override
  String get statDetailRealTrackSubtitle => 'Track in realtime';

  @override
  String get statDetailReferenceData => 'Referentiegegevens';

  @override
  String get statDetailImportedTrackSubtitle => 'Route';

  @override
  String get statDetailBackButton => 'TERUG NAAR STATISTIEKEN';

  @override
  String statDetailChartTitle(Object label) {
    return 'PROFIEL VAN $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PROFIEL VAN $label';
  }

  @override
  String get waypointsRecorded => 'Waypoints van de track';

  @override
  String get waypointsImported => 'Waypoints van de route';

  @override
  String get noRecordedTrack => 'Geen track beschikbaar';

  @override
  String get usingImportedTrack => 'Geïmporteerde route wordt weergegeven';

  @override
  String get statTimeTotal => 'Totale tijd';

  @override
  String get statTimeMoving => 'Bewegingstijd';

  @override
  String get statTimeStopped => 'Stilstandtijd';

  @override
  String get statTimeToWaypoint => 'Tijd tot waypoint';

  @override
  String get statSpeedCurrent => 'Huidige snelheid';

  @override
  String get statSpeedAverage => 'Gemiddelde snelheid';

  @override
  String get statSpeedTotal => 'Gemiddelde totale snelheid';

  @override
  String get statElevation => 'Hoogte';

  @override
  String get statElevationCurrent => 'Huidige hoogte';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Richting';

  @override
  String get statSatellites => 'Satellieten';

  @override
  String get statAccuracy => 'Nauwkeurigheid';

  @override
  String get satelliteSkyplotTitle => 'Hemelkaart';

  @override
  String get satelliteFlagsMode => 'Signalen';

  @override
  String get satelliteGeometryMode => 'Geometrieën';

  @override
  String get satelliteSearching => 'Satellieten zoeken... Zorg ervoor dat GPS buiten is ingeschakeld.';

  @override
  String get satelliteNoVisible => 'Geen zichtbare satellieten';

  @override
  String get satelliteUtcTime => 'UTC-tijd';

  @override
  String get satelliteFixType => 'Fix-type';

  @override
  String get satelliteFix3dRtk => '3D/RTK-fix';

  @override
  String get satelliteNoFix => 'Geen fix';

  @override
  String get satelliteSatellitesInView => 'Satellieten in beeld';

  @override
  String get satelliteSatellitesInUse => 'Satellieten in gebruik';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Waypoint verwijderen';

  @override
  String get deleteWaypointTitle => 'Waypoint verwijderen?';

  @override
  String get deleteWaypointMessage => 'Weet je zeker dat je dit interessepunt definitief wilt verwijderen?';

  @override
  String get deleteConfirm => 'VERWIJDEREN';

  @override
  String get waypointDeletedSuccess => 'Waypoint succesvol verwijderd';

  @override
  String get statSpeedMax => 'Maximale snelheid';

  @override
  String get statPaceAverage => 'Gemiddeld tempo';

  @override
  String get statPace => 'Tempo';

  @override
  String get statBarometerPressure => 'Atmosferische druk';

  @override
  String get statRangeSelectedTitle => 'Geselecteerd bereik';

  @override
  String get statRangeDistance => 'Afstand';

  @override
  String get statRangeAscent => 'Stijging +';

  @override
  String get statRangeDescent => 'Daling -';

  @override
  String get statRangeTime => 'Tijd van het traject';

  @override
  String get statPositionDecimal => 'Decimale positie';

  @override
  String get statPositionDMS => 'Positie DMS';

  @override
  String get demManagerTitle => 'DEM-tegelbeheer';

  @override
  String get demManagerDesc => 'Strack Rec downloadt de hoogte automatisch wanneer er dekking beschikbaar is. Zoom in op de kaart om handmatig maximaal 8 gebieden van 0,2° op te slaan voor offline gebruik.';

  @override
  String get demCellDownloaded => 'Tegel lokaal gedownload';

  @override
  String get demCellAvailable => 'Tegel beschikbaar om te downloaden';

  @override
  String get demDeleteConfirm => 'Wil je deze tegel van de schijf verwijderen?';

  @override
  String get demLimitReached => 'Limiet bereikt. Verwijder een oude tegel om een nieuwe te downloaden.';

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
  String get record => 'Opnemen';

  @override
  String get recordPaused => 'Gepauzeerd';

  @override
  String get recordStart => 'Opname starten';

  @override
  String get recordPause => 'Pauzeren';

  @override
  String get recordResume => 'Hervatten';

  @override
  String get recordStop => 'Beëindigen';

  @override
  String get navigationLoadTrack => 'Track laden';

  @override
  String get navigationFollow => 'Volgen';

  @override
  String get navigationFollowing => 'Volgen...';

  @override
  String get navigationPaused => 'Gepauzeerd';

  @override
  String get navigationStart => 'Starten';

  @override
  String get navigationCancel => 'Annuleren';

  @override
  String get navigationStop => 'Beëindigen';

  @override
  String get menuProfile => 'Profiel';

  @override
  String get menuSettings => 'Instellingen';

  @override
  String get submenuImportGpx => 'GPX importeren';

  @override
  String get submenuCancel => 'Annuleren';

  @override
  String get submenuStop => 'Beëindigen';

  @override
  String get submenuPause => 'Pauzeren';

  @override
  String get submenuResume => 'Hervatten';

  @override
  String get submenuFollowingPause => 'Pauzeren';

  @override
  String get submenuFollowingResume => 'Hervatten';

  @override
  String get submenuFollowingStop => 'Beëindigen';

  @override
  String get gpsDisabledAppBar => 'GEEN GPS';

  @override
  String get recoverTrackDialogBody => 'Er zijn gegevens van een eerder niet-opgeslagen route gevonden. Wil je deze herstellen of liever helemaal opnieuw beginnen?';

  @override
  String get waypointNoGps => 'Wachten op GPS-signaal...';

  @override
  String get waypointDefaultPrefix => 'P';

  @override
  String get gpsSearching => 'Zoeken...';

  @override
  String get fixStart => 'Startpunt';

  @override
  String get fixEnd => 'Eindpunt';

  @override
  String get deleteCurrentTrackTitle => 'Gegevens verwijderen?';

  @override
  String get deleteCurrentTrackMessage => 'Wil je de huidige trackgegevens verwijderen?';

  @override
  String get deleteCurrentTrackKeep => 'BEWAREN';
}
