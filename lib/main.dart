// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
// ✅ AFEGIT: Importem el motor de localització per cridar al guardat/recuperació de caché
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/screens/map_screen.dart';
import 'package:senda/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: GPXlyApp()));
}

class GPXlyApp extends StatelessWidget {
  const GPXlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _LifecycleWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ca'), Locale('es')],
        theme: appTheme,
        home: const MapScreen(),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// LISTENER DE CICLO DE VIDA (INTEGRACIÓ DE PERSISTÈNCIA SENDA)
/// ─────────────────────────────────────────────────────────
class _LifecycleWrapper extends ConsumerStatefulWidget {
  const _LifecycleWrapper({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends ConsumerState<_LifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔄 NOU: Al mateix moment en què l'aplicació s'arrenca en fred,
    // demanem al locationProvider que vagi a buscar la caché des de SharedPreferences
    // perquè el punt blau estigui llest abans que el satèl·lit es connecti [INDEX].
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).loadCachePositionFromPrefs();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 💾 NOU: Capturem el moment de sortida (minimitzat o tancat definitiu del Double Back Button)
    // i demanem al provider que salvi les coordenades actuals a SharedPreferences de forma síncrona [INDEX].
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(locationProvider.notifier).saveCurrentPositionToPrefs();
    }

    if (state == AppLifecycleState.resumed) {
      // Solució: refrescar permisos quan tornem a l’app
      ref.read(permissionsProvider.notifier).checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
