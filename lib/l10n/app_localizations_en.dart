// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Senda';

  @override
  String get startRecording => 'Record';

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
  String get gpsDisabledMessage => 'GPS is disabled';

  @override
  String get cancel => 'CANCEL';

  @override
  String get close => 'CLOSE';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Settings';

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
  String get offTrack => 'You are drifting away from the route';

  @override
  String get backOnTrack => 'You are on the track';

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
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Route';

  @override
  String get resume => 'RESUME';

  @override
  String get stopFollowing => 'STOP';

  @override
  String get follow => 'FOLLOW ROUTE';

  @override
  String get pause => 'PAUSE';

  @override
  String get apply => 'APPLY';

  @override
  String get pendingChangesTitle => 'Pending changes';

  @override
  String get pendingChangesMessage => 'You have unsaved changes. Do you want to apply them before returning to the map?';

  @override
  String get settingsApplied => 'Settings applied!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'APPLY';

  @override
  String get endOfTrack => 'You have reached the end of the track';

  @override
  String get reverseTrackTitle => 'Reverse direction';

  @override
  String get reverseTrackMessage => 'It looks like you are following the track in reverse. Do you want to invert it for better navigation?';

  @override
  String get reverseTrackConfirm => 'Yes, flip it';

  @override
  String get ignoreTrackReverse => 'No, keep it';

  @override
  String get gpxFilenameTitle => 'GPX file name';

  @override
  String get gpxFilenameLabel => 'File name';

  @override
  String get gpxFilenameHint => 'Enter the file name';

  @override
  String get recording => 'Recording...';

  @override
  String get paused => 'PAUSED';

  @override
  String get following => 'FOLLOWING';

  @override
  String get followPaused => 'TRACK PAUSED';

  @override
  String get track => 'Ruta';

  @override
  String get followShort => 'Seguir';

  @override
  String get followingTitle => 'SEGUIMIENTO';

  @override
  String get recordingTitle => 'GRABACIÓN';

  @override
  String get pauseShort => 'Pausa';

  @override
  String get stopShort => 'Detener';

  @override
  String get stopFollowingTitle => 'Stop Following';

  @override
  String get stopFollowingMessage => 'Do you want to stop following? The route will be removed from the map.';

  @override
  String get stopFollowingConfirm => 'STOP ROUTE';

  @override
  String get waypointNameTitle => 'Waypoint name';

  @override
  String get waypointNameHint => 'Enter a name';

  @override
  String get finishRecordingTitle => 'Finish recording';

  @override
  String get finishRecordingMessage => 'What would you like to do with the current recording?';

  @override
  String get finishRecordingConfirm => 'FINISH';

  @override
  String get shareTrack => 'SHARE';

  @override
  String get continueRecording => 'Continue recording';

  @override
  String get deleteTrackTitle => 'Delete track';

  @override
  String get deleteTrackMessage => 'Are you sure you want to delete this route? This action cannot be undone.';

  @override
  String get deleteTrackConfirm => 'DELETE';

  @override
  String get waypointDetailsTitle => 'Waypoint details';

  @override
  String get waypointName => 'Name';

  @override
  String get waypointAltitude => 'Altitude';

  @override
  String get waypointTrackPoint => 'Track point';

  @override
  String get waypointDistance => 'Accumulated distance';

  @override
  String get waypointTime => 'Time elapsed';

  @override
  String get gpsOptimizationTitle => 'GPS Optimization';

  @override
  String get gpsOptimizationMessage => 'For precise tracking, high-fidelity mode will be activated. This may increase battery consumption.';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get notificationPermissionTitle => 'Tracking Notifications';

  @override
  String get notificationPermissionMessage => 'Senda needs to show a notification while recording your route. This prevents the system from stopping the app to save battery and ensures you don\'t lose your track.';

  @override
  String get understood => 'UNDERSTOOD';

  @override
  String get gpxErrorInvalidExtension => 'The selected file is not a GPX file';

  @override
  String get gpxErrorRead => 'The GPX file could not be read';

  @override
  String get gpxErrorInvalidXml => 'The file does not appear to be valid GPX XML';

  @override
  String get gpxErrorNoGpxTag => 'The file contains no GPX data';

  @override
  String get alarms => 'Alarms';

  @override
  String get alarmsDistanceTitle => 'Distance';

  @override
  String get alarmsDistanceLabel => 'Meters traveled';

  @override
  String get alarmsAltitudeTitle => 'Altitude';

  @override
  String get alarmsAltitudeLabel => 'Elevation change (+/-)';

  @override
  String get alarmsTimeTitle => 'Time';

  @override
  String get alarmsTimeLabel => 'Seconds';

  @override
  String get gpsAutoConfigInfo => 'When following a track or enabling the distance alarm, the GPS automatically adjusts to improve accuracy.';

  @override
  String get gpsLockedMessage => 'Settings locked: Tracking or Alarm active';

  @override
  String get reasonAlarm => 'Alarm active';

  @override
  String get reasonTrack => 'Tracking in progress';

  @override
  String get barometerTitle => 'Barometer';

  @override
  String get fusedAltitude => 'Corrected Altitude';

  @override
  String get manualCalibration => 'Manual calibration';

  @override
  String get recalibrateGpsDem => 'Recalibrate with GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Current GPS accuracy';

  @override
  String get insufficientCoverage => 'Insufficient coverage to calibrate properly.';

  @override
  String get waitingValidAltitude => 'Waiting for valid altitude signal...';

  @override
  String get barometerCalibratedSuccess => 'Barometer calibrated successfully';

  @override
  String get autoCalibrationInterval => 'Auto calibration interval';

  @override
  String get howOften => 'How often?';

  @override
  String get barometerExplanation => 'The barometer will automatically recalibrate after this time, provided GPS coverage is good.';

  @override
  String get statDetailRecordingData => 'Recording data';

  @override
  String get statDetailRealTrackSubtitle => 'Real-time track';

  @override
  String get statDetailReferenceData => 'Reference data';

  @override
  String get statDetailImportedTrackSubtitle => 'Imported track';

  @override
  String get statDetailBackButton => 'BACK TO STATISTICS';

  @override
  String statDetailChartTitle(Object label) {
    return '$label PROFILE';
  }

  @override
  String statDetailChartProfile(String label) {
    return '$label PROFILE';
  }

  @override
  String get waypointsRecorded => 'Track waypoints';

  @override
  String get waypointsImported => 'Route waypoints';

  @override
  String get noRecordedTrack => 'No track available';

  @override
  String get usingImportedTrack => 'Showing imported route';

  @override
  String get statTimeTotal => 'Total time';

  @override
  String get statTimeMoving => 'Moving time';

  @override
  String get statTimeStopped => 'Stopped time';

  @override
  String get statSpeedCurrent => 'Current speed';

  @override
  String get statSpeedAverage => 'Average speed';

  @override
  String get statElevation => 'Elevation';

  @override
  String get statElevationCurrent => 'Current elevation';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Heading';

  @override
  String get statSatellites => 'Satellites';

  @override
  String get statAccuracy => 'Accuracy';

  @override
  String get deleteWaypoint => 'Delete waypoint';

  @override
  String get deleteWaypointTitle => 'Delete waypoint?';

  @override
  String get deleteWaypointMessage => 'Are you sure you want to delete this point of interest permanently?';

  @override
  String get deleteConfirm => 'DELETE';

  @override
  String get waypointDeletedSuccess => 'Waypoint successfully deleted';

  @override
  String get statSpeedMax => 'Max Speed';

  @override
  String get statPaceAverage => 'Average Pace';

  @override
  String get statPace => 'Pace';

  @override
  String get statBarometerPressure => 'BARO. PRES.';

  @override
  String get statRangeSelectedTitle => 'Selected range';

  @override
  String get statRangeDistance => 'Distance';

  @override
  String get statRangeAscent => 'Ascent';

  @override
  String get statRangeDescent => 'Descent';

  @override
  String get statRangeTime => 'Split time';

  @override
  String get statPositionDecimal => 'DD Position';

  @override
  String get statPositionDMS => 'DMS Position';

  @override
  String get demManagerTitle => 'DEM Cell Manager';

  @override
  String get demManagerDesc => 'Senda automatically downloads elevation data when connected. Zoom in on the map to manually save up to 8 zones of 0.2° for offline use.';

  @override
  String get demCellDownloaded => 'Cell downloaded locally';

  @override
  String get demCellAvailable => 'Cell available to download';

  @override
  String get demDeleteConfirm => 'Do you want to delete this cell from disk?';

  @override
  String get demLimitReached => 'Limit reached. Delete an old cell to download a new one.';

  @override
  String get record => 'Record';

  @override
  String get recordPaused => 'Paused';

  @override
  String get recordStart => 'Start recording';

  @override
  String get recordPause => 'Pause';

  @override
  String get recordResume => 'Resume';

  @override
  String get recordStop => 'Stop';

  @override
  String get navigationLoadTrack => 'Load track';

  @override
  String get navigationFollow => 'Follow';

  @override
  String get navigationFollowing => 'Following...';

  @override
  String get navigationPaused => 'Paused';

  @override
  String get navigationStart => 'Start';

  @override
  String get navigationCancel => 'Cancel';

  @override
  String get navigationStop => 'Stop';

  @override
  String get menuProfile => 'Profile';

  @override
  String get menuSettings => 'Settings';

  @override
  String get submenuImportGpx => 'Import GPX';

  @override
  String get submenuCancel => 'Cancel';

  @override
  String get submenuStop => 'Stop';

  @override
  String get submenuPause => 'Pause';

  @override
  String get submenuResume => 'Resume';

  @override
  String get submenuFollowingPause => 'Pause';

  @override
  String get submenuFollowingResume => 'Resume';

  @override
  String get submenuFollowingStop => 'Stop';

  @override
  String get gpsDisabledAppBar => 'NO GPS';

  @override
  String get recoverTrackDialogBody => 'An unsaved previous recording has been detected. Do you want to recover it or start a new one from scratch?';

  @override
  String get waypointNoGps => 'Waiting for GPS signal...';

  @override
  String get gpsSearching => 'Searching...';
}
