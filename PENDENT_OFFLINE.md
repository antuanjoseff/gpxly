# Pendent: mode offline al mapa principal

## 1. Rectangle de Catalunya (fet ✅)

**Problema original:** `OfflineMapsScreen` petava (crash natiu JNI) en afegir el GeoJSON.

**Causa:** Es passava una `Feature` sola a `addSource`. El plugin natiu espera un `FeatureCollection` amb llista `features`; cridava `toArray()` sobre null → abort.

**Solució aplicada:** Passar un `FeatureCollection` amb `features` a [offline_maps_screen.dart](../lib/screens/settings/offline_maps_screen.dart) (igual que fa el barometer, que funciona).

## 2. Mode offline al mapa principal (PENDENT 🔴)

**Estat actual:** El toggle "fer servir offline" només guarda un bool a SharedPreferences. **No fa res.**

**Per què:**

- Ningú fa servir `offlineMapsProvider` ni `buildOfflineStyle()` de [offline_maps_service.dart:178](../lib/services/offline_maps_service.dart#L178).
- El mapa principal ([map_base_layer.dart:47](../lib/screens/main_map/widgets/map_base_layer.dart#L47)) sempre carrega `assets/osm_style.json`.

**⚠️ ATENCIÓ:** L'estil que genera `buildOfflineStyle()` ara mateix només dibuixa un fons verd pla (`background`). No té capes de carreteres, aigua, noms, etc. Si el mapa principal el fes servir, es veuria pantalla verda buida.

**Per demà cal:**

1. **Mapa principal** miri `offlineMapsProvider`:
   - Si `offline.enabled == true` → cridar `controller.setStyleString(buildOfflineStyle('catalunya'))`
   - Si `false` → `assets/osm_style.json`

2. **`buildOfflineStyle()`** ha de generar les capes reals (carreteres, aigua, etc.) apuntant al `mbtiles` local, igual que fa `osm_style.json` però amb el source apuntant al fitxer descarregat.
