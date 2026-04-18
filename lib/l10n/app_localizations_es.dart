// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'GpxGo';

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
  String get longPressToFinish => 'Mantén pulsado para finalizar la grabación';

  @override
  String get gpsDisabledTitle => 'GPS desactivado';

  @override
  String get gpsDisabledMessage => 'El GPS está desactivado. ¿Quieres activarlo ahora?';

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
  String get offTrack => 'Te estás alejando del track importado';

  @override
  String get backOnTrack => 'Has vuelto al track';

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
  String get elevationProfile => 'Perfil de elevación';

  @override
  String get noData => 'Sin datos';

  @override
  String get realTrack => 'Track real';

  @override
  String get importedTrack => 'Track importado';

  @override
  String get resume => 'REANUDAR';

  @override
  String get stopFollowing => 'DETENER';

  @override
  String get follow => 'SEGUIR';

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
}
