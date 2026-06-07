import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';

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
    _matrixScrollController.dispose();
    super.dispose();
  }

  void _updateMatrixPosition() {
    if (_matrixScrollController.hasClients &&
        _matrixScrollController.position.maxScrollExtent > 0) {
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
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = math.min(constraints.maxWidth, 760);
          final double maxHeight = math.min(
            constraints.maxHeight,
            screenSize.height * 0.82,
          );
          final double matrixMaxHeight = math.max(220, maxHeight - 112);
          final double availableMatrixWidth = math.max(280, maxWidth - 32);
          final double matrixWidth =
              availableMatrixWidth * _matrixWidthMultiplier();

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: QubitQuestDialog.panelColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: QubitQuestDialog.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Overall Operator Matrix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: matrixMaxHeight),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: QubitQuestDialog.innerColor,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: QubitQuestDialog.borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Scrollbar(
                            controller: _matrixScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _matrixScrollController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SizedBox(
                                  width: matrixWidth,
                                  child: TeXView(
                                    child: TeXViewDocument(
                                      '\\(\n${widget.teXMatrix}\n\\)',
                                    ),
                                    style: TeXViewStyle(
                                      backgroundColor:
                                          QubitQuestDialog.innerColor,
                                      contentColor: Colors.white,
                                      fontStyle: TeXViewFontStyle(
                                        fontSize: _matrixFontSize(),
                                      ),
                                      textAlign: TeXViewTextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: QubitQuestDialogButton.primary(
                      label: 'Close',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _matrixWidthMultiplier() {
    return switch (widget._numQubits) {
      5 => 3.0,
      4 => 2.2,
      3 => 1.7,
      _ => 1.0,
    };
  }

  int _matrixFontSize() {
    return switch (widget._numQubits) {
      5 => 10,
      4 => 11,
      3 => 12,
      _ => 14,
    };
  }
}
