import 'dart:js_interop';

/// Defined in web/index.html.
@JS('laneRushSetDprCap')
external JSFunction? get _setDprCap;

/// Limits the rendering resolution (device pixel ratio) so phones with very
/// sharp screens draw fewer pixels.
void setResolutionCap(double maxPixelRatio) {
  _setDprCap?.callAsFunction(null, maxPixelRatio.toJS);
}
