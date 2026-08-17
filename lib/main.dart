// main.dart
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/notifiers/permissions_notifier.dart';
import 'package:strack_rec/screens/main_map/map_screen.dart';
import 'package:strack_rec/services/cog_service.dart';
import 'package:strack_rec/theme/app_theme.dart';

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
        supportedLocales: const [
          Locale('en'),
          Locale('ca'),
          Locale('es'),
          Locale('fr'), // Francès 👈 NOU
          Locale('it'),
        ],
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
  const _LifecycleWrapper({required this.child});
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

    // 🔄 NOU ENLLAÇ DE PERSISTÈNCIA UNIFICAT
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Recupera la posició del punt blau guardada prèviament
      ref.read(locationProvider.notifier).loadCachePositionFromPrefs();

      // 2. 🔥 NOU: Recupera els fitxers .bin de disc i omple el demBoundsProvider instantàniament
      await CogService().initService(ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 💾 Capturem el moment de sortida per salvar coordenades
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
