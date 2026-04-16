// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GpxGo';

  @override
  String get startRecording => 'Start recording';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get gpsDisabled => 'GPS is disabled';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String get exitWarning => 'Press back again to exit';

  @override
  String get longPressToFinish => 'Long press to finish recording';

  @override
  String get gpsDisabledTitle => 'GPS disabled';

  @override
  String get gpsDisabledMessage => 'GPS is disabled. Do you want to enable it now?';

  @override
  String get cancel => 'CANCEL';

  @override
  String get close => 'CLOSE';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'SETTINGS';

  @override
  String get recoverTrackTitle => 'Pending route';

  @override
  String get recoverTrackMessage => 'A previous recording was not closed properly. Do you want to continue it or start a new one?';

  @override
  String get discard => 'DISCARD';

  @override
  String get recover => 'RECOVER';

  @override
  String get exportTitle => 'Export GPX';

  @override
  String get exportMessage => 'Do you want to export the track now?';

  @override
  String get export => 'EXPORT';

  @override
  String get importGpxTitle => 'Import GPX';

  @override
  String get importGpxMessage => 'You already have an active route or loaded data. Do you want to replace it with the GPX file?';

  @override
  String get import => 'IMPORT';

  @override
  String get viewModeTitle => 'View mode';

  @override
  String get viewModeMessage => 'Do you want to enter view mode? No new points will be added and recording will be disabled.';

  @override
  String get no => 'NO';

  @override
  String get activate => 'ACTIVATE';

  @override
  String get permissionNeededTitle => 'Permission required';

  @override
  String get permissionNeededMessage => 'To record the route correctly with the screen off, you must select: 👉 \"Allow always\".';

  @override
  String get continueLabel => 'CONTINUE';

  @override
  String get locationPermissionTitle => 'Location permission';

  @override
  String get locationPermissionMessage => 'The app does not have permission to access location. Do you want to open settings to grant it?';

  @override
  String get offTrack => 'You are drifting away from the imported track';

  @override
  String get backOnTrack => 'You are back on the track';

  @override
  String get elevationFixing => 'Fixing altitudes';

  @override
  String get error => 'Error';

  @override
  String get gpsRecordByTime => 'Time-based recording';

  @override
  String get gpsRecordByDistance => 'Distance-based recording';

  @override
  String get gpsMaxAccuracy => 'Maximum accuracy';

  @override
  String get gpxIncludeExtraData => 'Include extra data in GPX file';

  @override
  String get gpxAccuracyPerPoint => 'Accuracy per point';

  @override
  String get gpxSpeed => 'Speed';

  @override
  String get gpxHeading => 'Heading';

  @override
  String get gpxSatellites => 'Satellites';

  @override
  String get gpxVerticalAccuracy => 'Vertical accuracy';

  @override
  String get switchOn => 'ON';

  @override
  String get switchOff => 'OFF';

  @override
  String get trackColor => 'Track color';

  @override
  String get changeTrackColor => 'CHANGE TRACK COLOR';

  @override
  String get trackWidth => 'Track width';

  @override
  String get trackPreview => 'Track preview:';

  @override
  String get pickColor => 'Pick a color';

  @override
  String get trackStatsTitle => 'Route data';

  @override
  String get statTime => 'TIME';

  @override
  String get statDistance => 'DIST';

  @override
  String get statSpeed => 'SPEED';

  @override
  String get statMaxElevation => 'MAX';

  @override
  String get statMinElevation => 'MIN';

  @override
  String get statAscent => '+ASC';

  @override
  String get statDescent => '-DES';

  @override
  String get elevationProfile => 'Elevation profile';

  @override
  String get noData => 'No data';

  @override
  String get realTrack => 'Real track';

  @override
  String get importedTrack => 'Imported track';

  @override
  String get resume => 'RESUME';

  @override
  String get stopFollowing => 'STOP';

  @override
  String get follow => 'FOLLOW';

  @override
  String get pause => 'PAUSE';
}
