import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
// The production webview_flutter dependency exposes this platform test seam.
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Widget tests exercise TeX routing/SVG layout, not an unavailable OS WebView.
/// Real formula appearance is checked separately in the browser review.
void useMasteryMathTestPlatform({String? svg}) {
  setUpAll(() async {
    WebViewPlatform.instance = _MathPlatform(svg);
    await TeXRenderingServer.start();
  });
  tearDownAll(TeXRenderingServer.stop);
}

class _MathPlatform extends WebViewPlatform {
  _MathPlatform(this.svg);
  final String? svg;
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) =>
      _MathController(params, svg);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      _MathNavigation(params);
}

class _MathNavigation extends PlatformNavigationDelegate {
  _MathNavigation(super.params) : super.implementation();
  PageEventCallback? finished;
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async {
    finished = callback;
  }

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback callback) async {}
}

class _MathController extends PlatformWebViewController {
  _MathController(super.params, this.svg) : super.implementation();
  final String? svg;
  _MathNavigation? delegate;
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate value) async {
    delegate = value as _MathNavigation;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    delegate?.finished?.call(params.uri.toString());
  }

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setOnConsoleMessage(
      void Function(JavaScriptConsoleMessage) callback) async {}
  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async =>
      svg ??
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4000 1000">'
          '<path d="M0 0 H4000 V1000 H0 Z"/></svg>';
}
