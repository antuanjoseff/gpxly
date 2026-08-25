// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Grabar';

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get gpsDisabled => 'El GPS está desactivado';

  @override
  String get locationPermissionRequired => 'Se requieren permisos de ubicación';

  @override
  String get exitWarning => 'Pulsa atrás otra vez para salir';

  @override
  String get exitWhileRecording => 'Para salir, primero debes finalizar la grabación';

  @override
  String get exitWhileFollowing => 'Para salir, primero debes finalizar el seguimiento';

  @override
  String get exitWhileRecordingAndFollowing => 'Para salir, primero debes finalizar la grabación y el seguimiento';

  @override
  String get longPressToFinish => 'Mantén pulsado para finalizar la grabación';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get close => 'CERRAR';

  @override
  String get ok => 'ACEPTAR';

  @override
  String get settings => 'Configuración';

  @override
  String get recoverTrackTitle => 'Ruta pendiente';

  @override
  String get recoverTrackMessage => 'Se ha detectado una grabación que no se cerró correctamente. ¿Quieres continuarla o empezar una nueva?';

  @override
  String get discard => 'DESCARTAR';

  @override
  String get recover => 'RECUPERAR';

  @override
  String get exportTitle => 'Exportar GPX';

  @override
  String get exportMessage => '¿Quieres exportar el track ahora?';

  @override
  String get export => 'EXPORTAR';

  @override
  String get importGpxTitle => 'Importar GPX';

  @override
  String get importGpxMessage => 'Ya tienes una ruta activa o datos cargados. ¿Quieres sustituirlos por el archivo GPX?';

  @override
  String get import => 'IMPORTAR';

  @override
  String get viewModeTitle => 'Modo visualización';

  @override
  String get viewModeMessage => '¿Quieres entrar en modo visualización? No se añadirán puntos nuevos y la grabación quedará desactivada.';

  @override
  String get no => 'NO';

  @override
  String get activate => 'ACTIVAR';

  @override
  String get permissionNeededTitle => 'Permiso necesario';

  @override
  String get permissionNeededMessage => 'Para grabar la ruta correctamente con la pantalla apagada, debes seleccionar: 👉 \"Permitir siempre\".';

  @override
  String get continueLabel => 'CONTINUAR';

  @override
  String get locationPermissionTitle => 'Permiso de ubicación';

  @override
  String get locationPermissionMessage => 'La aplicación no tiene permisos para acceder a la ubicación. ¿Quieres abrir la configuración para concederlos?';

  @override
  String get offTrack => 'Te estás alejando de la ruta';

  @override
  String get backOnTrack => 'Estás sobre el track';

  @override
  String get elevationFixing => 'Corrigiendo altitudes';

  @override
  String get error => 'Error';

  @override
  String get gpsRecordByTime => 'Grabación por tiempo';

  @override
  String get gpsRecordByDistance => 'Grabación por distancia';

  @override
  String get gpsMaxAccuracy => 'Precisión máxima';

  @override
  String get gpsRecordingMethod => 'Método de grabación';

  @override
  String get gpsSignalQuality => 'Calidad de la señal';

  @override
  String get gpsDiagnosticMode => 'Modo de diagnóstico GPS';

  @override
  String get gpsDiagnosticDescription => 'Registra telemetría detallada. Puede aumentar el consumo de batería.';

  @override
  String get gpxIncludeExtraData => 'Incluir datos extra en el archivo GPX';

  @override
  String get gpxAccuracyPerPoint => 'Precisión por punto';

  @override
  String get gpxSpeed => 'Velocidad';

  @override
  String get gpxHeading => 'Rumbo (Heading)';

  @override
  String get gpxSatellites => 'Satélites';

  @override
  String get gpxVerticalAccuracy => 'Precisión vertical';

  @override
  String get gpxSelectAll => 'Marcar todo';

  @override
  String get gpxDeselectAll => 'Desmarcar todo';

  @override
  String get switchOn => 'ON';

  @override
  String get switchOff => 'OFF';

  @override
  String get trackColor => 'Color del track';

  @override
  String get changeTrackColor => 'CAMBIAR COLOR DEL TRAZO';

  @override
  String get trackWidth => 'Grosor del trazo';

  @override
  String get trackPreview => 'Previsualización del trazo:';

  @override
  String get pickColor => 'Elige un color';

  @override
  String get trackStatsTitle => 'Datos de la ruta';

  @override
  String get statTime => 'Tiempo total';

  @override
  String get statDistance => 'Distancia total';

  @override
  String get statSpeed => 'Velocidad actual';

  @override
  String get statMaxElevation => 'Cota máxima';

  @override
  String get statMinElevation => 'Cota mínima';

  @override
  String get statAscent => 'Desnivel acumulado +';

  @override
  String get statDescent => 'Desnivel acumulado -';

  @override
  String get elevationProfile => 'Perfil de elevación';

  @override
  String get noData => 'Sin datos';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Ruta';

  @override
  String get resume => 'REANUDAR';

  @override
  String get stopFollowing => 'DETENER';

  @override
  String get follow => 'SEGUIR RUTA';

  @override
  String get pause => 'PAUSA';

  @override
  String get apply => 'APLICAR';

  @override
  String get pendingChangesTitle => 'Cambios pendientes';

  @override
  String get pendingChangesMessage => 'Has realizado cambios que no has aplicado. ¿Quieres aplicarlos antes de volver al mapa?';

  @override
  String get settingsApplied => '¡Configuración aplicada!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'APLICAR';

  @override
  String get endOfTrack => 'Has llegado al final del track';

  @override
  String get reverseTrackTitle => 'Dirección inversa';

  @override
  String get reverseTrackMessage => 'Parece que estás siguiendo el track en dirección inversa. ¿Quieres invertirlo para mejorar la navegación?';

  @override
  String get reverseTrackConfirm => 'Si, invertir';

  @override
  String get ignoreTrackReverse => 'No, continuar';

  @override
  String get gpxFilenameTitle => 'Nombre del archivo GPX';

  @override
  String get gpxFilenameLabel => 'Nombre del archivo';

  @override
  String get gpxFilenameHint => 'Introduce el nombre del archivo';

  @override
  String get recording => 'Grabando..';

  @override
  String get paused => 'PAUSADO';

  @override
  String get following => 'SIGUIENDO';

  @override
  String get followPaused => 'RUTA EN PAUSA';

  @override
  String get track => 'Track';

  @override
  String get followShort => 'Follow';

  @override
  String get followingTitle => 'FOLLOWING';

  @override
  String get recordingTitle => 'RECORDING';

  @override
  String get pauseShort => 'Pause';

  @override
  String get stopShort => 'Stop';

  @override
  String get stopFollowingTitle => 'Detener seguimiento';

  @override
  String get stopFollowingMessage => '¿Quieres detener el seguimiento? Se quitará la ruta del mapa.';

  @override
  String get stopFollowingConfirm => 'DETENER RUTA';

  @override
  String get waypointNameTitle => 'Nombre del waypoint';

  @override
  String get waypointNameHint => 'Introduce un nombre';

  @override
  String get finishRecordingTitle => 'Finalizar grabación';

  @override
  String get finishRecordingMessage => '¿Qué quieres hacer con la grabación actual?';

  @override
  String get finishRecordingConfirm => 'FINALIZAR';

  @override
  String get shareTrack => 'COMPARTIR';

  @override
  String get continueRecording => 'Continuar grabando';

  @override
  String get deleteTrackTitle => 'Eliminar ruta';

  @override
  String get deleteTrackMessage => '¿Estás seguro de que quieres eliminar esta ruta? Esta acción no se puede deshacer.';

  @override
  String get deleteTrackConfirm => 'ELIMINAR';

  @override
  String get waypointDetailsTitle => 'Detalles del waypoint';

  @override
  String get waypointName => 'Nombre';

  @override
  String get waypointAltitude => 'Altitud';

  @override
  String get waypointTrackPoint => 'Punto de la ruta';

  @override
  String get waypointDistance => 'Distancia acumulada';

  @override
  String get waypointTime => 'Tiempo transcurrido';

  @override
  String get gpsOptimizationTitle => 'Optimización GPS';

  @override
  String get gpsOptimizationMessage => 'Para un seguimiento preciso, activaremos el modo de alta fidelidad. Esto puede aumentar el consumo de batería.';

  @override
  String get batteryOptimizationTitle => 'Evita que Android detenga el GPS';

  @override
  String get batteryOptimizationMessage => 'Para grabar sin cortes, sobre todo en paradas largas, hay que excluir sTrack Rec del ahorro de batería. Si no, Android puede detener el GPS cuando la pantalla esté apagada un rato.';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get notificationPermissionTitle => 'Notificaciones de seguimiento';

  @override
  String get notificationPermissionMessage => 'sTrack Rec necesita mostrar una notificación mientras grabas la ruta. Esto evita que el sistema detenga la aplicación para ahorrar batería y garantiza que no pierdas tu track.';

  @override
  String get understood => 'ENTENDIDO';

  @override
  String get gpxErrorInvalidExtension => 'El archivo seleccionado no es un GPX';

  @override
  String get gpxErrorRead => 'No se ha podido leer el archivo GPX';

  @override
  String get gpxErrorInvalidXml => 'El archivo no parece ser un XML GPX válido';

  @override
  String get gpxErrorNoGpxTag => 'El archivo no contiene datos GPX';

  @override
  String get alarms => 'Alarmas';

  @override
  String get alarmsDistanceTitle => 'Distancia';

  @override
  String get alarmsDistanceLabel => 'Metros recorridos';

  @override
  String get alarmsAltitudeTitle => 'Altitud';

  @override
  String get alarmsAltitudeLabel => 'Metros de desnivel (+/-)';

  @override
  String get alarmsTimeTitle => 'Tiempo';

  @override
  String get alarmsTimeLabel => 'Segundos';

  @override
  String get alarmsAccSegmentLabel => 'Desnivel';

  @override
  String get alarmsCotaSegmentLabel => 'Cotas';

  @override
  String alarmsCotaValue(int meters) {
    return 'Cota $meters m';
  }

  @override
  String get gpsAutoConfigInfo => 'Cuando sigues un track o activas la alarma por distancia, el GPS se autoconfigura para mejorar la precisión.';

  @override
  String get gpsLockedMessage => 'Configuración bloqueada: Seguimiento o Alarma activa';

  @override
  String get reasonAlarm => 'Alarma activa';

  @override
  String get reasonTrack => 'Seguimiento en curso';

  @override
  String get barometerTitle => 'Barómetro';

  @override
  String get fusedAltitude => 'Altitud corregida';

  @override
  String get manualCalibration => 'Calibración manual';

  @override
  String get recalibrateGpsDem => 'Recalibrar con GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Precisión GPS actual';

  @override
  String get insufficientCoverage => 'Cobertura insuficiente para calibrar bien.';

  @override
  String get waitingValidAltitude => 'Esperando señal de altitud válida...';

  @override
  String get barometerCalibratedSuccess => 'Barómetro calibrado con éxito';

  @override
  String get autoCalibrationInterval => 'Intervalo de calibración automático';

  @override
  String get howOften => '¿Cada cuánto tiempo?';

  @override
  String get barometerExplanation => 'El barómetro se recalibrará automáticamente cada vez que pase este tiempo, siempre que la cobertura GPS sea buena.';

  @override
  String get statDetailRecordingData => 'Datos de la grabación';

  @override
  String get statDetailRealTrackSubtitle => 'Track en tiempo real';

  @override
  String get statDetailReferenceData => 'Datos de referencia';

  @override
  String get statDetailImportedTrackSubtitle => 'Track importado';

  @override
  String get statDetailBackButton => 'VOLVER A ESTADÍSTICAS';

  @override
  String statDetailChartTitle(Object label) {
    return 'PERFIL DE $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PERFIL DE $label';
  }

  @override
  String get waypointsRecorded => 'Waypoints track';

  @override
  String get waypointsImported => 'Waypoints ruta';

  @override
  String get noRecordedTrack => 'No hay ningún track disponible';

  @override
  String get usingImportedTrack => 'Mostrando ruta importada';

  @override
  String get statTimeTotal => 'Tiempo total';

  @override
  String get statTimeMoving => 'Tiempo en movimiento';

  @override
  String get statTimeStopped => 'Tiempo detenido';

  @override
  String get statTimeToWaypoint => 'Tiempo hasta el siguiente waypoint';

  @override
  String get statSpeedCurrent => 'Velocidad actual';

  @override
  String get statSpeedAverage => 'Velocidad media';

  @override
  String get statSpeedTotal => 'Velocidad media total';

  @override
  String get statElevation => 'Altitud';

  @override
  String get statElevationCurrent => 'Altitud actual';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Rumbo';

  @override
  String get statSatellites => 'Satélites';

  @override
  String get statAccuracy => 'Precisión';

  @override
  String get satelliteSkyplotTitle => 'Carta celeste';

  @override
  String get satelliteFlagsMode => 'Banderas';

  @override
  String get satelliteGeometryMode => 'Geometrías';

  @override
  String get satelliteSearching => 'Buscando satélites... Asegúrate de tener el GPS activo al aire libre.';

  @override
  String get satelliteNoVisible => 'No hay satélites visibles';

  @override
  String get satelliteUtcTime => 'Hora UTC';

  @override
  String get satelliteFixType => 'Tipo de fix';

  @override
  String get satelliteFix3dRtk => 'Fix 3D/RTK';

  @override
  String get satelliteNoFix => 'Sin fix';

  @override
  String get satelliteSatellitesInView => 'Satélites a la vista';

  @override
  String get satelliteSatellitesInUse => 'Satélites en uso';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Eliminar hito';

  @override
  String get deleteWaypointTitle => '¿Eliminar hito?';

  @override
  String get deleteWaypointMessage => '¿Estás seguro de que quieres borrar este punto de interés definitivamente?';

  @override
  String get deleteConfirm => 'ELIMINAR';

  @override
  String get waypointDeletedSuccess => 'Hito borrado correctamente';

  @override
  String get statSpeedMax => 'Velocidad Máxima';

  @override
  String get statPaceAverage => 'Ritmo Medio';

  @override
  String get statPace => 'Ritmo';

  @override
  String get statBarometerPressure => 'Presión atmosférica';

  @override
  String get statRangeSelectedTitle => 'Rango seleccionado';

  @override
  String get statRangeDistance => 'Distancia';

  @override
  String get statRangeAscent => 'Desnivel +';

  @override
  String get statRangeDescent => 'Desnivel -';

  @override
  String get statRangeTime => 'Tiempo del tramo';

  @override
  String get statPositionDecimal => 'Posición GD';

  @override
  String get statPositionDMS => 'Posición DMS';

  @override
  String get demManagerTitle => 'Gestor de Celdas DEM';

  @override
  String get demManagerDesc => 'Strack Rec descarga automáticamente la altitud si hay cobertura. Acércate al mapa para guardar manualmente hasta 8 zonas de 0.2° para usar offline.';

  @override
  String get demCellDownloaded => 'Celda descargada en local';

  @override
  String get demCellAvailable => 'Celda disponible para descargar';

  @override
  String get demDeleteConfirm => '¿Quieres eliminar esta celda del disco?';

  @override
  String get demLimitReached => 'Techo alcanzado. Elimina una celda antigua para bajar una nueva.';

  @override
  String get record => 'Grabar';

  @override
  String get recordPaused => 'Pausado';

  @override
  String get recordStart => 'Iniciar grabación';

  @override
  String get recordPause => 'Pausar';

  @override
  String get recordResume => 'Reanudar';

  @override
  String get recordStop => 'Finalizar';

  @override
  String get navigationLoadTrack => 'Cargar track';

  @override
  String get navigationFollow => 'Seguir';

  @override
  String get navigationFollowing => 'Siguiendo...';

  @override
  String get navigationPaused => 'Pausado';

  @override
  String get navigationStart => 'Iniciar';

  @override
  String get navigationCancel => 'Cancelar';

  @override
  String get navigationStop => 'Finalizar';

  @override
  String get menuProfile => 'Perfil';

  @override
  String get menuSettings => 'Ajustes';

  @override
  String get submenuImportGpx => 'Importar GPX';

  @override
  String get submenuCancel => 'Cancelar';

  @override
  String get submenuStop => 'Finalizar';

  @override
  String get submenuPause => 'Pausar';

  @override
  String get submenuResume => 'Reanudar';

  @override
  String get submenuFollowingPause => 'Pausar';

  @override
  String get submenuFollowingResume => 'Reanudar';

  @override
  String get submenuFollowingStop => 'Finalizar';

  @override
  String get gpsDisabledAppBar => 'SIN GPS';

  @override
  String get recoverTrackDialogBody => 'Se han detectado datos de una ruta anterior no guardada. ¿Quieres recuperarla o prefieres empezar una nueva desde cero?';

  @override
  String get waypointNoGps => 'Esperando señal GPS...';

  @override
  String get gpsSearching => 'Buscando...';

  @override
  String get fixStart => 'Punto de inicio';

  @override
  String get fixEnd => 'Punto final';

  @override
  String get deleteCurrentTrackTitle => '¿Eliminar datos?';

  @override
  String get deleteCurrentTrackMessage => '¿Quieres eliminar la información actual del track?';

  @override
  String get deleteCurrentTrackKeep => 'MANTENER';
}
