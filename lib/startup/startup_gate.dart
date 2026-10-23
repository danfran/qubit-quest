import 'package:flutter/material.dart';
import 'package:quantumquiz/startup/startup_coordinator.dart';

/// Builds the real application only once initialization has succeeded.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.createCoordinator,
    required this.readyBuilder,
    required this.theme,
  });

  final StartupCoordinator Function() createCoordinator;
  final WidgetBuilder readyBuilder;
  final ThemeData theme;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final StartupCoordinator _coordinator;
  Widget? _application;

  @override
  void initState() {
    super.initState();
    _coordinator = widget.createCoordinator();
    _coordinator.addListener(_changed);
    // Let Flutter paint its own first frame before touching the WebView plugin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coordinator.start();
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _coordinator.removeListener(_changed);
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_coordinator.phase == StartupPhase.ready) {
      return _application ??= widget.readyBuilder(context);
    }
    final failed = _coordinator.phase == StartupPhase.error;
    return MaterialApp(
      title: 'Qubit Quest',
      debugShowCheckedModeBanner: false,
      theme: widget.theme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Qubit Quest',
                        style: widget.theme.textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    if (!failed) const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      failed
                          ? (_coordinator.timedOut
                              ? 'Math setup is taking longer than expected.'
                              : 'Math setup could not finish.')
                          : 'Preparing Qubit Quest…',
                      textAlign: TextAlign.center,
                    ),
                    if (failed) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Retry to check again. If setup remains unavailable, close '
                        'and reopen the app. Your saved progress has not been changed.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _coordinator.retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
