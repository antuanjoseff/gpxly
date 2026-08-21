// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Enregistrer';

  @override
  String get stopRecording => 'Arrêter l\'enregistrement';

  @override
  String get gpsDisabled => 'Le GPS est désactivé';

  @override
  String get locationPermissionRequired => 'L\'autorisation de localisation est requise';

  @override
  String get exitWarning => 'Appuyez à nouveau sur retour pour quitter';

  @override
  String get longPressToFinish => 'Maintenez appuyé pour terminer l\'enregistrement';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'ANNULER';

  @override
  String get close => 'FERMER';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Paramètres';

  @override
  String get recoverTrackTitle => 'Itinéraire en attente';

  @override
  String get recoverTrackMessage => 'Un enregistrement qui n\'a pas été correctement terminé a été détecté. Voulez-vous le reprendre ou en commencer un nouveau ?';

  @override
  String get discard => 'SUPPRIMER';

  @override
  String get recover => 'RÉCUPÉRER';

  @override
  String get exportTitle => 'Exporter le GPX';

  @override
  String get exportMessage => 'Voulez-vous exporter la trace maintenant ?';

  @override
  String get export => 'EXPORTER';

  @override
  String get importGpxTitle => 'Importer un GPX';

  @override
  String get importGpxMessage => 'Un itinéraire est déjà actif ou des données sont chargées. Voulez-vous les remplacer par le fichier GPX ?';

  @override
  String get import => 'IMPORTER';

  @override
  String get viewModeTitle => 'Mode visualisation';

  @override
  String get viewModeMessage => 'Voulez-vous passer en mode visualisation ? Aucun nouveau point ne sera ajouté et l\'enregistrement sera désactivé.';

  @override
  String get no => 'NON';

  @override
  String get activate => 'ACTIVER';

  @override
  String get permissionNeededTitle => 'Autorisation requise';

  @override
  String get permissionNeededMessage => 'Pour enregistrer correctement l\'itinéraire lorsque l\'écran est éteint, vous devez sélectionner : 👉 \"Toujours autoriser\".';

  @override
  String get continueLabel => 'CONTINUER';

  @override
  String get locationPermissionTitle => 'Autorisation de localisation';

  @override
  String get locationPermissionMessage => 'L\'application n\'est pas autorisée à accéder à votre position. Voulez-vous ouvrir les paramètres pour accorder l\'autorisation ?';

  @override
  String get offTrack => 'Vous vous éloignez de l\'itinéraire';

  @override
  String get backOnTrack => 'Vous êtes sur la trace';

  @override
  String get elevationFixing => 'Correction des altitudes';

  @override
  String get error => 'Erreur';

  @override
  String get gpsRecordByTime => 'Enregistrement par durée';

  @override
  String get gpsRecordByDistance => 'Enregistrement par distance';

  @override
  String get gpsMaxAccuracy => 'Précision maximale';

  @override
  String get gpsRecordingMethod => 'Méthode d\'enregistrement';

  @override
  String get gpsSignalQuality => 'Qualité du signal';

  @override
  String get gpsDiagnosticMode => 'Mode diagnostic GPS';

  @override
  String get gpsDiagnosticDescription => 'Enregistre des données de télémétrie détaillées. Cela peut augmenter la consommation de batterie.';

  @override
  String get gpxIncludeExtraData => 'Inclure des données supplémentaires dans le fichier GPX';

  @override
  String get gpxAccuracyPerPoint => 'Précision par point';

  @override
  String get gpxSpeed => 'Vitesse';

  @override
  String get gpxHeading => 'Cap';

  @override
  String get gpxSatellites => 'Satellites';

  @override
  String get gpxVerticalAccuracy => 'Précision verticale';

  @override
  String get gpxSelectAll => 'Tout sélectionner';

  @override
  String get gpxDeselectAll => 'Tout désélectionner';

  @override
  String get switchOn => 'ACTIVÉ';

  @override
  String get switchOff => 'DÉSACTIVÉ';

  @override
  String get trackColor => 'Couleur de la trace';

  @override
  String get changeTrackColor => 'MODIFIER LA COULEUR DE LA TRACE';

  @override
  String get trackWidth => 'Épaisseur de la trace';

  @override
  String get trackPreview => 'Aperçu de la trace :';

  @override
  String get pickColor => 'Choisir une couleur';

  @override
  String get trackStatsTitle => 'Données de l\'itinéraire';

  @override
  String get statTime => 'Temps total';

  @override
  String get statDistance => 'Distance totale';

  @override
  String get statSpeed => 'Vitesse actuelle';

  @override
  String get statMaxElevation => 'Altitude maximale';

  @override
  String get statMinElevation => 'Altitude minimale';

  @override
  String get statAscent => 'Dénivelé positif cumulé';

  @override
  String get statDescent => 'Dénivelé négatif cumulé';

  @override
  String get elevationProfile => 'Profil d\'altitude';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get recordingTrack => 'Trace';

  @override
  String get importedTrack => 'Itinéraire';

  @override
  String get resume => 'REPRENDRE';

  @override
  String get stopFollowing => 'ARRÊTER';

  @override
  String get follow => 'SUIVRE L\'ITINÉRAIRE';

  @override
  String get pause => 'PAUSE';

  @override
  String get apply => 'APPLIQUER';

  @override
  String get pendingChangesTitle => 'Modifications en attente';

  @override
  String get pendingChangesMessage => 'Vous avez effectué des modifications qui n\'ont pas été appliquées. Voulez-vous les appliquer avant de revenir à la carte ?';

  @override
  String get settingsApplied => 'Paramètres appliqués !';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Trace';

  @override
  String get applyUpper => 'APPLIQUER';

  @override
  String get endOfTrack => 'Vous êtes arrivé à la fin de la trace';

  @override
  String get reverseTrackTitle => 'Sens inverse';

  @override
  String get reverseTrackMessage => 'Il semble que vous suiviez la trace dans le sens inverse. Voulez-vous l\'inverser pour améliorer la navigation ?';

  @override
  String get reverseTrackConfirm => 'Oui, inverser';

  @override
  String get ignoreTrackReverse => 'Continuer';

  @override
  String get gpxFilenameTitle => 'Nom du fichier GPX';

  @override
  String get gpxFilenameLabel => 'Nom du fichier';

  @override
  String get gpxFilenameHint => 'Saisissez le nom du fichier';

  @override
  String get recording => 'Enregistrement...';

  @override
  String get paused => 'EN PAUSE';

  @override
  String get following => 'SUIVI EN COURS';

  @override
  String get followPaused => 'ITINÉRAIRE EN PAUSE';

  @override
  String get track => 'Itinéraire';

  @override
  String get followShort => 'Suivre';

  @override
  String get followingTitle => 'SUIVI';

  @override
  String get recordingTitle => 'ENREGISTREMENT';

  @override
  String get pauseShort => 'Pause';

  @override
  String get stopShort => 'Arrêter';

  @override
  String get stopFollowingTitle => 'Arrêter le suivi';

  @override
  String get stopFollowingMessage => 'Voulez-vous arrêter le suivi ? L\'itinéraire sera retiré de la carte.';

  @override
  String get stopFollowingConfirm => 'ARRÊTER LE SUIVI';

  @override
  String get waypointNameTitle => 'Nom du point de passage';

  @override
  String get waypointNameHint => 'Saisissez un nom';

  @override
  String get finishRecordingTitle => 'Terminer l\'enregistrement';

  @override
  String get finishRecordingMessage => 'Que voulez-vous faire avec l\'enregistrement actuel ?';

  @override
  String get finishRecordingConfirm => 'TERMINER';

  @override
  String get shareTrack => 'PARTAGER';

  @override
  String get continueRecording => 'Continuer l\'enregistrement';

  @override
  String get deleteTrackTitle => 'Supprimer la trace';

  @override
  String get deleteTrackMessage => 'Voulez-vous vraiment supprimer cet itinéraire ? Cette action est irréversible.';

  @override
  String get deleteTrackConfirm => 'SUPPRIMER';

  @override
  String get waypointDetailsTitle => 'Détails du point de passage';

  @override
  String get waypointName => 'Nom';

  @override
  String get waypointAltitude => 'Altitude';

  @override
  String get waypointTrackPoint => 'Point de l\'itinéraire';

  @override
  String get waypointDistance => 'Distance cumulée';

  @override
  String get waypointTime => 'Temps de passage';

  @override
  String get gpsOptimizationTitle => 'Optimisation du GPS';

  @override
  String get gpsOptimizationMessage => 'Pour un suivi précis, il est nécessaire d\'activer le mode haute précision. Cela peut augmenter la consommation de batterie.';

  @override
  String get batteryOptimizationTitle => 'Empêcher Android d\'arrêter le GPS';

  @override
  String get batteryOptimizationMessage => 'Pour enregistrer sans coupures, surtout lors d\'arrêts prolongés, Senda doit être exclue de l\'optimisation de la batterie. Sinon, Android peut arrêter le GPS lorsque l\'écran est éteint un moment.';

  @override
  String get confirm => 'CONFIRMER';

  @override
  String get notificationPermissionTitle => 'Notifications de suivi';

  @override
  String get notificationPermissionMessage => 'Senda doit afficher une notification pendant l\'enregistrement de l\'itinéraire. Cela empêche le système d\'arrêter l\'application pour économiser la batterie et garantit que vous ne perdrez pas votre trace.';

  @override
  String get understood => 'COMPRIS';

  @override
  String get gpxErrorInvalidExtension => 'Le fichier sélectionné n\'est pas un fichier GPX';

  @override
  String get gpxErrorRead => 'Impossible de lire le fichier GPX';

  @override
  String get gpxErrorInvalidXml => 'Le fichier ne semble pas être un fichier XML GPX valide';

  @override
  String get gpxErrorNoGpxTag => 'Le fichier ne contient pas de données GPX';

  @override
  String get alarms => 'Alertes';

  @override
  String get alarmsDistanceTitle => 'Distance';

  @override
  String get alarmsDistanceLabel => 'Mètres parcourus';

  @override
  String get alarmsAltitudeTitle => 'Altitude';

  @override
  String get alarmsAltitudeLabel => 'Mètres de dénivelé (+/-)';

  @override
  String get alarmsTimeTitle => 'Temps';

  @override
  String get alarmsTimeLabel => 'Secondes';

  @override
  String get alarmsAccSegmentLabel => 'Dénivelé';

  @override
  String get alarmsCotaSegmentLabel => 'Altitudes';

  @override
  String alarmsCotaValue(int meters) {
    return 'Alt. $meters m';
  }

  @override
  String get gpsAutoConfigInfo => 'Lorsque vous suivez une trace ou activez l\'alerte de distance, le GPS se configure automatiquement pour améliorer la précision.';

  @override
  String get gpsLockedMessage => 'Configuration verrouillée : suivi ou alerte active';

  @override
  String get reasonAlarm => 'Alerte active';

  @override
  String get reasonTrack => 'Suivi en cours';

  @override
  String get barometerTitle => 'Baromètre';

  @override
  String get fusedAltitude => 'Altitude corrigée';

  @override
  String get manualCalibration => 'Étalonnage manuel';

  @override
  String get recalibrateGpsDem => 'Réétalonner avec GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Précision GPS actuelle';

  @override
  String get insufficientCoverage => 'Couverture insuffisante pour effectuer un étalonnage correct.';

  @override
  String get waitingValidAltitude => 'En attente d\'un signal d\'altitude valide...';

  @override
  String get barometerCalibratedSuccess => 'Baromètre étalonné avec succès';

  @override
  String get autoCalibrationInterval => 'Intervalle d\'étalonnage automatique';

  @override
  String get howOften => 'À quelle fréquence ?';

  @override
  String get barometerExplanation => 'Le baromètre sera automatiquement réétalonné à chaque fois que cet intervalle sera écoulé, à condition que la couverture GPS soit bonne.';

  @override
  String get statDetailRecordingData => 'Données de l\'enregistrement';

  @override
  String get statDetailRealTrackSubtitle => 'Trace en temps réel';

  @override
  String get statDetailReferenceData => 'Données de référence';

  @override
  String get statDetailImportedTrackSubtitle => 'Itinéraire';

  @override
  String get statDetailBackButton => 'RETOUR AUX STATISTIQUES';

  @override
  String statDetailChartTitle(Object label) {
    return 'PROFIL DE $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PROFIL DE $label';
  }

  @override
  String get waypointsRecorded => 'Points de passage de la trace';

  @override
  String get waypointsImported => 'Points de passage de l\'itinéraire';

  @override
  String get noRecordedTrack => 'Aucune trace disponible';

  @override
  String get usingImportedTrack => 'Affichage de l\'itinéraire importé';

  @override
  String get statTimeTotal => 'Temps total';

  @override
  String get statTimeMoving => 'Temps en mouvement';

  @override
  String get statTimeStopped => 'Temps à l\'arrêt';

  @override
  String get statSpeedCurrent => 'Vitesse actuelle';

  @override
  String get statSpeedAverage => 'Vitesse moyenne';

  @override
  String get statSpeedTotal => 'Vitesse moyenne totale';

  @override
  String get statElevation => 'Altitude';

  @override
  String get statElevationCurrent => 'Altitude actuelle';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Cap';

  @override
  String get statSatellites => 'Satellites';

  @override
  String get statAccuracy => 'Précision';

  @override
  String get satelliteSkyplotTitle => 'Carte du ciel';

  @override
  String get satelliteFlagsMode => 'Indicateurs';

  @override
  String get satelliteGeometryMode => 'Géométries';

  @override
  String get satelliteSearching => 'Recherche de satellites... Assurez-vous que le GPS est activé et que vous êtes à l\'extérieur.';

  @override
  String get satelliteNoVisible => 'Aucun satellite visible';

  @override
  String get satelliteUtcTime => 'Heure UTC';

  @override
  String get satelliteFixType => 'Type de positionnement';

  @override
  String get satelliteFix3dRtk => 'Positionnement 3D/RTK';

  @override
  String get satelliteNoFix => 'Aucun positionnement';

  @override
  String get satelliteSatellitesInView => 'Satellites visibles';

  @override
  String get satelliteSatellitesInUse => 'Satellites utilisés';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Supprimer le point de passage';

  @override
  String get deleteWaypointTitle => 'Supprimer le point de passage ?';

  @override
  String get deleteWaypointMessage => 'Voulez-vous vraiment supprimer définitivement ce point d\'intérêt ?';

  @override
  String get deleteConfirm => 'SUPPRIMER';

  @override
  String get waypointDeletedSuccess => 'Point de passage supprimé avec succès';

  @override
  String get statSpeedMax => 'Vitesse maximale';

  @override
  String get statPaceAverage => 'Allure moyenne';

  @override
  String get statPace => 'Allure';

  @override
  String get statBarometerPressure => 'Pression atmosphérique';

  @override
  String get statRangeSelectedTitle => 'Intervalle sélectionné';

  @override
  String get statRangeDistance => 'Distance';

  @override
  String get statRangeAscent => 'Dénivelé +';

  @override
  String get statRangeDescent => 'Dénivelé -';

  @override
  String get statRangeTime => 'Temps du tronçon';

  @override
  String get statPositionDecimal => 'Position DD';

  @override
  String get statPositionDMS => 'Position DMS';

  @override
  String get demManagerTitle => 'Gestionnaire de cellules DEM';

  @override
  String get demManagerDesc => 'Strack Rec télécharge automatiquement l\'altitude lorsque la couverture est disponible. Zoomez sur la carte pour enregistrer manuellement jusqu\'à 8 zones de 0,2° afin de les utiliser hors ligne.';

  @override
  String get demCellDownloaded => 'Cellule téléchargée localement';

  @override
  String get demCellAvailable => 'Cellule disponible au téléchargement';

  @override
  String get demDeleteConfirm => 'Voulez-vous supprimer cette cellule du disque ?';

  @override
  String get demLimitReached => 'Limite atteinte. Supprimez une ancienne cellule pour en télécharger une nouvelle.';

  @override
  String get record => 'Enregistrer';

  @override
  String get recordPaused => 'En pause';

  @override
  String get recordStart => 'Démarrer l\'enregistrement';

  @override
  String get recordPause => 'Mettre en pause';

  @override
  String get recordResume => 'Reprendre';

  @override
  String get recordStop => 'Terminer';

  @override
  String get navigationLoadTrack => 'Charger une trace';

  @override
  String get navigationFollow => 'Suivre';

  @override
  String get navigationFollowing => 'Suivi en cours...';

  @override
  String get navigationPaused => 'En pause';

  @override
  String get navigationStart => 'Démarrer';

  @override
  String get navigationCancel => 'Annuler';

  @override
  String get navigationStop => 'Terminer';

  @override
  String get menuProfile => 'Profil';

  @override
  String get menuSettings => 'Paramètres';

  @override
  String get submenuImportGpx => 'Importer un GPX';

  @override
  String get submenuCancel => 'Annuler';

  @override
  String get submenuStop => 'Terminer';

  @override
  String get submenuPause => 'Mettre en pause';

  @override
  String get submenuResume => 'Reprendre';

  @override
  String get submenuFollowingPause => 'Mettre en pause';

  @override
  String get submenuFollowingResume => 'Reprendre';

  @override
  String get submenuFollowingStop => 'Terminer';

  @override
  String get gpsDisabledAppBar => 'SANS GPS';

  @override
  String get recoverTrackDialogBody => 'Des données d\'un itinéraire précédent non enregistré ont été détectées. Voulez-vous les récupérer ou préférez-vous repartir de zéro avec un nouvel itinéraire ?';

  @override
  String get waypointNoGps => 'En attente du signal GPS...';

  @override
  String get gpsSearching => 'Recherche...';

  @override
  String get fixStart => 'Point de départ';

  @override
  String get fixEnd => 'Point d\'arrivée';

  @override
  String get deleteCurrentTrackTitle => 'Supprimer les données ?';

  @override
  String get deleteCurrentTrackMessage => 'Voulez-vous supprimer les données actuelles de la trace ?';

  @override
  String get deleteCurrentTrackKeep => 'CONSERVER';
}
