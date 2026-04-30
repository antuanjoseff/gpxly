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
    print("---> GET isProgrammatic = $_isProgrammatic");
    return _isProgrammatic;
  }

  bool get cameraDrivenByAnimation {
    print("---> GET cameraDrivenByAnimation = $_cameraDrivenByAnimation");
    return _cameraDrivenByAnimation;
  }

  CameraController(this._map);

  // ------------------------------------------------------------
  // MOVIMENTS BÀSICS
  // ------------------------------------------------------------

  Future<void> moveTo(LatLng target) async {
    print("---> moveTo() START target=$target");
    _beginProgrammaticMove();
    await _map.moveCamera(CameraUpdate.newLatLng(target));
    _endProgrammaticMove();
    print("---> moveTo() END");
  }

  Future<void> animateTo(LatLng target) async {
    print("---> animateTo() START target=$target");
    _beginProgrammaticMove();
    await _map.animateCamera(CameraUpdate.newLatLng(target));
    _endProgrammaticMove();
    print("---> animateTo() END");
  }

  Future<void> animateBounds(LatLngBounds bounds, {double padding = 50}) async {
    print("---> animateBounds() START bounds=$bounds");
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
    print("---> animateBounds() END");
  }

  // ------------------------------------------------------------
  // MOVIMENT DURANT ANIMACIÓ GPS
  // ------------------------------------------------------------

  void moveDuringAnimation(LatLng target) {
    print("---> moveDuringAnimation() target=$target");
    _cameraDrivenByAnimation = true;
    _map.moveCamera(CameraUpdate.newLatLng(target));
  }

  void endAnimation() {
    print("---> endAnimation() SET anim=false");
    _cameraDrivenByAnimation = false;
  }

  // ------------------------------------------------------------
  // GESTIÓ INTERNA DE FLAGS
  // ------------------------------------------------------------

  void _beginProgrammaticMove() {
    _isProgrammatic = true;
    _activeAnimations++;
    print("---> beginProgrammaticMove() active=$_activeAnimations");
  }

  void _endProgrammaticMove() {
    _activeAnimations--;
    print("---> endProgrammaticMove() active=$_activeAnimations");

    if (_activeAnimations <= 0) {
      _activeAnimations = 0;
      _isProgrammatic = false;
      print("---> endProgrammaticMove() programmatic=false");
    }
  }
}
