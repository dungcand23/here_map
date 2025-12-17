import 'dart:ui_web' as ui_web;

void registerViewFactory(String viewType, Object Function(int viewId) factory) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, factory);
}
