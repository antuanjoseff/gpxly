// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'GpxGo';

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
  String get offTrack => 'T\'estàs allunyant del track importat';

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
  String get realTrack => 'Track real';

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
  String get reverseTrackConfirm => 'Inverteix';

  @override
  String get gpxFilenameTitle => 'Nom del fitxer GPX';

  @override
  String get gpxFilenameLabel => 'Nom del fitxer';

  @override
  String get gpxFilenameHint => 'Introdueix el nom del fitxer';
}
