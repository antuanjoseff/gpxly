// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Senda';

  @override
  String get startRecording => 'Gravar';

  @override
  String get stopRecording => 'Atura gravació';

  @override
  String get gpsDisabled => 'El GPS està desactivat';

  @override
  String get locationPermissionRequired => 'Cal acceptar permisos de localització';

  @override
  String get exitWarning => 'Prem enrere un altre cop per sortir';

  @override
  String get longPressToFinish => 'Mantén premut per finalitzar la gravació';

  @override
  String get gpsDisabledTitle => 'GPS desactivat';

  @override
  String get gpsDisabledMessage => 'El GPS està desactivat. Vols activar-lo ara?';

  @override
  String get cancel => 'CANCEL·LAR';

  @override
  String get close => 'TANCAR';

  @override
  String get ok => 'D\'ACORD';

  @override
  String get settings => 'Configuració';

  @override
  String get recoverTrackTitle => 'Ruta pendent';

  @override
  String get recoverTrackMessage => 'S\'ha detectat una gravació que no es va tancar correctament. Vols continuar-la o començar-ne una de nova?';

  @override
  String get discard => 'DESCARTAR';

  @override
  String get recover => 'RECUPERAR';

  @override
  String get exportTitle => 'Exportar GPX';

  @override
  String get exportMessage => 'Vols exportar el track ara?';

  @override
  String get export => 'EXPORTAR';

  @override
  String get importGpxTitle => 'Importar GPX';

  @override
  String get importGpxMessage => 'Ja tens una ruta activa o dades carregades. Vols substituir-les pel fitxer GPX?';

  @override
  String get import => 'IMPORTAR';

  @override
  String get viewModeTitle => 'Mode visualització';

  @override
  String get viewModeMessage => 'Vols entrar en mode visualització? No s\'afegiran punts nous i la gravació quedarà desactivada.';

  @override
  String get no => 'NO';

  @override
  String get activate => 'ACTIVAR';

  @override
  String get permissionNeededTitle => 'Permís necessari';

  @override
  String get permissionNeededMessage => 'Per poder gravar la ruta correctament amb la pantalla apagada, cal seleccionar: 👉 \"Permetre sempre\".';

  @override
  String get continueLabel => 'CONTINUA';

  @override
  String get locationPermissionTitle => 'Permís de localització';

  @override
  String get locationPermissionMessage => 'L’aplicació no té permisos per accedir a la ubicació. Vols obrir la configuració per donar permisos?';

  @override
  String get offTrack => 'T\'estàs allunyant de la ruta';

  @override
  String get backOnTrack => 'Estàs sobre el track';

  @override
  String get elevationFixing => 'Corregint altituds';

  @override
  String get error => 'Error';

  @override
  String get gpsRecordByTime => 'Gravació per temps';

  @override
  String get gpsRecordByDistance => 'Gravació per distància';

  @override
  String get gpsMaxAccuracy => 'Accuracy màxima';

  @override
  String get gpxIncludeExtraData => 'Incloure dades extres al fitxer GPX';

  @override
  String get gpxAccuracyPerPoint => 'Accuracy per punt';

  @override
  String get gpxSpeed => 'Velocitat';

  @override
  String get gpxHeading => 'Heading (Rumb)';

  @override
  String get gpxSatellites => 'Satèl·lits';

  @override
  String get gpxVerticalAccuracy => 'Vertical accuracy';

  @override
  String get switchOn => 'ON';

  @override
  String get switchOff => 'OFF';

  @override
  String get trackColor => 'Color del track';

  @override
  String get changeTrackColor => 'CANVIA EL COLOR DEL TRAÇ';

  @override
  String get trackWidth => 'Gruix del traç';

  @override
  String get trackPreview => 'Previsualització del traç:';

  @override
  String get pickColor => 'Tria un color';

  @override
  String get trackStatsTitle => 'Dades de la ruta';

  @override
  String get statTime => 'TMP';

  @override
  String get statDistance => 'DIST';

  @override
  String get statSpeed => 'VEL';

  @override
  String get statMaxElevation => 'MAX';

  @override
  String get statMinElevation => 'MIN';

  @override
  String get statAscent => '+ASC';

  @override
  String get statDescent => '-DES';

  @override
  String get elevationProfile => 'Perfil d\'elevació';

  @override
  String get noData => 'Sense dades';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Ruta';

  @override
  String get resume => 'REPRÈN';

  @override
  String get stopFollowing => 'ATURA';

  @override
  String get follow => 'SEGUIR RUTA';

  @override
  String get pause => 'PAUSA';

  @override
  String get apply => 'APLICA';

  @override
  String get pendingChangesTitle => 'Canvis pendents';

  @override
  String get pendingChangesMessage => 'Has fet canvis que no has aplicat. Vols aplicar-los abans de tornar al mapa?';

  @override
  String get settingsApplied => 'Configuració aplicada!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'APLICA';

  @override
  String get endOfTrack => 'Has arribat al final del track';

  @override
  String get reverseTrackTitle => 'Direcció inversa';

  @override
  String get reverseTrackMessage => 'Sembla que estàs seguint el track en direcció inversa. Vols invertir-lo per millorar la navegació?';

  @override
  String get reverseTrackConfirm => 'Sí, inverteix';

  @override
  String get ignoreTrackReverse => 'Continuar';

  @override
  String get gpxFilenameTitle => 'Nom del fitxer GPX';

  @override
  String get gpxFilenameLabel => 'Nom del fitxer';

  @override
  String get gpxFilenameHint => 'Introdueix el nom del fitxer';

  @override
  String get recording => 'GRAVANT';

  @override
  String get paused => 'PAUSAT';

  @override
  String get following => 'SEGUINT';

  @override
  String get followPaused => 'PAUSA RUTA';

  @override
  String get track => 'Ruta';

  @override
  String get followShort => 'Seguir';

  @override
  String get followingTitle => 'SEGUIMENT';

  @override
  String get recordingTitle => 'GRAVACIÓ';

  @override
  String get pauseShort => 'Pausa';

  @override
  String get stopShort => 'Atura';

  @override
  String get stopFollowingTitle => 'Aturar seguiment';

  @override
  String get stopFollowingMessage => 'Vols aturar el seguiment? Es traurà la ruta del mapa.';

  @override
  String get stopFollowingConfirm => 'ATURAR RUTA';

  @override
  String get waypointNameTitle => 'Nom del waypoint';

  @override
  String get waypointNameHint => 'Introdueix un nom';

  @override
  String get finishRecordingTitle => 'Finalitzar gravació';

  @override
  String get finishRecordingMessage => 'Què vols fer amb la gravació actual?';

  @override
  String get finishRecordingConfirm => 'FINALITZAR';

  @override
  String get shareTrack => 'COMPARTIR';

  @override
  String get continueRecording => 'Continuar gravant';

  @override
  String get deleteTrackTitle => 'Eliminar track';

  @override
  String get deleteTrackMessage => 'Estàs segur que vols eliminar aquesta ruta? Aquesta acció no es pot desfer.';

  @override
  String get deleteTrackConfirm => 'ELIMINAR';

  @override
  String get waypointDetailsTitle => 'Detalls del waypoint';

  @override
  String get waypointName => 'Nom';

  @override
  String get waypointAltitude => 'Altitud';

  @override
  String get waypointTrackPoint => 'Punt de la ruta';

  @override
  String get waypointDistance => 'Distància acumulada';

  @override
  String get waypointTime => 'Temps de pas';

  @override
  String get gpsOptimizationTitle => 'Optimització GPS';

  @override
  String get gpsOptimizationMessage => 'Per a un seguiment precís, cal activar el mode d\'alta fidelitat. Això pot augmentar el consum de bateria.';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get notificationPermissionTitle => 'Notificacions de seguiment';

  @override
  String get notificationPermissionMessage => 'Senda necessita mostrar una notificació mentre graves la ruta. Això evita que el sistema aturi l\'aplicació per estalviar bateria i garanteix que no perdis el teu track.';

  @override
  String get understood => 'ENTESOS';

  @override
  String get gpxErrorInvalidExtension => 'El fitxer seleccionat no és un GPX';

  @override
  String get gpxErrorRead => 'No s\'ha pogut llegir el fitxer GPX';

  @override
  String get gpxErrorInvalidXml => 'El fitxer no sembla un XML GPX vàlid';

  @override
  String get gpxErrorNoGpxTag => 'El fitxer no conté dades GPX';

  @override
  String get alarms => 'Alarmes';

  @override
  String get alarmsDistanceTitle => 'Distància';

  @override
  String get alarmsDistanceLabel => 'Metres recorreguts';

  @override
  String get alarmsAltitudeTitle => 'Altitud';

  @override
  String get alarmsAltitudeLabel => 'Metres de desnivell (+/-)';

  @override
  String get alarmsTimeTitle => 'Temps';

  @override
  String get alarmsTimeLabel => 'Segons';

  @override
  String get gpsAutoConfigInfo => 'Quan segueixes un track o actives l’alarma per distància, el GPS s’autoconfigura per millorar la precisió.';

  @override
  String get gpsLockedMessage => 'Configuració bloquejada: Seguiment o Alarma activa';

  @override
  String get reasonAlarm => 'Alarma activa';

  @override
  String get reasonTrack => 'Seguiment en curs';

  @override
  String get barometerTitle => 'Baròmetre';

  @override
  String get fusedAltitude => 'Altitud corregida';

  @override
  String get manualCalibration => 'Calibratge manual';

  @override
  String get recalibrateGpsDem => 'Recalibrar amb GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Precisió GPS actual';

  @override
  String get insufficientCoverage => 'Cobertura insuficient per calibrar bé.';

  @override
  String get waitingValidAltitude => 'Esperant senyal d\'altitud vàlida...';

  @override
  String get barometerCalibratedSuccess => 'Baròmetre calibrat amb èxit';

  @override
  String get autoCalibrationInterval => 'Interval de calibratge automàtic';

  @override
  String get howOften => 'Cada quant temps?';

  @override
  String get barometerExplanation => 'El baròmetre es recalibrarà automàticament cada cop que passi aquest temps, sempre que la cobertura GPS sigui bona.';

  @override
  String get statDetailRecordingData => 'Dades de la gravació';

  @override
  String get statDetailRealTrackSubtitle => 'Track en temps real';

  @override
  String get statDetailReferenceData => 'Dades de referència';

  @override
  String get statDetailImportedTrackSubtitle => 'Track importat';

  @override
  String get statDetailBackButton => 'TORNAR A ESTADÍSTIQUES';

  @override
  String statDetailChartTitle(Object label) {
    return 'PERFIL DE $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PERFIL DE $label';
  }
}
