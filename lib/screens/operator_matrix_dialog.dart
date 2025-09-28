import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter/material.dart';

class OperatorMatrixDialog extends StatefulWidget {
  const OperatorMatrixDialog({
    super.key,
    required int numQubits,
    required this.teXMatrix,
  }) : _numQubits = numQubits;

  final int _numQubits;
  final String teXMatrix;

  @override
  State<StatefulWidget> createState() => _OperatorMatrixDialogState();
}

class _OperatorMatrixDialogState extends State<OperatorMatrixDialog> {

  late ScrollController _matrixScrollController;

  @override
  void initState() {
    super.initState();
    _matrixScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMatrixPosition();
    });
  }

  @override
  void dispose() {
    _matrixScrollController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _updateMatrixPosition() {
    debugPrint('CALLED: _updateMatrixPosition');
    if (_matrixScrollController.hasClients && _matrixScrollController.position.maxScrollExtent > 0) {
      final position = _matrixScrollController.position.maxScrollExtent / 2;
      _matrixScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[800],
      title: const Text(
        'Overall Operator Matrix',
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      // Make content fill available space and be scrollable
      contentPadding: EdgeInsets.zero, // Remove default padding
      content: Container(
        // Use MediaQuery to take up a large percentage of screen size
        width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
        height: MediaQuery.of(context).size.height * 0.9, // 90% of screen height
        padding: const EdgeInsets.all(16.0), // Add internal padding for the content
        child: SingleChildScrollView( // Vertical scroll for the TeXView content
          scrollDirection: Axis.vertical,
          child: LayoutBuilder( // Use LayoutBuilder to get the available width
            builder: (context, constraints) {
              double adaptiveFontSize = MediaQuery.of(context).size.width * 0.013;
              double adaptiveWidth = constraints.maxWidth;
              if (widget._numQubits == 5) {
                adaptiveWidth = MediaQuery.of(context).size.width * 3;
                adaptiveFontSize = MediaQuery.of(context).size.width * 0.009;
              } else if (widget._numQubits == 4) {
                adaptiveWidth = MediaQuery.of(context).size.width * 2;
                adaptiveFontSize = MediaQuery.of(context).size.width * 0.01;
              } else if (widget._numQubits == 3) {
                adaptiveWidth = MediaQuery.of(context).size.width * 1.7;
                adaptiveFontSize = MediaQuery.of(context).size.width * 0.011;
              }

              return Scrollbar(
                controller: _matrixScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView( // Horizontal scroll for the TeXView content
                  scrollDirection: Axis.horizontal,
                  controller: _matrixScrollController,
                  child: SizedBox( // Explicitly provide a fixed width to TeXView
                    width: adaptiveWidth,
                    child: TeXView(
                      child: TeXViewDocument(
                        '\\(\n${widget.teXMatrix}\n\\)',
                      ),
                      style: TeXViewStyle( // Styling for the TeXView content
                        backgroundColor: Colors.grey[800], // Explicitly set background to match dialog content
                        contentColor: Colors.white, // Text color white
                        fontStyle: TeXViewFontStyle(fontSize: adaptiveFontSize.round()), // Slightly larger font for visibility
                        textAlign: TeXViewTextAlign.center, // <<< ADDED THIS LINE TO CENTER THE MATRIX
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      // actionsPadding: EdgeInsets.only(left:16.0, right: 16.0, bottom: 4.0, top: 0),
      buttonPadding: EdgeInsets.zero, // <<< NEW: This helps reduce space between buttons
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close', style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }
}