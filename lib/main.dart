import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/screens/map_screen.dart';
import 'package:senda/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PAS CRÍTIC: copiar els .tif dels assets a /files/dem/
  // await DemLoader.ensureDemFiles();

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
        home: MapScreen(),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// LISTENER DE CICLO DE VIDA (soluciona el problema)
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // olució: refrescar permisos quan tornem a l’app
      ref.read(permissionsProvider.notifier).checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
