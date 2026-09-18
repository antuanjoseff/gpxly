// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'STRec';

  @override
  String get startRecording => 'Gravar';

  @override
  String get stopRecording => 'Parar gravação';

  @override
  String get gpsDisabled => 'O GPS está desativado';

  @override
  String get locationPermissionRequired => 'É necessário aceitar as permissões de localização';

  @override
  String get exitWarning => 'Prima novamente para sair';

  @override
  String get exitWhileRecording => 'Para sair, é necessário terminar primeiro a gravação';

  @override
  String get exitWhileFollowing => 'Para sair, é necessário terminar primeiro o seguimento';

  @override
  String get exitWhileRecordingAndFollowing => 'Para sair, é necessário terminar primeiro a gravação e o seguimento';

  @override
  String get longPressToFinish => 'Mantenha premido para terminar a gravação';

  @override
  String get gpsDisabledTitle => 'GPS';

  @override
  String get gpsDisabledMessage => 'GPS';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get close => 'FECHAR';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'Definições';

  @override
  String get recoverTrackTitle => 'Rota pendente';

  @override
  String get recoverTrackMessage => 'Foi detetada uma gravação que não foi encerrada corretamente. Quer continuar ou começar uma nova?';

  @override
  String get discard => 'DESCARTAR';

  @override
  String get recover => 'RECUPERAR';

  @override
  String get exportTitle => 'Exportar GPX';

  @override
  String get exportMessage => 'Quer exportar o track agora?';

  @override
  String get export => 'EXPORTAR';

  @override
  String get importGpxTitle => 'Importar GPX';

  @override
  String get importGpxMessage => 'Já tem uma rota ativa ou dados carregados. Quer substituí-los pelo ficheiro GPX?';

  @override
  String get import => 'IMPORTAR';

  @override
  String get viewModeTitle => 'Modo de visualização';

  @override
  String get viewModeMessage => 'Quer entrar no modo de visualização? Não serão adicionados novos pontos e a gravação ficará desativada.';

  @override
  String get no => 'NÃO';

  @override
  String get activate => 'ATIVAR';

  @override
  String get permissionNeededTitle => 'Permissão necessária';

  @override
  String get continueLabel => 'CONTINUAR';

  @override
  String get locationPermissionTitle => 'Permissão de localização';

  @override
  String get locationPermissionMessage => 'A aplicação não tem permissão para aceder à localização. Quer abrir as definições para conceder a permissão?';

  @override
  String get offTrack => 'Está a afastar-se da rota';

  @override
  String get backOnTrack => 'Está no track';

  @override
  String get elevationFixing => 'A corrigir altitudes';

  @override
  String get error => 'Erro';

  @override
  String get gpsRecordByTime => 'Gravação por tempo';

  @override
  String get gpsRecordByDistance => 'Gravação por distância';

  @override
  String get gpsMaxAccuracy => 'Precisão máxima';

  @override
  String get gpsRecordingMethod => 'Método de registo';

  @override
  String get gpsSignalQuality => 'Qualidade do sinal';

  @override
  String get gpsDiagnosticMode => 'Modo de diagnóstico GPS';

  @override
  String get gpsDiagnosticDescription => 'Regista telemetria detalhada. Pode aumentar o consumo da bateria.';

  @override
  String get gpxIncludeExtraData => 'Incluir dados extra no ficheiro GPX';

  @override
  String get gpxAccuracyPerPoint => 'Precisão por ponto';

  @override
  String get gpxSpeed => 'Velocidade';

  @override
  String get gpxHeading => 'Rumo';

  @override
  String get gpxSatellites => 'Satélites';

  @override
  String get gpxVerticalAccuracy => 'Precisão vertical';

  @override
  String get gpxSelectAll => 'Selecionar tudo';

  @override
  String get gpxDeselectAll => 'Desmarcar tudo';

  @override
  String get gpxSaveTrack => 'Guardar o track agora';

  @override
  String get gpxTrackSaved => 'Track guardado';

  @override
  String get switchOn => 'ATIVADO';

  @override
  String get switchOff => 'DESATIVADO';

  @override
  String get trackColor => 'Cor do track';

  @override
  String get changeTrackColor => 'ALTERAR A COR DO TRAÇADO';

  @override
  String get trackWidth => 'Espessura do traçado';

  @override
  String get trackPreview => 'Pré-visualização do traçado:';

  @override
  String get pickColor => 'Escolha uma cor';

  @override
  String get trackStatsTitle => 'Dados da rota';

  @override
  String get statTime => 'Tempo total';

  @override
  String get statDistance => 'Distância total';

  @override
  String get statSpeed => 'Velocidade atual';

  @override
  String get statMaxElevation => 'Cota máxima';

  @override
  String get statMinElevation => 'Cota mínima';

  @override
  String get statAscent => 'Desnível acumulado +';

  @override
  String get statDescent => 'Desnível acumulado -';

  @override
  String get mapStatDistance => 'DIST.';

  @override
  String get mapStatRemaining => 'REST.';

  @override
  String get mapStatTime => 'TEMPO';

  @override
  String get mapStatMoving => 'MOV.';

  @override
  String get mapStatStopped => 'PAR.';

  @override
  String get mapStatWaypoint => 'PONTO';

  @override
  String get mapStatSpeed => 'VEL.';

  @override
  String get mapStatSpeedAvg => 'MÉD.';

  @override
  String get mapStatSpeedTotal => 'TOTAL';

  @override
  String get mapStatSpeedMax => 'MÁX.';

  @override
  String get mapStatPace => 'RITMO';

  @override
  String get mapStatPaceAvg => 'RITMO M.';

  @override
  String get mapStatAltitude => 'COTA';

  @override
  String get mapStatAltMax => 'COTA MÁX.';

  @override
  String get mapStatAltMin => 'COTA MÍN.';

  @override
  String get mapStatAscent => 'SUBIDA';

  @override
  String get mapStatDescent => 'DESCIDA';

  @override
  String get mapStatPosition => 'POS.';

  @override
  String get mapStatPositionDms => 'POS. DMS';

  @override
  String get mapStatPressure => 'PRESS.';

  @override
  String get mapStatGps => 'GPS';

  @override
  String get mapStatGpsAccuracy => 'PRECISÃO GPS';

  @override
  String get statRemaining => 'Restante';

  @override
  String get elevationProfile => 'Perfil de elevação';

  @override
  String get noData => 'Sem dados';

  @override
  String get recordingTrack => 'Track';

  @override
  String get importedTrack => 'Rota';

  @override
  String get resume => 'RETOMAR';

  @override
  String get stopFollowing => 'PARAR';

  @override
  String get follow => 'SEGUIR ROTA';

  @override
  String get pause => 'PAUSA';

  @override
  String get apply => 'APLICAR';

  @override
  String get pendingChangesTitle => 'Alterações pendentes';

  @override
  String get pendingChangesMessage => 'Fez alterações que não aplicou. Quer aplicá-las antes de voltar ao mapa?';

  @override
  String get settingsApplied => 'Definições aplicadas!';

  @override
  String get gpsTab => 'GPS';

  @override
  String get gpxTab => 'GPX';

  @override
  String get trackTab => 'Track';

  @override
  String get applyUpper => 'APLICAR';

  @override
  String get endOfTrack => 'Chegou ao fim do track';

  @override
  String get reverseTrackTitle => 'Direção inversa';

  @override
  String get reverseTrackMessage => 'Parece que está a seguir o track na direção inversa. Quer invertê-lo para melhorar a navegação?';

  @override
  String get reverseTrackConfirm => 'Sim, inverter';

  @override
  String get ignoreTrackReverse => 'Continuar';

  @override
  String get gpxFilenameTitle => 'Nome do ficheiro GPX';

  @override
  String get gpxFilenameLabel => 'Nome do ficheiro';

  @override
  String get gpxFilenameHint => 'Introduza o nome do ficheiro';

  @override
  String get recording => 'A gravar...';

  @override
  String get paused => 'PAUSADO';

  @override
  String get following => 'A SEGUIR';

  @override
  String get followPaused => 'ROTA EM PAUSA';

  @override
  String get track => 'Rota';

  @override
  String get followShort => 'Seguir';

  @override
  String get followingTitle => 'SEGUIMENTO';

  @override
  String get recordingTitle => 'GRAVAÇÃO';

  @override
  String get pauseShort => 'Pausa';

  @override
  String get stopShort => 'Parar';

  @override
  String get stopFollowingTitle => 'Parar seguimento';

  @override
  String get stopFollowingMessage => 'Quer parar o seguimento? A rota será removida do mapa.';

  @override
  String get stopFollowingConfirm => 'PARAR ROTA';

  @override
  String get waypointNameTitle => 'Nome do waypoint';

  @override
  String get waypointNameHint => 'Introduza um nome';

  @override
  String get finishRecordingTitle => 'Terminar gravação';

  @override
  String get finishRecordingMessage => 'O que quer fazer com a gravação atual?';

  @override
  String get finishRecordingConfirm => 'TERMINAR';

  @override
  String get shareTrack => 'PARTILHAR';

  @override
  String get continueRecording => 'Continuar a gravar';

  @override
  String get deleteTrackTitle => 'Eliminar track';

  @override
  String get deleteTrackMessage => 'Tem a certeza de que quer eliminar esta rota? Esta ação não pode ser anulada.';

  @override
  String get deleteTrackConfirm => 'ELIMINAR';

  @override
  String get waypointDetailsTitle => 'Detalhes do waypoint';

  @override
  String get waypointName => 'Nome';

  @override
  String get waypointAltitude => 'Altitude';

  @override
  String get waypointTrackPoint => 'Ponto da rota';

  @override
  String get waypointDistance => 'Distância acumulada';

  @override
  String get waypointTime => 'Tempo de passagem';

  @override
  String get gpsOptimizationTitle => 'Otimização GPS';

  @override
  String get gpsOptimizationMessage => 'Para um seguimento preciso, é necessário ativar o modo de alta fidelidade. Isto pode aumentar o consumo da bateria.';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get notificationPermissionTitle => 'Notificações de seguimento';

  @override
  String get understood => 'ENTENDIDO';

  @override
  String get permissionNeededMessage => 'Esta aplicação requer que selecione a opção \'Permitir sempre\' para poder recolher os dados de localização durante a execução da aplicação. Isto permite registar e seguir as suas rotas em tempo real, mesmo quando a aplicação está minimizada ou em segundo plano.';

  @override
  String get notificationPermissionMessage => 'Esta aplicação executa um serviço em primeiro plano para garantir um seguimento GPS contínuo enquanto regista a sua rota. Será apresentada uma notificação persistente para o informar de que a aplicação está a recolher dados de localização ativamente, evitando que o sistema interrompa a sua viagem.';

  @override
  String get gpxErrorInvalidExtension => 'O ficheiro selecionado não é um GPX';

  @override
  String get gpxErrorRead => 'Não foi possível ler o ficheiro GPX';

  @override
  String get gpxErrorInvalidXml => 'O ficheiro não parece ser um XML GPX válido';

  @override
  String get gpxErrorNoGpxTag => 'O ficheiro não contém dados GPX';

  @override
  String get alarms => 'Alarmes';

  @override
  String get alarmsDistanceTitle => 'Distância';

  @override
  String get alarmsDistanceLabel => 'Metros percorridos';

  @override
  String get alarmsAltitudeTitle => 'Altitude';

  @override
  String get alarmsAltitudeLabel => 'Metros de desnível (+/-)';

  @override
  String get alarmsTimeTitle => 'Tempo';

  @override
  String get alarmsTimeLabel => 'Segundos';

  @override
  String get alarmsAccSegmentLabel => 'Desnível';

  @override
  String get alarmsCotaSegmentLabel => 'Cotas';

  @override
  String alarmsCotaValue(int meters) {
    return 'Cota $meters m';
  }

  @override
  String get alarmsVolume => 'Volume dos alarmes';

  @override
  String get gpsAutoConfigInfo => 'Quando segue um track ou ativa o alarme por distância, o GPS é configurado automaticamente para melhorar a precisão.';

  @override
  String get gpsLockedMessage => 'Configuração bloqueada: Seguimento ou Alarme ativo';

  @override
  String get reasonAlarm => 'Alarme ativo';

  @override
  String get reasonTrack => 'Seguimento em curso';

  @override
  String get barometerTitle => 'Barómetro';

  @override
  String get fusedAltitude => 'Altitude corrigida';

  @override
  String get manualCalibration => 'Calibração manual';

  @override
  String get recalibrateGpsDem => 'Recalibrar com GPS/DEM';

  @override
  String get currentGpsAccuracy => 'Precisão GPS atual';

  @override
  String get insufficientCoverage => 'Cobertura insuficiente para calibrar corretamente.';

  @override
  String get waitingValidAltitude => 'A aguardar sinal de altitude válido...';

  @override
  String get barometerCalibratedSuccess => 'Barómetro calibrado com sucesso';

  @override
  String get autoCalibrationInterval => 'Intervalo de calibração automática';

  @override
  String get howOften => 'Com que frequência?';

  @override
  String get barometerExplanation => 'O barómetro será recalibrado automaticamente sempre que este período de tempo passar, desde que a cobertura GPS seja boa.';

  @override
  String get statDetailRecordingData => 'Dados da gravação';

  @override
  String get statDetailRealTrackSubtitle => 'Track em tempo real';

  @override
  String get statDetailReferenceData => 'Dados de referência';

  @override
  String get statDetailImportedTrackSubtitle => 'Rota';

  @override
  String get statDetailBackButton => 'VOLTAR ÀS ESTATÍSTICAS';

  @override
  String statDetailChartTitle(Object label) {
    return 'PERFIL DE $label';
  }

  @override
  String statDetailChartProfile(String label) {
    return 'PERFIL DE $label';
  }

  @override
  String get waypointsRecorded => 'Waypoints do track';

  @override
  String get waypointsImported => 'Waypoints da rota';

  @override
  String get noRecordedTrack => 'Não existe nenhum track disponível';

  @override
  String get usingImportedTrack => 'A mostrar a rota importada';

  @override
  String get statTimeTotal => 'Tempo total';

  @override
  String get statTimeMoving => 'Tempo em movimento';

  @override
  String get statTimeStopped => 'Tempo parado';

  @override
  String get statTimeToWaypoint => 'Tempo até ao waypoint';

  @override
  String get statSpeedCurrent => 'Velocidade atual';

  @override
  String get statSpeedAverage => 'Velocidade média';

  @override
  String get statSpeedTotal => 'Velocidade média total';

  @override
  String get statElevation => 'Altitude';

  @override
  String get statElevationCurrent => 'Altitude atual';

  @override
  String get statGps => 'GPS';

  @override
  String get statHeading => 'Rumo';

  @override
  String get statSatellites => 'Satélites';

  @override
  String get statAccuracy => 'Precisão';

  @override
  String get satelliteSkyplotTitle => 'Carta do céu';

  @override
  String get satelliteFlagsMode => 'Bandeiras';

  @override
  String get satelliteGeometryMode => 'Geometrias';

  @override
  String get satelliteSearching => 'A procurar satélites... Certifique-se de que tem o GPS ativo e está no exterior.';

  @override
  String get satelliteNoVisible => 'Sem satélites visíveis';

  @override
  String get satelliteUtcTime => 'Hora UTC';

  @override
  String get satelliteFixType => 'Tipo de fix';

  @override
  String get satelliteFix3dRtk => 'Fix 3D/RTK';

  @override
  String get satelliteNoFix => 'Sem fix';

  @override
  String get satelliteSatellitesInView => 'Satélites à vista';

  @override
  String get satelliteSatellitesInUse => 'Satélites em utilização';

  @override
  String get satelliteConstellationGps => 'GPS';

  @override
  String get satelliteConstellationGlonass => 'GLONASS';

  @override
  String get satelliteConstellationGalileo => 'GALILEO';

  @override
  String get satelliteConstellationBeidou => 'BEIDOU';

  @override
  String get deleteWaypoint => 'Eliminar ponto';

  @override
  String get deleteWaypointTitle => 'Eliminar ponto?';

  @override
  String get deleteWaypointMessage => 'Tem a certeza de que quer eliminar definitivamente este ponto de interesse?';

  @override
  String get deleteConfirm => 'ELIMINAR';

  @override
  String get waypointDeletedSuccess => 'Ponto eliminado com sucesso';

  @override
  String get statSpeedMax => 'Velocidade máxima';

  @override
  String get statPaceAverage => 'Ritmo médio';

  @override
  String get statPace => 'Ritmo';

  @override
  String get statBarometerPressure => 'Pressão atmosférica';

  @override
  String get statRangeSelectedTitle => 'Intervalo selecionado';

  @override
  String get statRangeDistance => 'Distância';

  @override
  String get statRangeAscent => 'Desnível +';

  @override
  String get statRangeDescent => 'Desnível -';

  @override
  String get statRangeTime => 'Tempo do troço';

  @override
  String get statPositionDecimal => 'Posição GD';

  @override
  String get statPositionDMS => 'Posição DMS';

  @override
  String get demManagerTitle => 'Gestor de Células DEM';

  @override
  String get demManagerDesc => 'O Strack Rec descarrega automaticamente a altitude quando existe cobertura. Aproxime-se do mapa para guardar manualmente até 8 zonas de 0,2° para utilizar offline.';

  @override
  String get demCellDownloaded => 'Célula descarregada localmente';

  @override
  String get demCellAvailable => 'Célula disponível para descarregar';

  @override
  String get demDeleteConfirm => 'Quer eliminar esta célula do disco?';

  @override
  String get demLimitReached => 'Limite atingido. Elimine uma célula antiga para descarregar uma nova.';

  @override
  String get record => 'Gravar';

  @override
  String get recordPaused => 'Pausado';

  @override
  String get recordStart => 'Iniciar gravação';

  @override
  String get recordPause => 'Pausar';

  @override
  String get recordResume => 'Retomar';

  @override
  String get recordStop => 'Terminar';

  @override
  String get navigationLoadTrack => 'Carregar track';

  @override
  String get navigationFollow => 'Seguir';

  @override
  String get navigationFollowing => 'A seguir...';

  @override
  String get navigationPaused => 'Pausado';

  @override
  String get navigationStart => 'Iniciar';

  @override
  String get navigationCancel => 'Cancelar';

  @override
  String get navigationStop => 'Terminar';

  @override
  String get menuProfile => 'Perfil';

  @override
  String get menuSettings => 'Definições';

  @override
  String get submenuImportGpx => 'Importar GPX';

  @override
  String get submenuCancel => 'Cancelar';

  @override
  String get submenuStop => 'Terminar';

  @override
  String get submenuPause => 'Pausar';

  @override
  String get submenuResume => 'Retomar';

  @override
  String get submenuFollowingPause => 'Pausar';

  @override
  String get submenuFollowingResume => 'Retomar';

  @override
  String get submenuFollowingStop => 'Terminar';

  @override
  String get gpsDisabledAppBar => 'SEM GPS';

  @override
  String get recoverTrackDialogBody => 'Foram detetados dados de uma rota anterior que não foram guardados. Quer recuperá-los ou prefere começar uma nova do zero?';

  @override
  String get waypointNoGps => 'A aguardar sinal GPS...';

  @override
  String get waypointDefaultPrefix => 'P';

  @override
  String get gpsSearching => 'A procurar...';

  @override
  String get fixStart => 'Ponto de início';

  @override
  String get fixEnd => 'Ponto final';

  @override
  String get deleteCurrentTrackTitle => 'Eliminar dados?';

  @override
  String get deleteCurrentTrackMessage => 'Quer eliminar as informações atuais do track?';

  @override
  String get deleteCurrentTrackKeep => 'MANTER';
}
