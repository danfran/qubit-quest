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
    final double matrixMaxHeight = screenSize.height * 0.58;
    final double matrixWidth = _matrixWidth();

    return QubitQuestDialog(
      title: 'Overall Operator Matrix',
      titleAlign: TextAlign.center,
      maxWidth: 760,
      actions: [
        QubitQuestDialogButton.primary(
          label: 'Close',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: matrixMaxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.innerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QubitQuestDialog.borderColor),
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
                        backgroundColor: QubitQuestDialog.innerColor,
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
    );
  }

  double _matrixWidth() {
    return switch (widget._numQubits) {
      5 => 1960,
      4 => 1420,
      3 => 1040,
      _ => 620,
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
