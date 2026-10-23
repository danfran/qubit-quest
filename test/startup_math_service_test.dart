import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/startup/tex_initializer_native.dart';
import 'support/mastery_math_test_platform.dart';

void main() {
  useMasteryMathTestPlatform();

  test('native retry reuses the started singleton server and its cached URL',
      () async {
    final port = TeXRenderingServer.port;
    expect(port, isNotNull);
    final url = TeXRenderingServer.teXRenderingController.baseUrl;
    await initializeMathService();
    await initializeMathService();
    expect(TeXRenderingServer.port, port);
    expect(TeXRenderingServer.teXRenderingController.baseUrl, url);
  });
}
