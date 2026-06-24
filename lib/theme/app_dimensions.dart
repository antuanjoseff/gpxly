// lib/theme/app_dimensions.dart

/// Constants globals de dimensions i proporcions de la interfície de Senda.
class AppDimensions {
  // 🎛️ Barra de Menú Inferior (MenuBar)
  /// L'alçada fixa en píxels del giny MenuBar inferior.
  static const double menuBarHeight = 72.0;

  // 📊 Panell d'Elevacions (Chart)
  /// Proporció d'alçada que ocupa el gràfic respecte a la pantalla total (20%).
  static const double elevationChartHeightRatio = 0.15;

  // 🛡️ Marges i Resguards
  /// Espai de seguretat visual extra per separar elements flotants sobre el mapa.
  static const double mapSafetyPadding = 16.0;

  /// Marge horitzontal estàndard per a les bafarades flotants dels submenús.
  static const double subMenuHorizontalPadding = 24.0;

  /// Separació vertical reglamentària entre components apilats.
  static const double verticalSpacing = 12.0;
}
