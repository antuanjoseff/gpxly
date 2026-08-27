import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'STRec'**
  String get appTitle;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get startRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @gpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled'**
  String get gpsDisabled;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// No description provided for @exitWarning.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get exitWarning;

  /// No description provided for @exitWhileRecording.
  ///
  /// In en, this message translates to:
  /// **'To exit, you must first finish the recording'**
  String get exitWhileRecording;

  /// No description provided for @exitWhileFollowing.
  ///
  /// In en, this message translates to:
  /// **'To exit, you must first finish following the track'**
  String get exitWhileFollowing;

  /// No description provided for @exitWhileRecordingAndFollowing.
  ///
  /// In en, this message translates to:
  /// **'To exit, you must first finish the recording and following the track'**
  String get exitWhileRecordingAndFollowing;

  /// No description provided for @longPressToFinish.
  ///
  /// In en, this message translates to:
  /// **'Long press to finish recording'**
  String get longPressToFinish;

  /// No description provided for @gpsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS disabled'**
  String get gpsDisabledTitle;

  /// No description provided for @gpsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled'**
  String get gpsDisabledMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @recoverTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending route'**
  String get recoverTrackTitle;

  /// No description provided for @recoverTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'A previous recording was not closed properly. Do you want to continue it or start a new one?'**
  String get recoverTrackMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get discard;

  /// No description provided for @recover.
  ///
  /// In en, this message translates to:
  /// **'RECOVER'**
  String get recover;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get exportTitle;

  /// No description provided for @exportMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to export the track now?'**
  String get exportMessage;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'EXPORT'**
  String get export;

  /// No description provided for @importGpxTitle.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get importGpxTitle;

  /// No description provided for @importGpxMessage.
  ///
  /// In en, this message translates to:
  /// **'You already have an active route or loaded data. Do you want to replace it with the GPX file?'**
  String get importGpxMessage;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get import;

  /// No description provided for @viewModeTitle.
  ///
  /// In en, this message translates to:
  /// **'View mode'**
  String get viewModeTitle;

  /// No description provided for @viewModeMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to enter view mode? No new points will be added and recording will be disabled.'**
  String get viewModeMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'ACTIVATE'**
  String get activate;

  /// No description provided for @permissionNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionNeededTitle;

  /// No description provided for @permissionNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'To record the route correctly with the screen off, you must select: 👉 \"Allow always\".'**
  String get permissionNeededMessage;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueLabel;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'The app does not have permission to access location. Do you want to open settings to grant it?'**
  String get locationPermissionMessage;

  /// No description provided for @offTrack.
  ///
  /// In en, this message translates to:
  /// **'You are drifting away from the route'**
  String get offTrack;

  /// No description provided for @backOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You are on the track'**
  String get backOnTrack;

  /// No description provided for @elevationFixing.
  ///
  /// In en, this message translates to:
  /// **'Fixing altitudes'**
  String get elevationFixing;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @gpsRecordByTime.
  ///
  /// In en, this message translates to:
  /// **'Time-based recording'**
  String get gpsRecordByTime;

  /// No description provided for @gpsRecordByDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance-based recording'**
  String get gpsRecordByDistance;

  /// No description provided for @gpsMaxAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Maximum accuracy'**
  String get gpsMaxAccuracy;

  /// No description provided for @gpsRecordingMethod.
  ///
  /// In en, this message translates to:
  /// **'Recording method'**
  String get gpsRecordingMethod;

  /// No description provided for @gpsSignalQuality.
  ///
  /// In en, this message translates to:
  /// **'Signal quality'**
  String get gpsSignalQuality;

  /// No description provided for @gpsDiagnosticMode.
  ///
  /// In en, this message translates to:
  /// **'GPS diagnostic mode'**
  String get gpsDiagnosticMode;

  /// No description provided for @gpsDiagnosticDescription.
  ///
  /// In en, this message translates to:
  /// **'Records detailed telemetry. It may increase battery consumption.'**
  String get gpsDiagnosticDescription;

  /// No description provided for @gpxIncludeExtraData.
  ///
  /// In en, this message translates to:
  /// **'Include extra data in GPX file'**
  String get gpxIncludeExtraData;

  /// No description provided for @gpxAccuracyPerPoint.
  ///
  /// In en, this message translates to:
  /// **'Accuracy per point'**
  String get gpxAccuracyPerPoint;

  /// No description provided for @gpxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get gpxSpeed;

  /// No description provided for @gpxHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get gpxHeading;

  /// No description provided for @gpxSatellites.
  ///
  /// In en, this message translates to:
  /// **'Satellites'**
  String get gpxSatellites;

  /// No description provided for @gpxVerticalAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Vertical accuracy'**
  String get gpxVerticalAccuracy;

  /// No description provided for @gpxSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get gpxSelectAll;

  /// No description provided for @gpxDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get gpxDeselectAll;

  /// No description provided for @switchOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get switchOn;

  /// No description provided for @switchOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get switchOff;

  /// No description provided for @trackColor.
  ///
  /// In en, this message translates to:
  /// **'Track color'**
  String get trackColor;

  /// No description provided for @changeTrackColor.
  ///
  /// In en, this message translates to:
  /// **'CHANGE TRACK COLOR'**
  String get changeTrackColor;

  /// No description provided for @trackWidth.
  ///
  /// In en, this message translates to:
  /// **'Track width'**
  String get trackWidth;

  /// No description provided for @trackPreview.
  ///
  /// In en, this message translates to:
  /// **'Track preview:'**
  String get trackPreview;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickColor;

  /// No description provided for @trackStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Route data'**
  String get trackStatsTitle;

  /// No description provided for @statTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get statTime;

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get statDistance;

  /// No description provided for @statSpeed.
  ///
  /// In en, this message translates to:
  /// **'Current speed'**
  String get statSpeed;

  /// No description provided for @statMaxElevation.
  ///
  /// In en, this message translates to:
  /// **'Maximum altitude'**
  String get statMaxElevation;

  /// No description provided for @statMinElevation.
  ///
  /// In en, this message translates to:
  /// **'Minimum altitude'**
  String get statMinElevation;

  /// No description provided for @statAscent.
  ///
  /// In en, this message translates to:
  /// **'Accumulated ascent +'**
  String get statAscent;

  /// No description provided for @statDescent.
  ///
  /// In en, this message translates to:
  /// **'Accumulated descent -'**
  String get statDescent;

  /// No description provided for @elevationProfile.
  ///
  /// In en, this message translates to:
  /// **'Elevation profile'**
  String get elevationProfile;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @recordingTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get recordingTrack;

  /// No description provided for @importedTrack.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get importedTrack;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get resume;

  /// No description provided for @stopFollowing.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get stopFollowing;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW ROUTE'**
  String get follow;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pause;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get apply;

  /// No description provided for @pendingChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get pendingChangesTitle;

  /// No description provided for @pendingChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to apply them before returning to the map?'**
  String get pendingChangesMessage;

  /// No description provided for @settingsApplied.
  ///
  /// In en, this message translates to:
  /// **'Settings applied!'**
  String get settingsApplied;

  /// No description provided for @gpsTab.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gpsTab;

  /// No description provided for @gpxTab.
  ///
  /// In en, this message translates to:
  /// **'GPX'**
  String get gpxTab;

  /// No description provided for @trackTab.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackTab;

  /// No description provided for @applyUpper.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get applyUpper;

  /// No description provided for @endOfTrack.
  ///
  /// In en, this message translates to:
  /// **'You have reached the end of the track'**
  String get endOfTrack;

  /// No description provided for @reverseTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse direction'**
  String get reverseTrackTitle;

  /// No description provided for @reverseTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'It looks like you are following the track in reverse. Do you want to invert it for better navigation?'**
  String get reverseTrackMessage;

  /// No description provided for @reverseTrackConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, flip it'**
  String get reverseTrackConfirm;

  /// No description provided for @ignoreTrackReverse.
  ///
  /// In en, this message translates to:
  /// **'No, keep it'**
  String get ignoreTrackReverse;

  /// No description provided for @gpxFilenameTitle.
  ///
  /// In en, this message translates to:
  /// **'GPX file name'**
  String get gpxFilenameTitle;

  /// No description provided for @gpxFilenameLabel.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get gpxFilenameLabel;

  /// No description provided for @gpxFilenameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the file name'**
  String get gpxFilenameHint;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get paused;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWING'**
  String get following;

  /// No description provided for @followPaused.
  ///
  /// In en, this message translates to:
  /// **'TRACK PAUSED'**
  String get followPaused;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Ruta'**
  String get track;

  /// No description provided for @followShort.
  ///
  /// In en, this message translates to:
  /// **'Seguir'**
  String get followShort;

  /// No description provided for @followingTitle.
  ///
  /// In en, this message translates to:
  /// **'SEGUIMIENTO'**
  String get followingTitle;

  /// No description provided for @recordingTitle.
  ///
  /// In en, this message translates to:
  /// **'GRABACIÓN'**
  String get recordingTitle;

  /// No description provided for @pauseShort.
  ///
  /// In en, this message translates to:
  /// **'Pausa'**
  String get pauseShort;

  /// No description provided for @stopShort.
  ///
  /// In en, this message translates to:
  /// **'Detener'**
  String get stopShort;

  /// No description provided for @stopFollowingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Following'**
  String get stopFollowingTitle;

  /// No description provided for @stopFollowingMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to stop following? The route will be removed from the map.'**
  String get stopFollowingMessage;

  /// No description provided for @stopFollowingConfirm.
  ///
  /// In en, this message translates to:
  /// **'STOP ROUTE'**
  String get stopFollowingConfirm;

  /// No description provided for @waypointNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Waypoint name'**
  String get waypointNameTitle;

  /// No description provided for @waypointNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get waypointNameHint;

  /// No description provided for @finishRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish recording'**
  String get finishRecordingTitle;

  /// No description provided for @finishRecordingMessage.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do with the current recording?'**
  String get finishRecordingMessage;

  /// No description provided for @finishRecordingConfirm.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get finishRecordingConfirm;

  /// No description provided for @shareTrack.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get shareTrack;

  /// No description provided for @continueRecording.
  ///
  /// In en, this message translates to:
  /// **'Continue recording'**
  String get continueRecording;

  /// No description provided for @deleteTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete track'**
  String get deleteTrackTitle;

  /// No description provided for @deleteTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this route? This action cannot be undone.'**
  String get deleteTrackMessage;

  /// No description provided for @deleteTrackConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteTrackConfirm;

  /// No description provided for @waypointDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Waypoint details'**
  String get waypointDetailsTitle;

  /// No description provided for @waypointName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get waypointName;

  /// No description provided for @waypointAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get waypointAltitude;

  /// No description provided for @waypointTrackPoint.
  ///
  /// In en, this message translates to:
  /// **'Track point'**
  String get waypointTrackPoint;

  /// No description provided for @waypointDistance.
  ///
  /// In en, this message translates to:
  /// **'Accumulated distance'**
  String get waypointDistance;

  /// No description provided for @waypointTime.
  ///
  /// In en, this message translates to:
  /// **'Time elapsed'**
  String get waypointTime;

  /// No description provided for @gpsOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS Optimization'**
  String get gpsOptimizationTitle;

  /// No description provided for @gpsOptimizationMessage.
  ///
  /// In en, this message translates to:
  /// **'For precise tracking, high-fidelity mode will be activated. This may increase battery consumption.'**
  String get gpsOptimizationMessage;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent Android from stopping GPS'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryOptimizationMessage.
  ///
  /// In en, this message translates to:
  /// **'To record without gaps, especially during long stops, sTrack Rec needs to be excluded from battery optimization. Otherwise Android may stop the GPS when the screen is off for a while.'**
  String get batteryOptimizationMessage;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirm;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking Notifications'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'sTrack Rec needs to show a notification while recording your route. This prevents the system from stopping the app to save battery and ensures you don\'t lose your track.'**
  String get notificationPermissionMessage;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'UNDERSTOOD'**
  String get understood;

  /// No description provided for @gpxErrorInvalidExtension.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a GPX file'**
  String get gpxErrorInvalidExtension;

  /// No description provided for @gpxErrorRead.
  ///
  /// In en, this message translates to:
  /// **'The GPX file could not be read'**
  String get gpxErrorRead;

  /// No description provided for @gpxErrorInvalidXml.
  ///
  /// In en, this message translates to:
  /// **'The file does not appear to be valid GPX XML'**
  String get gpxErrorInvalidXml;

  /// No description provided for @gpxErrorNoGpxTag.
  ///
  /// In en, this message translates to:
  /// **'The file contains no GPX data'**
  String get gpxErrorNoGpxTag;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @alarmsDistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get alarmsDistanceTitle;

  /// No description provided for @alarmsDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Meters traveled'**
  String get alarmsDistanceLabel;

  /// No description provided for @alarmsAltitudeTitle.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get alarmsAltitudeTitle;

  /// No description provided for @alarmsAltitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Elevation change (+/-)'**
  String get alarmsAltitudeLabel;

  /// No description provided for @alarmsTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get alarmsTimeTitle;

  /// No description provided for @alarmsTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get alarmsTimeLabel;

  /// No description provided for @alarmsAccSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get alarmsAccSegmentLabel;

  /// No description provided for @alarmsCotaSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get alarmsCotaSegmentLabel;

  /// No description provided for @alarmsCotaValue.
  ///
  /// In en, this message translates to:
  /// **'Alt. {meters} m'**
  String alarmsCotaValue(int meters);

  /// No description provided for @alarmsVolume.
  ///
  /// In en, this message translates to:
  /// **'Alarm volume'**
  String get alarmsVolume;

  /// No description provided for @gpsAutoConfigInfo.
  ///
  /// In en, this message translates to:
  /// **'When following a track or enabling the distance alarm, the GPS automatically adjusts to improve accuracy.'**
  String get gpsAutoConfigInfo;

  /// No description provided for @gpsLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Settings locked: Tracking or Alarm active'**
  String get gpsLockedMessage;

  /// No description provided for @reasonAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm active'**
  String get reasonAlarm;

  /// No description provided for @reasonTrack.
  ///
  /// In en, this message translates to:
  /// **'Tracking in progress'**
  String get reasonTrack;

  /// No description provided for @barometerTitle.
  ///
  /// In en, this message translates to:
  /// **'Barometer'**
  String get barometerTitle;

  /// No description provided for @fusedAltitude.
  ///
  /// In en, this message translates to:
  /// **'Corrected Altitude'**
  String get fusedAltitude;

  /// No description provided for @manualCalibration.
  ///
  /// In en, this message translates to:
  /// **'Manual calibration'**
  String get manualCalibration;

  /// No description provided for @recalibrateGpsDem.
  ///
  /// In en, this message translates to:
  /// **'Recalibrate with GPS/DEM'**
  String get recalibrateGpsDem;

  /// No description provided for @currentGpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Current GPS accuracy'**
  String get currentGpsAccuracy;

  /// No description provided for @insufficientCoverage.
  ///
  /// In en, this message translates to:
  /// **'Insufficient coverage to calibrate properly.'**
  String get insufficientCoverage;

  /// No description provided for @waitingValidAltitude.
  ///
  /// In en, this message translates to:
  /// **'Waiting for valid altitude signal...'**
  String get waitingValidAltitude;

  /// No description provided for @barometerCalibratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Barometer calibrated successfully'**
  String get barometerCalibratedSuccess;

  /// No description provided for @autoCalibrationInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto calibration interval'**
  String get autoCalibrationInterval;

  /// No description provided for @howOften.
  ///
  /// In en, this message translates to:
  /// **'How often?'**
  String get howOften;

  /// No description provided for @barometerExplanation.
  ///
  /// In en, this message translates to:
  /// **'The barometer will automatically recalibrate after this time, provided GPS coverage is good.'**
  String get barometerExplanation;

  /// No description provided for @statDetailRecordingData.
  ///
  /// In en, this message translates to:
  /// **'Recording data'**
  String get statDetailRecordingData;

  /// No description provided for @statDetailRealTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time track'**
  String get statDetailRealTrackSubtitle;

  /// No description provided for @statDetailReferenceData.
  ///
  /// In en, this message translates to:
  /// **'Reference data'**
  String get statDetailReferenceData;

  /// No description provided for @statDetailImportedTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Imported track'**
  String get statDetailImportedTrackSubtitle;

  /// No description provided for @statDetailBackButton.
  ///
  /// In en, this message translates to:
  /// **'BACK TO STATISTICS'**
  String get statDetailBackButton;

  /// No description provided for @statDetailChartTitle.
  ///
  /// In en, this message translates to:
  /// **'{label} PROFILE'**
  String statDetailChartTitle(Object label);

  /// No description provided for @statDetailChartProfile.
  ///
  /// In en, this message translates to:
  /// **'{label} PROFILE'**
  String statDetailChartProfile(String label);

  /// No description provided for @waypointsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Track waypoints'**
  String get waypointsRecorded;

  /// No description provided for @waypointsImported.
  ///
  /// In en, this message translates to:
  /// **'Route waypoints'**
  String get waypointsImported;

  /// No description provided for @noRecordedTrack.
  ///
  /// In en, this message translates to:
  /// **'No track available'**
  String get noRecordedTrack;

  /// No description provided for @usingImportedTrack.
  ///
  /// In en, this message translates to:
  /// **'Showing imported route'**
  String get usingImportedTrack;

  /// No description provided for @statTimeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get statTimeTotal;

  /// No description provided for @statTimeMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving time'**
  String get statTimeMoving;

  /// No description provided for @statTimeStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped time'**
  String get statTimeStopped;

  /// No description provided for @statTimeToWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Time to next waypoint'**
  String get statTimeToWaypoint;

  /// No description provided for @statSpeedCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current speed'**
  String get statSpeedCurrent;

  /// No description provided for @statSpeedAverage.
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get statSpeedAverage;

  /// No description provided for @statSpeedTotal.
  ///
  /// In en, this message translates to:
  /// **'Total average speed'**
  String get statSpeedTotal;

  /// No description provided for @statElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get statElevation;

  /// No description provided for @statElevationCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current elevation'**
  String get statElevationCurrent;

  /// No description provided for @statGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get statGps;

  /// No description provided for @statHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get statHeading;

  /// No description provided for @statSatellites.
  ///
  /// In en, this message translates to:
  /// **'Satellites'**
  String get statSatellites;

  /// No description provided for @statAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get statAccuracy;

  /// No description provided for @satelliteSkyplotTitle.
  ///
  /// In en, this message translates to:
  /// **'Skyplot'**
  String get satelliteSkyplotTitle;

  /// No description provided for @satelliteFlagsMode.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get satelliteFlagsMode;

  /// No description provided for @satelliteGeometryMode.
  ///
  /// In en, this message translates to:
  /// **'Geometries'**
  String get satelliteGeometryMode;

  /// No description provided for @satelliteSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching satellites... Make sure GPS is active outdoors.'**
  String get satelliteSearching;

  /// No description provided for @satelliteNoVisible.
  ///
  /// In en, this message translates to:
  /// **'No visible satellites'**
  String get satelliteNoVisible;

  /// No description provided for @satelliteUtcTime.
  ///
  /// In en, this message translates to:
  /// **'UTC Time'**
  String get satelliteUtcTime;

  /// No description provided for @satelliteFixType.
  ///
  /// In en, this message translates to:
  /// **'Fix Type'**
  String get satelliteFixType;

  /// No description provided for @satelliteFix3dRtk.
  ///
  /// In en, this message translates to:
  /// **'3D/RTK Fix'**
  String get satelliteFix3dRtk;

  /// No description provided for @satelliteNoFix.
  ///
  /// In en, this message translates to:
  /// **'No Fix'**
  String get satelliteNoFix;

  /// No description provided for @satelliteSatellitesInView.
  ///
  /// In en, this message translates to:
  /// **'Satellites in View'**
  String get satelliteSatellitesInView;

  /// No description provided for @satelliteSatellitesInUse.
  ///
  /// In en, this message translates to:
  /// **'Satellites in Use'**
  String get satelliteSatellitesInUse;

  /// No description provided for @satelliteConstellationGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get satelliteConstellationGps;

  /// No description provided for @satelliteConstellationGlonass.
  ///
  /// In en, this message translates to:
  /// **'GLONASS'**
  String get satelliteConstellationGlonass;

  /// No description provided for @satelliteConstellationGalileo.
  ///
  /// In en, this message translates to:
  /// **'GALILEO'**
  String get satelliteConstellationGalileo;

  /// No description provided for @satelliteConstellationBeidou.
  ///
  /// In en, this message translates to:
  /// **'BEIDOU'**
  String get satelliteConstellationBeidou;

  /// No description provided for @deleteWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Delete waypoint'**
  String get deleteWaypoint;

  /// No description provided for @deleteWaypointTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete waypoint?'**
  String get deleteWaypointTitle;

  /// No description provided for @deleteWaypointMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this point of interest permanently?'**
  String get deleteWaypointMessage;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteConfirm;

  /// No description provided for @waypointDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Waypoint successfully deleted'**
  String get waypointDeletedSuccess;

  /// No description provided for @statSpeedMax.
  ///
  /// In en, this message translates to:
  /// **'Max Speed'**
  String get statSpeedMax;

  /// No description provided for @statPaceAverage.
  ///
  /// In en, this message translates to:
  /// **'Average Pace'**
  String get statPaceAverage;

  /// No description provided for @statPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get statPace;

  /// No description provided for @statBarometerPressure.
  ///
  /// In en, this message translates to:
  /// **'Atmospheric pressure'**
  String get statBarometerPressure;

  /// No description provided for @statRangeSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected range'**
  String get statRangeSelectedTitle;

  /// No description provided for @statRangeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statRangeDistance;

  /// No description provided for @statRangeAscent.
  ///
  /// In en, this message translates to:
  /// **'Ascent'**
  String get statRangeAscent;

  /// No description provided for @statRangeDescent.
  ///
  /// In en, this message translates to:
  /// **'Descent'**
  String get statRangeDescent;

  /// No description provided for @statRangeTime.
  ///
  /// In en, this message translates to:
  /// **'Split time'**
  String get statRangeTime;

  /// No description provided for @statPositionDecimal.
  ///
  /// In en, this message translates to:
  /// **'DD Position'**
  String get statPositionDecimal;

  /// No description provided for @statPositionDMS.
  ///
  /// In en, this message translates to:
  /// **'DMS Position'**
  String get statPositionDMS;

  /// No description provided for @demManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'DEM Cell Manager'**
  String get demManagerTitle;

  /// No description provided for @demManagerDesc.
  ///
  /// In en, this message translates to:
  /// **'Strack Rec automatically downloads elevation data when connected. Zoom in on the map to manually save up to 8 zones of 0.2° for offline use.'**
  String get demManagerDesc;

  /// No description provided for @demCellDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Cell downloaded locally'**
  String get demCellDownloaded;

  /// No description provided for @demCellAvailable.
  ///
  /// In en, this message translates to:
  /// **'Cell available to download'**
  String get demCellAvailable;

  /// No description provided for @demDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this cell from disk?'**
  String get demDeleteConfirm;

  /// No description provided for @demLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached. Delete an old cell to download a new one.'**
  String get demLimitReached;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @recordPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recordPaused;

  /// No description provided for @recordStart.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get recordStart;

  /// No description provided for @recordPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recordPause;

  /// No description provided for @recordResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recordResume;

  /// No description provided for @recordStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recordStop;

  /// No description provided for @navigationLoadTrack.
  ///
  /// In en, this message translates to:
  /// **'Load track'**
  String get navigationLoadTrack;

  /// No description provided for @navigationFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get navigationFollow;

  /// No description provided for @navigationFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following...'**
  String get navigationFollowing;

  /// No description provided for @navigationPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get navigationPaused;

  /// No description provided for @navigationStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get navigationStart;

  /// No description provided for @navigationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get navigationCancel;

  /// No description provided for @navigationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get navigationStop;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get menuProfile;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @submenuImportGpx.
  ///
  /// In en, this message translates to:
  /// **'Import GPX'**
  String get submenuImportGpx;

  /// No description provided for @submenuCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get submenuCancel;

  /// No description provided for @submenuStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get submenuStop;

  /// No description provided for @submenuPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get submenuPause;

  /// No description provided for @submenuResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get submenuResume;

  /// No description provided for @submenuFollowingPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get submenuFollowingPause;

  /// No description provided for @submenuFollowingResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get submenuFollowingResume;

  /// No description provided for @submenuFollowingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get submenuFollowingStop;

  /// No description provided for @gpsDisabledAppBar.
  ///
  /// In en, this message translates to:
  /// **'NO GPS'**
  String get gpsDisabledAppBar;

  /// No description provided for @recoverTrackDialogBody.
  ///
  /// In en, this message translates to:
  /// **'An unsaved previous recording has been detected. Do you want to recover it or start a new one from scratch?'**
  String get recoverTrackDialogBody;

  /// No description provided for @waypointNoGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS signal...'**
  String get waypointNoGps;

  /// No description provided for @gpsSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get gpsSearching;

  /// No description provided for @fixStart.
  ///
  /// In en, this message translates to:
  /// **'Start point'**
  String get fixStart;

  /// No description provided for @fixEnd.
  ///
  /// In en, this message translates to:
  /// **'End point'**
  String get fixEnd;

  /// No description provided for @deleteCurrentTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete data?'**
  String get deleteCurrentTrackTitle;

  /// No description provided for @deleteCurrentTrackMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the current track information?'**
  String get deleteCurrentTrackMessage;

  /// No description provided for @deleteCurrentTrackKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP'**
  String get deleteCurrentTrackKeep;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ca', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca': return AppLocalizationsCa();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
