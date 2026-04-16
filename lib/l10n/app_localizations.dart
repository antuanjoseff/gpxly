import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GpxGo'**
  String get appTitle;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
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
  /// **'GPS is disabled. Do you want to enable it now?'**
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
  /// **'SETTINGS'**
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
  /// **'You are drifting away from the imported track'**
  String get offTrack;

  /// No description provided for @backOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You are back on the track'**
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
  /// **'TIME'**
  String get statTime;

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'DIST'**
  String get statDistance;

  /// No description provided for @statSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPEED'**
  String get statSpeed;

  /// No description provided for @statMaxElevation.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get statMaxElevation;

  /// No description provided for @statMinElevation.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get statMinElevation;

  /// No description provided for @statAscent.
  ///
  /// In en, this message translates to:
  /// **'+ASC'**
  String get statAscent;

  /// No description provided for @statDescent.
  ///
  /// In en, this message translates to:
  /// **'-DES'**
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

  /// No description provided for @realTrack.
  ///
  /// In en, this message translates to:
  /// **'Real track'**
  String get realTrack;

  /// No description provided for @importedTrack.
  ///
  /// In en, this message translates to:
  /// **'Imported track'**
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
  /// **'FOLLOW'**
  String get follow;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pause;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ca', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca': return AppLocalizationsCa();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
