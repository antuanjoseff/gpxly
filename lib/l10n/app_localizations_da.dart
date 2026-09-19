// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Optag';

  @override
  String get stopRecording => 'Stop optagelse';

  @override
  String get gpsDisabled => 'GPS er deaktiveret';

  @override
  String get locationPermissionRequired => 'Placeringstilladelse er påkrævet';

  @override
  String get exitWarning => 'Tryk tilbage igen for at afslutte';

  @override
  String get exitWhileRecording => 'Afslut optagelsen, før du lukker';

  @override
  String get exitWhileFollowing => 'Afslut sporing, før du lukker';

  @override
  String get exitWhileRecordingAndFollowing => 'Afslut optagelsen og sporingen, før du lukker';

  @override
  String get longPressToFinish => 'Tryk og hold for at afslutte optagelsen';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'ANNULLER';

  @override
  String get close => 'LUK';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Indstillinger';

  @override
  String get recoverTrackTitle => 'Uafsluttet rute';

  @override
  String get recoverTrackMessage => 'Der blev fundet en optagelse, som ikke blev afsluttet korrekt. Vil du fortsætte den eller starte en ny?';

  @override
  String get discard => 'KASSÉR';

  @override
  String get recover => 'GENDAN';

  @override
  String get exportTitle => 'Eksportér GPX';

  @override
  String get exportMessage => 'Vil du eksportere tracket nu?';

  @override
  String get export => 'EKSPORTÉR';

  @override
  String get importGpxTitle => 'Importér GPX';

  @override
  String get importGpxMessage => 'Du har allerede en aktiv rute eller indlæste data. Vil du erstatte dem med GPX-filen?';

  @override
  String get import => 'IMPORTÉR';

  @override
  String get viewModeTitle => 'Visningstilstand';

  @override
  String get viewModeMessage => 'Vil du gå til visningstilstand? Der tilføjes ingen nye punkter, og optagelsen deaktiveres.';

  @override
  String get no => 'NEJ';

  @override
  String get activate => 'AKTIVÉR';

  @override
  String get permissionNeededTitle => 'Tilladelse påkrævet';

  @override
  String get continueLabel => 'FORTSÆT';

  @override
  String get locationPermissionTitle => 'Placeringstilladelse';

  @override
  String get locationPermissionMessage => 'Appen har ikke tilladelse til at få adgang til din placering. Vil du åbne indstillingerne for at give tilladelse?';

  @override
  String get offTrack => 'Du bevæger dig væk fra ruten';

  @override
  String get backOnTrack => 'Du er tilbage på tracket';

  @override
  String get elevationFixing => 'Korrigerer højder';

  @override
  String get error => 'Fejl';

  @override
  String get gpsRecordByTime => 'Tidsbaseret optagelse';

  @override
  String get gpsRecordByDistance => 'Afstandsbaseret optagelse';

  @override
  String get gpsMaxAccuracy => 'Maksimal nøjagtighed';

  @override
  String get gpsRecordingMethod => 'Optagelsesmetode';

  @override
  String get gpsSignalQuality => 'Signalkvalitet';

  @override
  String get gpsDiagnosticMode => 'GPS-diagnosetilstand';

  @override
  String get gpsDiagnosticDescription => 'Registrerer detaljeret telemetri. Kan øge batteriforbruget.';

  @override
  String get gpxIncludeExtraData => 'Inkludér ekstra data i GPX-filen';

  @override
  String get gpxAccuracyPerPoint => 'Nøjagtighed pr. punkt';

  @override
  String get gpxSpeed => 'Hastighed';

  @override
  String get gpxHeading => 'Retning';

  @override
  String get gpxSatellites => 'Satellitter';

  @override
  String get gpxVerticalAccuracy => 'Lodret nøjagtighed';

  @override
  String get gpxSelectAll => 'Markér alle';

  @override
  String get gpxDeselectAll => 'Fjern markering fra alle';

  @override
  String get gpxSaveTrack => 'Gem tracket nu';

  @override
  String get gpxTrackSaved => 'Track gemt';

  @override
  String get switchOn => 'TIL';

  @override
  String get switchOff => 'FRA';

  @override
  String get trackColor => 'Trackfarve';

  @override
  String get changeTrackColor => 'SKIFT FARVE PÅ SPOR';

  @override
  String get trackWidth => 'Sporbredde';

  @override
  String get trackPreview => 'Forhåndsvisning af spor:';

  @override
  String get pickColor => 'Vælg en farve';

  @override
  String get trackStatsTitle => 'Rutedata';

  @override
  String get statTime => 'Samlet tid';

  @override
  String get statDistance => 'Samlet distance';

  @override
  String get statSpeed => 'Aktuel hastighed';

  @override
  String get statMaxElevation => 'Maksimal højde';

  @override
  String get statMinElevation => 'Minimal højde';

  @override
  String get statAscent => 'Samlet stigning +';

  @override
  String get statDescent => 'Samlet nedstigning -';

  @override
  String get mapStatDistance => 'DIST.';

  @override
  String get mapStatRemaining => 'REST.';

  @override
  String get mapStatTime => 'TID';

  @override
  String get mapStatMoving => 'I BEV.';

  @override
  String get mapStatStopped => 'STOP.';

  @override
  String get mapStatWaypoint => 'WAYPOINT';

  @override
  String get mapStatSpeed => 'FART';

  @override
  String get mapStatSpeedAvg => 'GN.SN.';

  @override
  String get mapStatSpeedTotal => 'TOTAL';

  @override
  String get mapStatSpeedMax => 'MAKS.';

  @override
  String get mapStatPace => 'TEMPO';

  @override
  String get mapStatPaceAvg => 'GN.SN. TEMPO';

  @override
  String get mapStatAltitude => 'HØJDE';

  @override
  String get mapStatAltMax => 'MAKS. HØJDE';

  @override
  String get mapStatAltMin => 'MIN. HØJDE';

  @override
  String get mapStatAscent => 'STIGNING';

  @override
  String get mapStatDescent => 'NEDSTIGNING';

  @override
  String get mapStatPosition => 'POS.';

  @override
  String get mapStatPositionDms => 'POS. DMS';

  @override
  String get mapStatPressure => 'TRYK';

  @override
  String get mapStatGps => 'GPS';

  @override
  String get mapStatGpsAccuracy => 'GPS-NØJAGTIGHED';

  @override
  String get statRemaining => 'Resterende';

  @override
  String get elevationProfile => 'Højdeprofil';

  @override
  String get noData => 'Ingen data';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Rute';

  @override
  String get resume => 'GENOPTAG';

  @override
  String get stopFollowing => 'STOP';

  @override
  String get follow => 'FØLG RUTE';

  @override
  String get pause => 'PAUSE';

  @override
  String get apply => 'ANVEND';

  @override
  String get pendingChangesTitle => 'Ventende ændringer';

  @override
  String get pendingChangesMessage => 'Du har foretaget ændringer, som ikke er anvendt. Vil du anvende dem, før du vender tilbage til kortet?';

  @override
  String get settingsApplied => 'Indstillinger anvendt!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'ANVEND';

  @override
  String get endOfTrack => 'Du er nået til slutningen af tracket';

  @override
  String get reverseTrackTitle => 'Omvendt retning';

  @override
  String get reverseTrackMessage => 'Det ser ud til, at du følger tracket i den modsatte retning. Vil du vende det for at forbedre navigationen?';

  @override
  String get reverseTrackConfirm => 'Ja, vend det';

  @override
  String get ignoreTrackReverse => 'Fortsæt';

  @override
  String get gpxFilenameTitle => 'Navn på GPX-fil';

  @override
  String get gpxFilenameLabel => 'Filnavn';

  @override
  String get gpxFilenameHint => 'Indtast filnavnet';

  @override
  String get recording => 'Optager...';

  @override
  String get paused => 'PAUSET';

  @override
  String get following => 'FØLGER';

  @override
  String get followPaused => 'RUTE PAUSET';

  @override
  String get track => 'Rute';

  @override
  String get followShort => 'Følg';

  @override
  String get followingTitle => 'SPORING';

  @override
  String get recordingTitle => 'OPTAGELSE';

  @override
  String get pauseShort => 'Pause';

  @override
  String get stopShort => 'Stop';

  @override
  String get stopFollowingTitle => 'Stop sporing';

  @override
  String get stopFollowingMessage => 'Vil du stoppe sporingen? Ruten fjernes fra kortet.';

  @override
  String get stopFollowingConfirm => 'STOP RUTE';

  @override
  String get waypointNameTitle => 'Waypoint-navn';

  @override
  String get waypointNameHint => 'Indtast et navn';

  @override
  String get finishRecordingTitle => 'Afslut optagelse';

  @override
  String get finishRecordingMessage => 'Hvad vil du gøre med den aktuelle optagelse?';

  @override
  String get finishRecordingConfirm => 'AFSLUT';

  @override
  String get shareTrack => 'DEL';

  @override
  String get continueRecording => 'Fortsæt med at optage';

  @override
  String get deleteTrackTitle => 'Slet track';

  @override
  String get deleteTrackMessage => 'Er du sikker på, at du vil slette denne rute? Denne handling kan ikke fortrydes.';

  @override
  String get deleteTrackConfirm => 'SLET';

  @override
  String get waypointDetailsTitle => 'Waypoint-detaljer';

  @override
  String get waypointName => 'Navn';

  @override
  String get waypointAltitude => 'Højde';

  @override
  String get waypointTrackPoint => 'Rutepunkt';

  @override
  String get waypointDistance => 'Samlet distance';

  @override
  String get waypointTime => 'Passagetid';

  @override
  String get gpsOptimizationTitle => 'GPS-optimering';

  @override
  String get gpsOptimizationMessage => 'For præcis sporing skal tilstanden med høj præcision aktiveres. Dette kan øge batteriforbruget.';

  @override
  String get confirm => 'BEKRÆFT';

  @override
  String get notificationPermissionTitle => 'Sporingsnotifikationer';

  @override
  String get understood => 'FORSTÅET';

  @override
  String get permissionNeededMessage => 'Denne app kræver, at du vælger indstillingen \'Tillad altid\' for at kunne indsamle placeringsdata, mens appen kører. Dette gør det muligt at registrere og følge dine ruter i realtid, også når appen er minimeret eller kører i baggrunden.';

  @override
  String get notificationPermissionMessage => 'Denne app kører en tjeneste i forgrunden for at sikre kontinuerlig GPS-sporing, mens du registrerer din rute. Der vises en vedvarende notifikation for at informere dig om, at appen aktivt indsamler placeringsdata, så systemet ikke afbryder din tur.';

  @override
  String get gpxErrorInvalidExtension => 'Den valgte fil er ikke en GPX-fil';

  @override
  String get gpxErrorRead => 'GPX-filen kunne ikke læses';

  @override
  String get gpxErrorInvalidXml => 'Filen ser ikke ud til at være gyldig GPX-XML';

  @override
  String get gpxErrorNoGpxTag => 'Filen indeholder ingen GPX-data';

  @override
  String get alarms => 'Alarmer';

  @override
  String get alarmsDistanceTitle => 'Distance';

  @override
  String get alarmsDistanceLabel => 'Tilbagelagte meter';

  @override
  String get alarmsAltitudeTitle => 'Højde';

  @override
  String get alarmsAltitudeLabel => 'Højdeforskel (± meter)';

  @override
  String get alarmsTimeTitle => 'Tid';

  @override
  String get alarmsTimeLabel => 'Sekunder';

  @override
  String get alarmsAccSegmentLabel => 'Højdeforskel';

  @override
  String get alarmsCotaSegmentLabel => 'Højder';

  @override
  String alarmsCotaValue(int meters) {
    return 'Højde $meters m';
  }

  @override
  String get alarmsVolume => 'Alarmlydstyrke';

  @override
  String get gpsAutoConfigInfo => 'Når du følger et track eller aktiverer afstandsalarmen, konfigureres GPS automatisk for at forbedre nøjagtigheden.';

  @override
  String get gpsLockedMessage => 'Indstillinger låst: Sporing eller alarm aktiv';

  @override
  String get reasonAlarm => 'Alarm aktiv';

  @override
  String get reasonTrack => 'Sporing i gang';

  @override
  String get barometerTitle => 'Barometer';

  @override
  String get fusedAltitude => 'Korrigeret højde';

  @override
  String get manualCalibration => 'Manuel kalibrering';

  @override
  String get recalibrateGpsDem => 'Kalibrér igen med GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Aktuel GPS-nøjagtighed';

  @override
  String get insufficientCoverage => 'Utilstrækkelig dækning til korrekt kalibrering.';

  @override
  String get waitingValidAltitude => 'Venter på gyldigt højdesignal...';

  @override
  String get barometerCalibratedSuccess => 'Barometer kalibreret';

  @override
  String get autoCalibrationInterval => 'Automatisk kalibreringsinterval';

  @override
  String get howOften => 'Hvor ofte?';

  @override
  String get barometerExplanation => 'Barometeret kalibreres automatisk igen, hver gang dette tidsinterval er gået, så længe GPS-dækningen er god.';

  @override
  String get statDetailRecordingData => 'Optagelsesdata';

  @override
  String get statDetailRealTrackSubtitle => 'Track i realtid';

  @override
  String get statDetailReferenceData => 'Referencedata';

  @override
  String get statDetailImportedTrackSubtitle => 'Rute';

  @override
  String get statDetailBackButton => 'TILBAGE TIL STATISTIK';

  @override
  String statDetailChartTitle(Object label) {
    return 'PROFIL AF $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PROFIL AF $label';
  }

  @override
  String get waypointsRecorded => 'Track-waypoints';

  @override
  String get waypointsImported => 'Rute-waypoints';

  @override
  String get noRecordedTrack => 'Der er ingen tilgængelige tracks';

  @override
  String get usingImportedTrack => 'Viser importeret rute';

  @override
  String get statTimeTotal => 'Samlet tid';

  @override
  String get statTimeMoving => 'Tid i bevægelse';

  @override
  String get statTimeStopped => 'Stilletid';

  @override
  String get statTimeToWaypoint => 'Tid til waypoint';

  @override
  String get statSpeedCurrent => 'Aktuel hastighed';

  @override
  String get statSpeedAverage => 'Gennemsnitshastighed';

  @override
  String get statSpeedTotal => 'Samlet gennemsnitshastighed';

  @override
  String get statElevation => 'Højde';

  @override
  String get statElevationCurrent => 'Aktuel højde';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Retning';

  @override
  String get statSatellites => 'Satellitter';

  @override
  String get statAccuracy => 'Nøjagtighed';

  @override
  String get satelliteSkyplotTitle => 'Himmeldiagram';

  @override
  String get satelliteFlagsMode => 'Flag';

  @override
  String get satelliteGeometryMode => 'Geometrier';

  @override
  String get satelliteSearching => 'Søger efter satellitter... Sørg for, at GPS er aktiveret og at du er udendørs.';

  @override
  String get satelliteNoVisible => 'Ingen synlige satellitter';

  @override
  String get satelliteUtcTime => 'UTC-tid';

  @override
  String get satelliteFixType => 'Fix-type';

  @override
  String get satelliteFix3dRtk => '3D/RTK-fix';

  @override
  String get satelliteNoFix => 'Intet fix';

  @override
  String get satelliteSatellitesInView => 'Satellitter i synsfeltet';

  @override
  String get satelliteSatellitesInUse => 'Satellitter i brug';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Slet waypoint';

  @override
  String get deleteWaypointTitle => 'Slet waypoint?';

  @override
  String get deleteWaypointMessage => 'Er du sikker på, at du vil slette dette interessepunkt permanent?';

  @override
  String get deleteConfirm => 'SLET';

  @override
  String get waypointDeletedSuccess => 'Waypoint slettet';

  @override
  String get statSpeedMax => 'Maksimal hastighed';

  @override
  String get statPaceAverage => 'Gennemsnitstempo';

  @override
  String get statPace => 'Tempo';

  @override
  String get statBarometerPressure => 'Atmosfærisk tryk';

  @override
  String get statRangeSelectedTitle => 'Valgt interval';

  @override
  String get statRangeDistance => 'Distance';

  @override
  String get statRangeAscent => 'Stigning +';

  @override
  String get statRangeDescent => 'Nedstigning -';

  @override
  String get statRangeTime => 'Strækkets tid';

  @override
  String get statPositionDecimal => 'Position GD';

  @override
  String get statPositionDMS => 'Position DMS';

  @override
  String get demManagerTitle => 'DEM-cellehåndtering';

  @override
  String get demManagerDesc => 'Strack Rec downloader automatisk højdedata, når der er dækning. Zoom ind på kortet for manuelt at gemme op til 8 områder på 0,2° til offline-brug.';

  @override
  String get demCellDownloaded => 'Celle downloadet lokalt';

  @override
  String get demCellAvailable => 'Celle tilgængelig til download';

  @override
  String get demDeleteConfirm => 'Vil du slette denne celle fra disken?';

  @override
  String get demLimitReached => 'Grænsen er nået. Slet en ældre celle for at downloade en ny.';

  @override
  String get record => 'Optag';

  @override
  String get recordPaused => 'Pauset';

  @override
  String get recordStart => 'Start optagelse';

  @override
  String get recordPause => 'Pause';

  @override
  String get recordResume => 'Genoptag';

  @override
  String get recordStop => 'Afslut';

  @override
  String get navigationLoadTrack => 'Indlæs track';

  @override
  String get navigationFollow => 'Følg';

  @override
  String get navigationFollowing => 'Følger...';

  @override
  String get navigationPaused => 'Pauset';

  @override
  String get navigationStart => 'Start';

  @override
  String get navigationCancel => 'Annuller';

  @override
  String get navigationStop => 'Afslut';

  @override
  String get menuProfile => 'Profil';

  @override
  String get menuSettings => 'Indstillinger';

  @override
  String get submenuImportGpx => 'Importér GPX';

  @override
  String get submenuCancel => 'Annuller';

  @override
  String get submenuStop => 'Afslut';

  @override
  String get submenuPause => 'Pause';

  @override
  String get submenuResume => 'Genoptag';

  @override
  String get submenuFollowingPause => 'Pause';

  @override
  String get submenuFollowingResume => 'Genoptag';

  @override
  String get submenuFollowingStop => 'Afslut';

  @override
  String get gpsDisabledAppBar => 'INGEN GPS';

  @override
  String get recoverTrackDialogBody => 'Der blev fundet data fra en tidligere, ikke-gemt rute. Vil du gendanne den, eller vil du hellere starte en helt ny fra bunden?';

  @override
  String get waypointNoGps => 'Venter på GPS-signal...';

  @override
  String get waypointDefaultPrefix => 'P';

  @override
  String get gpsSearching => 'Søger...';

  @override
  String get fixStart => 'Startpunkt';

  @override
  String get fixEnd => 'Slutpunkt';

  @override
  String get deleteCurrentTrackTitle => 'Slet data?';

  @override
  String get deleteCurrentTrackMessage => 'Vil du slette de aktuelle trackoplysninger?';

  @override
  String get deleteCurrentTrackKeep => 'BEHOLD';
}
