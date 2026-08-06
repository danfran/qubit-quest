import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const WebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true; // State to control spinner visibility
  double _progress = 0.0; // To show loading progress

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // <--- THIS IS THE KEY LINE
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
            setState(() {
              _progress = progress / 100.0;
            });
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            // Page started loading, show spinner
            setState(() {
              _isLoading = true;
              _progress = 0.0; // Reset progress
            });
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            // Page finished loading, hide spinner
            setState(() {
              _isLoading = false;
            });
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            // An error occurred, hide spinner
            setState(() {
              _isLoading = false;
            });
            debugPrint('''
              Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
            ''');
            // Optionally, show an error message to the user
          },
          onNavigationRequest: (NavigationRequest request) {
            // You can control navigation here, e.g., block certain URLs
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          // The WebView itself
          WebViewWidget(controller: _controller),

          // Loading Indicator Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7), // Semi-transparent overlay
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress > 0 && _progress < 1 ? _progress : null,
                      // Show progress if available
                      color: Colors.blueAccent,
                    ),
                    if (_progress > 0 && _progress < 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Loading: ${(_progress * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Loading content...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
