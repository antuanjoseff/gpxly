import 'package:maplibre_gl/maplibre_gl.dart';

/// Controlador centralitzat de càmera.
/// TOTS els moviments de càmera passen per aquí.
/// Això permet distingir clarament moviments programàtics
/// de moviments de l’usuari.
class CameraController {
  final MapLibreMapController _map;

  /// Indica si el moviment actual és programàtic (animate/move).
  bool _isProgrammatic = false;

  /// Indica si el moviment prové d’una animació interna (GPS).
  bool _cameraDrivenByAnimation = false;

  /// Comptador d’animacions actives (per evitar falsos positius).
  int _activeAnimations = 0;

  bool get isProgrammatic {
    return _isProgrammatic;
  }

  bool get cameraDrivenByAnimation {
    return _cameraDrivenByAnimation;
  }

  CameraController(this._map);

  // ------------------------------------------------------------
  // MOVIMENTS BÀSICS
  // ------------------------------------------------------------

  Future<void> moveTo(LatLng target) async {
    _beginProgrammaticMove();
    await _map.moveCamera(CameraUpdate.newLatLng(target));
    _endProgrammaticMove();
  }

  Future<void> animateTo(LatLng target) async {
    _beginProgrammaticMove();
    await _map.animateCamera(CameraUpdate.newLatLng(target));
    _endProgrammaticMove();
  }

  Future<void> animateBounds(LatLngBounds bounds, {double padding = 50}) async {
    _beginProgrammaticMove();
    await _map.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: padding,
        top: padding,
        right: padding,
        bottom: padding,
      ),
    );
    _endProgrammaticMove();
  }

  // ------------------------------------------------------------
  // MOVIMENT DURANT ANIMACIÓ GPS
  // ------------------------------------------------------------

  void moveDuringAnimation(LatLng target) {
    _cameraDrivenByAnimation = true;
    _map.moveCamera(CameraUpdate.newLatLng(target));
  }

  void endAnimation() {
    _cameraDrivenByAnimation = false;
  }

  // ------------------------------------------------------------
  // GESTIÓ INTERNA DE FLAGS
  // ------------------------------------------------------------

  void _beginProgrammaticMove() {
    _isProgrammatic = true;
    _activeAnimations++;
  }

  void _endProgrammaticMove() {
    _activeAnimations--;

    if (_activeAnimations <= 0) {
      _activeAnimations = 0;
      _isProgrammatic = false;
    }
  }
}
